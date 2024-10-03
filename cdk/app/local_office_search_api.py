from aws_cdk import Stack, Stage
from aws_cdk.aws_ecr import Repository
from aws_cdk.aws_ec2 import Vpc
from aws_cdk.aws_eks import ServiceAccount as AwsServiceAccount
from aws_cdk.aws_rds import Credentials, DatabaseCluster
from aws_cdk.aws_s3 import Bucket
from aws_cdk.aws_secretsmanager import Secret, SecretStringGenerator
from ca_cdk_constructs.eks.external_secrets import (
    ExternalAwsSecretsChart,
    ExternalSecretSource,
)
from constructs import Construct

from cdk8s import App
from ca_cdk_constructs.eks.eks_cluster_integration import EksClusterIntegration

from .chart import LocalOfficeSearchApiChart


class LocalOfficeSearchApiDeployment(Stack):
    def __init__(
        self,
        scope: Construct,
        construct_id: str,
        app_image_version: str,
        db: DatabaseCluster,
        db_credentials: Credentials,
        lss_bucket_name: str,
        geo_data_bucket_name: str,
        geo_data_postcode_file: str,
        **kwargs,
    ) -> None:
        super().__init__(scope, construct_id, **kwargs)

        image_repo = Repository.from_repository_arn(
            self,
            "LocalOfficeSearchApiRepo",
            "arn:aws:ecr:eu-west-1:979633842206:repository/local-office-search-api",
        )

        vpc = Vpc.from_lookup(
            self,
            "VpcLookup",
            is_default=False,
            region="eu-west-1",
            tags={"Product": "vpc"},
        )

        namespace = f"{Stage.of(self).stage_name}-local-office-search-api"

        eks_cluster = EksClusterIntegration(
            self,
            "EksClusterIntegration",
            vpc=vpc,
            cluster_name=f"{Stage.of(self).stage_name}-eks-platform",
            role_name="LocalOfficeSearchApiDeploymentEksClusterIntegration",
        ).cluster

        lss_data_bucket = Bucket.from_bucket_name(
            self, "LssBucket", bucket_name=lss_bucket_name
        )
        geo_data_bucket = Bucket.from_bucket_name(
            self, "GeoDataBucket", bucket_name=geo_data_bucket_name
        )

        app_secrets_secret = Secret(
            self,
            "AppSecrets",
            secret_name=f"content-platform-LocalOfficeSearchApiAppSecrets-{Stage.of(self).stage_name}",
            generate_secret_string=SecretStringGenerator(),
        )

        self._service_account = AwsServiceAccount(
            self,
            "LocalOfficeSearchApiServiceAccount",
            namespace=namespace,
            name="local-office-search-api",
            cluster=eks_cluster,
            labels={"app.kubernetes.io/name": "local-office-search-api"},
        )
        lss_data_bucket.grant_read(self._service_account)
        geo_data_bucket.grant_read(self._service_account)

        external_secrets_service_account = AwsServiceAccount(
            self,
            "LocalOfficeSearchApiReadExternalSecrets",
            namespace=namespace,
            name="local-office-search-api-read-external-secrets",
            cluster=eks_cluster,
            labels={"app.kubernetes.io/name": "local-office-search-api"},
        )

        self._cdk8s_app = App()

        rds_secret_source = ExternalSecretSource(
            source_secret=db_credentials.secret_name,
            secret_mappings={"password": "DB_PASSWORD"},
            k8s_secret_name="local-office-search-db",
        )
        db_credentials_secret = Secret.from_secret_name_v2(
            self, "LocalOfficeSearchDbSecret", secret_name=db_credentials.secret_name
        )
        db_credentials_secret.grant_read(external_secrets_service_account)

        app_secret_source = ExternalSecretSource(
            source_secret=app_secrets_secret.secret_name,
            secret_mappings={
                "SECRET_KEY_BASE": "",
                "EPISERVER_USERNAME": "",
                "EPISERVER_PASSWORD": "",
            },
            k8s_secret_name="local-office-search-app",
        )
        app_secrets_secret.grant_read(external_secrets_service_account)

        eks_cluster.add_cdk8s_chart(
            "ExternalSecrets",
            ExternalAwsSecretsChart(
                self._cdk8s_app,
                "LocalOfficeSearchApiExternalSecrets",
                region=Stack.of(self).region,
                namespace=namespace,
                secret_sources=[app_secret_source, rds_secret_source],
                service_account_name=external_secrets_service_account.service_account_name,
            ),
        )

        eks_cluster.add_cdk8s_chart(
            "LocalOfficeSearchApiChart",
            LocalOfficeSearchApiChart(
                self._cdk8s_app,
                "LocalOfficeSearchApiChart",
                namespace=namespace,
                env=Stage.of(self).stage_name,
                image_repo=image_repo,
                image_version=app_image_version,
                db=db,
                db_credentials=db_credentials,
                lss_data_bucket=lss_data_bucket,
                geo_data_bucket=geo_data_bucket,
                geo_data_postcode_file=geo_data_postcode_file,
                service_account_name=self._service_account.service_account_name,
                rds_secret_name=rds_secret_source.k8s_secret_name,
                app_secret_name=app_secret_source.k8s_secret_name,
            ),
        )
