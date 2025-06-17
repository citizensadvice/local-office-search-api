#!/usr/bin/env python3

import os

from aws_cdk import App, Stage, Environment, Tags

from app.local_office_search_api import LocalOfficeSearchApiDeployment
from infrastructure.db import LocalOfficeSearchDatabase


app = App()

app_version = os.environ.get("IMAGE_TAG", "local")

ACCOUNT_IDS = {"devops": "979633842206", "prod2": "912473634278"}

STAGE_VARS = {
    "dev": {
        "lss_bucket_name": "sandbox-advicelocationpipe-pipelinebucket263ac468-19wuk9oanxght",
        "geo_data_bucket_name": "uat-geo-data-postcodes-raw-eu-west-1",
        "geo_data_postcode_file": "Geo_postcodes_csv_uat.csv",
    },
    "prod": {
        "lss_bucket_name": "prod-advicelocationprodbucket-buckete75ea64c-1oasp6hbbkp4j",
        "geo_data_bucket_name": "prod-onsgeodata-buckete75ea64c-phllx3dqnkmx",
        "geo_data_postcode_file": "geo_postcodes_prod.csv",
    },
}

STAGES = [
    Stage(app, "dev", env=Environment(account=ACCOUNT_IDS["devops"], region="eu-west-1")),
    Stage(app, "prod", env=Environment(account=ACCOUNT_IDS["prod2"], region="eu-west-1")),
]

for stage in STAGES:
    db_stack = LocalOfficeSearchDatabase(
        stage,
        "LocalOfficeSearchApiDb",
        num_replicas=1 if stage.stage_name == "prod" else 0 # enable high availability mode in prod
    )
    LocalOfficeSearchApiDeployment(
        stage,
        "LocalOfficeSearchApiDeployment",
        app_image_version=app_version,
        db=db_stack.db,
        db_credentials=db_stack.db_credentials,
        **STAGE_VARS[stage.stage_name],
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
