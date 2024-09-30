#!/usr/bin/env python3

import os

from aws_cdk import App, Stage, Environment, Tags
from aws_cdk.aws_iam import AccountPrincipal

from app.local_office_search_api import LocalOfficeSearchApiDeployment
from infrastructure.ecr import EcrRepository
from infrastructure.db import LocalOfficeSearchDatabase


app = App()

app_version = os.environ.get("IMAGE_TAG", "local")

ACCOUNT_IDS = {
    "devops": "979633842206",
    "prod2": "912473634278"
}

LSS_FILES = {
    "dev": "sandbox-advicelocationpipe-pipelinebucket263ac468-19wuk9oanxght",
    "prod": "prod-advicelocationprodbucket-buckete75ea64c-1oasp6hbbkp4j"
}

GEO_DATA_FILES = {
    "dev": ("uat-geo-data-postcodes-raw-eu-west-1", "Geo_postcodes_csv_uat.csv"),
    "prod": ("prod-onsgeodata-buckete75ea64c-phllx3dqnkmx", "geo_postcodes_prod.csv"),
}

STAGES = [
    Stage(app, "dev", env=Environment(account=ACCOUNT_IDS["devops"], region="eu-west-1")),
    Stage(app, "prod", env=Environment(account=ACCOUNT_IDS["prod2"], region="eu-west-1"))
]

# shared infra - this is deployed to the devops account, but is used in production and tagged as such
# so in the workflow, it's deployed in the prod stage
EcrRepository(
    app,
    "LocalOfficeSearchApiEcrRepo",
    env=Environment(account=ACCOUNT_IDS["devops"], region="eu-west-1"),
    pull_principals=[AccountPrincipal(ACCOUNT_IDS["prod2"])],
    tags={"Environment": "prod"},
)

for stage in STAGES:
    db_stack = LocalOfficeSearchDatabase(
        stage,
        "LocalOfficeSearchApiDb"
    )
    LocalOfficeSearchApiDeployment(
        stage,
        "LocalOfficeSearchApiDeployment",
        app_image_version=app_version,
        db=db_stack.db,
        db_credentials=db_stack.db_credentials,
        lss_bucket_name=LSS_FILES[stage.stage_name],
        geo_data_bucket_name=GEO_DATA_FILES[stage.stage_name][0],
        geo_data_postcode_file=GEO_DATA_FILES[stage.stage_name][1],
    )

for child in app.node.children:
    Tags.of(child).add(key="TechnicalOwner", value="contentplatform@citizensadvice.org.uk")
    Tags.of(child).add(key="Product", value="corporate_site")
    Tags.of(child).add(key="Component", value="local_office_search_api")
    if isinstance(child, Stage):
        stage_name = child.stage_name
        Tags.of(child).add(key="Stage", value=stage_name)
        Tags.of(child).add(key="Environment", value=stage_name)

app.synth()
