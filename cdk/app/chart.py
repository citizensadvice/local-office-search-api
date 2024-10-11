import json
import typing

from aws_cdk.aws_ecr import Repository
from aws_cdk.aws_rds import Credentials, DatabaseCluster
from aws_cdk.aws_s3 import Bucket
from cdk8s import Chart, Cron, Duration, Size, ApiObjectMetadataDefinition
from cdk8s_plus_30 import (
    Deployment,
    RestartPolicy,
    ServicePort,
    CronJob,
    ContainerProps,
    ImagePullPolicy,
    ContainerPort,
    EnvValue,
    Probe,
    ContainerResources,
    CpuResources,
    Cpu,
    MemoryResources,
    ContainerSecurityContextProps,
    HorizontalPodAutoscaler,
    Metric,
    NetworkPolicyTraffic,
    NetworkPolicy,
    NetworkPolicyRule,
    NetworkPolicyPort,
    Pods,
    Namespaces,
    LabelExpression,
    MetricTarget,
    EnvFieldPaths,
    NetworkPolicyIpBlock,
    Secret,
    ServiceAccount,
    ServiceType,
    Service,
    Ingress,
    IngressBackend,
)
from constructs import Construct


class LocalOfficeSearchApiChart(Chart):
    _APP_NAME = "local-office-search-api"
    _HTTP_PORT = 3060
    _METRICS_PORT = 9394

    def __init__(
        self,
        scope: Construct,
        construct_id: str,
        env: str,
        namespace: str,
        image_repo: Repository,
        image_version: str,
        db: DatabaseCluster,
        db_credentials: Credentials,
        lss_data_bucket: Bucket,
        geo_data_bucket: Bucket,
        geo_data_postcode_file: str,
        service_account_name: str,
        rds_secret_name: str,
        app_secret_name: str,
        api_v0_host: str,
    ):
        self._labels = {
            "app": self._APP_NAME,
            "env": env,
            "tags.datadoghq.com/env": env,
            "tags.datadoghq.com/service": self._APP_NAME,
            "tags.datadoghq.com/version": image_version,
        }

        super().__init__(
            scope,
            construct_id,
            namespace=namespace,
            labels=self._labels,
        )

        self._container_image = f"{image_repo.repository_uri}:{image_version}"
        self._app_version = image_version

        self._db = db
        self._db_username = db_credentials.username
        self._db_secret = Secret.from_secret_name(
            self, "LocalOfficeSearchDbSecret", name=rds_secret_name
        )
        self._app_secret = Secret.from_secret_name(
            self, "LocalOfficeSearchApiAppSecrets", name=app_secret_name
        )
        self._service_account = ServiceAccount.from_service_account_name(
            self, "LocalOfficeSearchApiAppServiceAccount", service_account_name
        )
        self._lss_data_bucket_name = lss_data_bucket.bucket_name
        self._geo_data_bucket_name = geo_data_bucket.bucket_name
        self._geo_data_postcode_file = geo_data_postcode_file

        deployment = self._create_deployment()
        app_service = self._expose_services(deployment)
        self._expose_v0_api(api_v0_host, app_service)

        self._create_scheduled_import()
        self._configure_autoscaler(deployment)
        self._allow_external_traffic()
        self._allow_metrics_collection()

    def _create_deployment(self):
        deployment = Deployment(
            self,
            "Deployment",
            containers=[
                self._server_container_props(
                    f"{self._APP_NAME}-server",
                    command_line=[
                        "bin/rails",
                        "server",
                        "-p",
                        str(self._HTTP_PORT),
                        "-b",
                        "0.0.0.0",
                    ],
                )
            ],
            service_account=self._service_account,
            restart_policy=RestartPolicy.ALWAYS,
            termination_grace_period=Duration.seconds(60),
        )

        self._add_labels(deployment.metadata)
        self._add_labels(deployment.pod_metadata)
        deployment.pod_metadata.add_label("component", "local-office-search-api-server")
        deployment.metadata.add_annotation(
            "ad.datadoghq.com/local-office-search-api-server.logs",
            json.dumps(
                [
                    {
                        "source": "ruby",
                        "sourcecategory": "sourcecode",
                        "service": self._APP_NAME,
                        "log_processing_rules": [
                            {
                                "type": "exclude_at_match",
                                "name": "exclude_metrics_requests",
                                "pattern": "GET /metrics",
                            },
                            {
                                "type": "exclude_at_match",
                                "name": "exclude_status_heartbeat",
                                "pattern": '"path":"/status"',
                            },
                        ],
                    }
                ]
            ),
        )

        return deployment

    def _create_scheduled_import(self):
        scheduled_job = CronJob(
            self,
            "ScheduledImport",
            schedule=Cron.schedule(hour="9", minute="55"),
            time_zone="Europe/London",
            containers=[
                self._server_container_props(
                    f"{self._APP_NAME}-scheduled-import",
                    command_line=["bin/rake", "sync_database"],
                )
            ],
            service_account=self._service_account,
            restart_policy=RestartPolicy.NEVER,
        )

        self._add_labels(scheduled_job.metadata)
        self._add_labels(scheduled_job.pod_metadata)
        scheduled_job.pod_metadata.add_label(
            "component", "local-office-search-api-scheduled-import"
        )

        scheduled_job.metadata.add_annotation(
            "ad.datadoghq.com/local-office-search-api-scheduled-import.logs",
            json.dumps(
                [
                    {
                        "source": "ruby",
                        "sourcecategory": "sourcecode",
                        "service": self._APP_NAME,
                    }
                ]
            ),
        )

    def _server_container_props(self, name: str, command_line: typing.List[str]):
        return ContainerProps(
            name=name,
            image=self._container_image,
            image_pull_policy=ImagePullPolicy.IF_NOT_PRESENT,
            args=command_line,
            ports=[
                ContainerPort(name="http", number=self._HTTP_PORT),
                ContainerPort(name="metrics", number=self._METRICS_PORT),
            ],
            env_variables=self._app_env_vars(),
            readiness=Probe.from_http_get(
                path="/status",
                port=self._HTTP_PORT,
                initial_delay_seconds=Duration.seconds(10),
                period_seconds=Duration.seconds(10),
                success_threshold=1,
                failure_threshold=3,
                timeout_seconds=Duration.seconds(5),
            ),
            resources=ContainerResources(
                cpu=CpuResources(request=Cpu.millis(400), limit=Cpu.millis(800)),
                memory=MemoryResources(request=Size.mebibytes(512), limit=Size.gibibytes(1)),
            ),
            security_context=ContainerSecurityContextProps(
                user=1000, read_only_root_filesystem=False
            ),
        )

    def _app_env_vars(self):
        return {
            "DD_ENV": EnvValue.from_field_ref(
                EnvFieldPaths.POD_LABEL, key="tags.datadoghq.com/env"
            ),
            "DD_SERVICE": EnvValue.from_field_ref(
                EnvFieldPaths.POD_LABEL, key="tags.datadoghq.com/service"
            ),
            "DD_VERSION": EnvValue.from_field_ref(
                EnvFieldPaths.POD_LABEL, key="tags.datadoghq.com/version"
            ),
            "DD_AGENT_HOST": EnvValue.from_field_ref(EnvFieldPaths.NODE_IP),
            "RAILS_MAX_THREADS": EnvValue.from_value("10"),
            "RAILS_ENV": EnvValue.from_value("production"),
            "RACK_ENV": EnvValue.from_value("production"),
            "NODE_ENV": EnvValue.from_value("production"),
            "SECRET_KEY_BASE": self._app_secret.env_value("SECRET_KEY_BASE"),
            "RAILS_LOG_TO_STDOUT": EnvValue.from_value("true"),
            "LSS_DATA_BUCKET": EnvValue.from_value(self._lss_data_bucket_name),
            "GEO_DATA_BUCKET": EnvValue.from_value(self._geo_data_bucket_name),
            "GEO_DATA_POSTCODES_FILE": EnvValue.from_value(self._geo_data_postcode_file),
            "LOCAL_OFFICE_SEARCH_EPISERVER_USER": self._app_secret.env_value(
                "EPISERVER_USERNAME"
            ),
            "LOCAL_OFFICE_SEARCH_EPISERVER_PASSWORD": self._app_secret.env_value(
                "EPISERVER_PASSWORD"
            ),
            "LOCAL_OFFICE_SEARCH_DB_USER": EnvValue.from_value(self._db_username),
            "LOCAL_OFFICE_SEARCH_DB_PASSWORD": self._db_secret.env_value("DB_PASSWORD"),
            "LOCAL_OFFICE_SEARCH_DB_HOST": EnvValue.from_value(
                self._db.cluster_endpoint.hostname
            ),
            "LOCAL_OFFICE_SEARCH_DB_PORT": EnvValue.from_value(
                str(self._db.cluster_endpoint.port)
            ),
            "LOCAL_OFFICE_SEARCH_DB_NAME": EnvValue.from_value("local_office_search_api"),
        }

    def _expose_services(self, deployment: Deployment):
        service = deployment.expose_via_service(
            name=self._APP_NAME,
            ports=[ServicePort(name="http", port=self._HTTP_PORT)],
            service_type=ServiceType.NODE_PORT,
        )

        metrics_service = deployment.expose_via_service(
            name=f"{self._APP_NAME}-metrics",
            ports=[ServicePort(name="metrics", port=self._METRICS_PORT)],
        )
        metrics_service.metadata.add_label("custom-metrics-enabled", "true")

        return service

    def _expose_v0_api(self, host: str, app_service: Service):
        ingress = Ingress(self, "LocalOfficeSearchApiV0Ingress", class_name="alb")
        ingress.add_host_rule(host, "/api/v0/", IngressBackend.from_service(app_service))

    def _configure_autoscaler(self, deployment: Deployment):
        HorizontalPodAutoscaler(
            self,
            "Autoscaler",
            target=deployment,
            min_replicas=2,
            max_replicas=4,
            # 75% of threads busy serving requests
            metrics=[
                Metric.pods(name="puma_business", target=MetricTarget.average_value(0.75))
            ],
        )

    def _allow_external_traffic(self):
        NetworkPolicy(
            self,
            "AllowExternalTraffic",
            ingress=NetworkPolicyTraffic(
                rules=[
                    NetworkPolicyRule(
                        peer=NetworkPolicyIpBlock.any_ipv4(self, "AllowAnyIpv4"),
                        ports=[NetworkPolicyPort.of(port=self._HTTP_PORT)],
                    )
                ]
            ),
        )

    def _allow_metrics_collection(self):
        NetworkPolicy(
            self,
            "AllowMetricsCollection",
            ingress=NetworkPolicyTraffic(
                rules=[
                    NetworkPolicyRule(
                        peer=Pods(
                            self,
                            "Prometheus",
                            namespaces=Namespaces(
                                self, "MonitoringNamespace", names=["kube-monitoring"]
                            ),
                            expressions=[
                                LabelExpression.in_(
                                    key="prometheus", values=["prometheus-operator-prometheus"]
                                )
                            ],
                        ),
                        ports=[NetworkPolicyPort.of(port=self._METRICS_PORT)],
                    )
                ]
            ),
        )

    def _add_labels(self, metadata: ApiObjectMetadataDefinition):
        for key, value in self._labels.items():
            metadata.add_label(key, value)
