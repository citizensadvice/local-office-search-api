from functools import lru_cache

from aws_cdk import Stack, Duration
from aws_cdk.aws_ec2 import InstanceType, Peer, Port, SecurityGroup, SubnetSelection, SubnetType, Vpc
from aws_cdk.aws_rds import AuroraPostgresEngineVersion, BackupProps, Credentials, ClusterInstance, DatabaseCluster, DatabaseClusterEngine, ParameterGroup
from constructs import Construct


class LocalOfficeSearchApiInfrastructure(Stack):
    _POSTGRES_PORT = 5432

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        self._create_postgres_database()

    def _create_postgres_database(self):
        sg = SecurityGroup(self, "DbSecurityGroup", vpc=self._vpc)

        db = DatabaseCluster(
            self,
            "LocalOfficeSearchApiDb",
            engine=DatabaseClusterEngine.aurora_postgres(version=AuroraPostgresEngineVersion.VER_16_4),
            backup=BackupProps(retention=Duration.days(5), preferred_window="23:00-00:00"),
            copy_tags_to_snapshot=True,
            credentials=Credentials.fromGeneratedSecret("local-office-search-api"),
            default_database_name="local_office_search_api",
            parameter_group=ParameterGroup.fromParameterGroupName("aurora-postgresql16"),
            monitoring_interval=Duration.seconds(30),
            storage_encrypted=True,
            security_groups=[sg],
            vpc=self._vpc,
            vpc_subnets=SubnetSelection(subnet_type=SubnetType.PRIVATE),
            writer=ClusterInstance.provisioned(
                "LocalOfficeSearchApiDbWriter",
                instance_type=InstanceType("t3.medium"),
                allow_major_version_upgrade=True,
                auto_minor_version_upgrade=True,
                preferred_maintenance_window="sat:06:00-sat:08:00",
                publicly_accessible=False,
            )
        )

        for private_subnet in self._vpc.private_subnets:
            sg.add_ingress_rule(
                peer=Peer.ipv4(private_subnet.ipv4_cidr_block),
                connection=Port.tcp(db.db_instance_endpoint_port),
                description=f"Allow access to DB in {self.stack_name} from {private_subnet.subnet_id}",
            )

    @property
    @lru_cache
    def _vpc(self):
        return Vpc.from_lookup(
            self,
            "VpcLookup",
            is_default=False,
            region="eu-west-1",
            tags={"Product": "vpc"},
        )
