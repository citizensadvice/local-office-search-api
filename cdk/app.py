#!/usr/bin/env python3

from aws_cdk import App, Stage, Environment, Tags
from aws_cdk.aws_iam import AccountPrincipal

from infrastructure.ecr import EcrRepository
from infrastructure.infrastructure_stack import LocalOfficeSearchApiInfrastructure


app = App()

ACCOUNT_IDS = {
    "devops": "979633842206",
    "prod2": "912473634278"
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
    LocalOfficeSearchApiInfrastructure(
        stage,
        "LocalOfficeSearchApiInfrastructure"
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
