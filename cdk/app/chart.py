import json

from aws_cdk.aws_eks import ServiceAccount
from aws_cdk.aws_rds import Credentials, DatabaseCluster
from aws_cdk.aws_s3 import Bucket
from constructs import Construct
from cdk8s import Chart, Cron, Duration, Size
from cdk8s_plus_30 import Deployment, RestartPolicy, ServicePort, CronJob, ContainerProps, ImagePullPolicy, \
    ContainerPort, EnvValue, Probe, ContainerResources, CpuResources, Cpu, MemoryResources, \
    ContainerSecurityContextProps, \
    HorizontalPodAutoscaler, Metric, NetworkPolicyTraffic, NetworkPolicy, NetworkPolicyRule, NetworkPolicyPort, Pods, \
    Namespaces, LabelExpression, MetricTarget, EnvFieldPaths, NetworkPolicyIpBlock


class LocalOfficeSearchApiChart(Chart):
    _HTTP_PORT = 3060
    _METRICS_PORT = 9394

    def __init__(self,
                 scope: Construct,
                 construct_id: str,
                 env: str,
                 namespace: str,
                 image_version: str,
                 db: DatabaseCluster,
                 db_credentials: Credentials,
                 lss_data_bucket: Bucket,
                 geo_data_bucket: Bucket,
                 geo_data_postcode_file: str,
                 service_account: ServiceAccount):
        super().__init__(scope,
                         construct_id,
                         namespace=namespace,
                         labels={
                             "app": "local-office-search-api",
                             "env": env,
                             "tags.datadoghq.com/env": env,
                             "tags.datadoghq.com/service": "local-office-search-api",
                             "tags.datadoghq.com/version": image_version,
                         })

        deployment = self._create_deployment(
            image_version=image_version,
            db=db,
            db_credentials=db_credentials,
            lss_data_bucket=lss_data_bucket,
            geo_data_bucket=geo_data_bucket,
            geo_data_postcode_file=geo_data_postcode_file,
            service_account=service_account
        )
        deployment.expose_via_service(
            name="local-office-search-api",
            ports=[ServicePort(name="http", port=self._HTTP_PORT)]
        )

        metrics_service = deployment.expose_via_service(
            name="local-office-search-api-metrics",
            ports=[ServicePort(name="metrics", port=self._METRICS_PORT)]
        )
        metrics_service.metadata.add_label("custom-metrics-enabled", "true")

        self._create_scheduled_import(
            image_version=image_version,
            db=db,
            db_credentials=db_credentials,
            lss_data_bucket=lss_data_bucket,
            geo_data_bucket=geo_data_bucket,
            geo_data_postcode_file=geo_data_postcode_file,
            service_account=service_account
        )
        self._configure_autoscaler(deployment)
        self._allow_external_traffic()
        self._allow_metrics_collection()

    def _create_deployment(self,
                           image_version: str,
                           db: DatabaseCluster,
                           db_credentials: Credentials,
                           lss_data_bucket: Bucket,
                           geo_data_bucket: Bucket,
                           geo_data_postcode_file: str,
                           service_account: ServiceAccount):
        deployment = Deployment(
            self,
            "Deployment",
            containers=[self._server_container_props(
                "local-office-search-api-server",
                image_version=image_version,
                command_line=["bin/rails", "server", "-p", str(self._HTTP_PORT), "-b", "0.0.0.0"],
                db=db,
                db_credentials=db_credentials,
                lss_data_bucket=lss_data_bucket,
                geo_data_bucket=geo_data_bucket,
                geo_data_postcode_file=geo_data_postcode_file,
            )],
            service_account=service_account,
            restart_policy=RestartPolicy.ALWAYS,
            termination_grace_period=Duration.seconds(60),
        )

        deployment.metadata.add_annotation("ad.datadoghq.com/local-office-search-api-server.logs", json.dumps([{
            "source": "ruby",
            "sourcecategory": "sourcecode",
            "service": "local-office-search-api",
            "log_processing_rules": [{
                "type": "exclude_at_match",
                "name": "exclude_metrics_requests",
                "pattern": "GET /metrics"
            }, {
                "type": "exclude_at_match",
                "name": "exclude_status_heartbeat",
                "pattern": '"path":"/status"'
            }]
        }]))

        return deployment

    def _create_scheduled_import(self,
                              image_version: str,
                              db: DatabaseCluster,
                              db_credentials: Credentials,
                              lss_data_bucket: Bucket,
                              geo_data_bucket: Bucket,
                              geo_data_postcode_file: str,
                              service_account: ServiceAccount):
        scheduled_job = CronJob(
            self,
            "ScheduledImport",
            schedule=Cron.schedule(hour="9", minute="55"),
            time_zone="Europe/London",
            containers=[self._server_container_props(
                "local-office-search-api-server",
                image_version=image_version,
                command_line=["bin/rake", "sync_database"],
                db=db,
                db_credentials=db_credentials,
                lss_data_bucket=lss_data_bucket,
                geo_data_bucket=geo_data_bucket,
                geo_data_postcode_file=geo_data_postcode_file,
            )],
            service_account=service_account,
            restart_policy=RestartPolicy.NEVER,
        )

        scheduled_job.metadata.add_annotation("ad.datadoghq.com/local-office-search-api-scheduled-import.logs", json.dumps([{
            "source": "ruby",
            "sourcecategory": "sourcecode",
            "service": "local-office-search-api",
        }]))

    def _server_container_props(self,
                                name: str,
                                image_version: str,
                                command_line,
                                db: DatabaseCluster,
                                db_credentials: Credentials,
                                lss_data_bucket: Bucket,
                                geo_data_bucket: Bucket,
                                geo_data_postcode_file: str):

        return ContainerProps(
            name=name,
            image=f"979633842206.dkr.ecr.eu-west-1.amazonaws.com/local-office-search-api:{image_version}",
            image_pull_policy=ImagePullPolicy.IF_NOT_PRESENT,
            args=command_line,
            ports=[ContainerPort(name="http", number=self._HTTP_PORT), ContainerPort(name="metrics", number=self._METRICS_PORT)],
            env_variables={
                "DD_ENV": EnvValue.from_field_ref(EnvFieldPaths.POD_LABEL, key="tags.datadoghq.com/env"),
                "DD_SERVICE": EnvValue.from_field_ref(EnvFieldPaths.POD_LABEL, key="tags.datadoghq.com/service"),
                "DD_VERSION": EnvValue.from_field_ref(EnvFieldPaths.POD_LABEL, key="tags.datadoghq.com/version"),
                "DD_AGENT_HOST": EnvValue.from_field_ref(EnvFieldPaths.NODE_IP),
                "RAILS_MAX_THREADS": EnvValue.from_value("10"),
                "RAILS_ENV": EnvValue.from_value("production"),
                "RACK_ENV": EnvValue.from_value("production"),
                "NODE_ENV": EnvValue.from_value("production"),
                "SECRET_KEY_BASE": EnvValue.from_value('<%= vault_ref "RAILS_MASTER_KEY" %>'), ## TODO: figure out how to pass through external secret here??
                "RAILS_LOG_TO_STDOUT": EnvValue.from_value("true"),
                "LSS_DATA_BUCKET": EnvValue.from_value(lss_data_bucket.bucket_name),
                "GEO_DATA_BUCKET": EnvValue.from_value(geo_data_bucket.bucket_name),
                "GEO_DATA_POSTCODES_FILE": EnvValue.from_value(geo_data_postcode_file),
                "LOCAL_OFFICE_SEARCH_EPISERVER_USER": EnvValue.from_value('<%= vault_ref "LOCAL_OFFICE_SEARCH_EPISERVER_USER" %>'), ## TODO
                "LOCAL_OFFICE_SEARCH_EPISERVER_PASSWORD": EnvValue.from_value('<%= vault_ref "LOCAL_OFFICE_SEARCH_EPISERVER_PASSWORD" %>'), ## TODO
                "LOCAL_OFFICE_SEARCH_DB_USER": EnvValue.from_value(db_credentials.username),
                "LOCAL_OFFICE_SEARCH_DB_PASSWORD": EnvValue.from_value(""), ## TODO EnvValue.from_secret_value(db_credentials),
                "LOCAL_OFFICE_SEARCH_DB_HOST": EnvValue.from_value(db.cluster_endpoint.hostname),
                "LOCAL_OFFICE_SEARCH_DB_PORT": EnvValue.from_value(str(db.cluster_endpoint.port)),
                "LOCAL_OFFICE_SEARCH_DB_NAME": EnvValue.from_value("local_office_search_api"),
            },
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
            security_context=ContainerSecurityContextProps(user=3000)
        )

    def _configure_autoscaler(self, deployment):
        HorizontalPodAutoscaler(
            self,
            "Autoscaler",
            target=deployment,
            min_replicas=2,
            max_replicas=4,
            # 75% of threads busy serving requests
            metrics=[Metric.pods(name="puma_business", target=MetricTarget.average_value(0.75))]
        )

    def _allow_external_traffic(self):
        NetworkPolicy(self, "AllowExternalTraffic", ingress=NetworkPolicyTraffic(rules=[
            NetworkPolicyRule(
                peer=NetworkPolicyIpBlock.any_ipv4(self, "AllowAnyIpv4"),
                ports=[NetworkPolicyPort.of(port=self._HTTP_PORT)]
            )
        ]))

    def _allow_metrics_collection(self):
        NetworkPolicy(self, "AllowMetricsCollection", ingress=NetworkPolicyTraffic(rules=[
            NetworkPolicyRule(
                peer=Pods(
                    self,
                    "Prometheus",
                    namespaces=Namespaces(self, "MonitoringNamespace", names=["kube-monitoring"]),
                    expressions=[LabelExpression.in_(key="prometheus", values=["prometheus-operator-prometheus"])]
                ),
                ports=[NetworkPolicyPort.of(port=self._METRICS_PORT)]
            )
        ]))
