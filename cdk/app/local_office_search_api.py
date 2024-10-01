from aws_cdk import Stack, Stage
from aws_cdk.aws_ecr import Repository
from aws_cdk.aws_ec2 import Vpc
from aws_cdk.aws_eks import ServiceAccount
from aws_cdk.aws_rds import Credentials, DatabaseCluster
from aws_cdk.aws_s3 import Bucket
from constructs import Construct

from cdk8s import App
from ca_cdk_constructs.eks.eks_cluster_integration import EksClusterIntegration

from .chart import LocalOfficeSearchApiChart


class LocalOfficeSearchApiDeployment(Stack):
    def __init__(self,
                 scope: Construct,
                 construct_id: str,
                 app_image_version: str,
                 db: DatabaseCluster,
                 db_credentials: Credentials,
                 lss_bucket_name: str,
                 geo_data_bucket_name: str,
                 geo_data_postcode_file: str,
                 **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        image_repo = Repository.from_repository_arn(self, "LocalOfficeSearchApiRepo", "arn:aws:ecr:eu-west-1:979633842206:repository/local-office-search-api")

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

        lss_data_bucket = Bucket.from_bucket_name(self, "LssBucket", bucket_name=lss_bucket_name)
        geo_data_bucket = Bucket.from_bucket_name(self, "GeoDataBucket", bucket_name=geo_data_bucket_name)

        service_account = ServiceAccount(
            self,
            "LocalOfficeSearchApiServiceAccount",
            namespace=namespace,
            name="local-office-search-api",
            cluster=eks_cluster,
            labels={"app.kubernetes.io/name": "local-office-search-api"},
        )
        lss_data_bucket.grant_read(service_account)
        geo_data_bucket.grant_read(service_account)

        cdk8s_app = App()
        eks_cluster.add_cdk8s_chart(
            "LocalOfficeSearchApiChart",
            LocalOfficeSearchApiChart(
                cdk8s_app,
                "LocalOfficeSearchApiChart",
                namespace=namespace,
                env=Stage.of(scope).stage_name,
                image_repo=image_repo,
                image_version=app_image_version,
                db=db,
                db_credentials=db_credentials,
                lss_data_bucket=lss_data_bucket,
                geo_data_bucket=geo_data_bucket,
                geo_data_postcode_file=geo_data_postcode_file,
                service_account=service_account,
            )
        )
