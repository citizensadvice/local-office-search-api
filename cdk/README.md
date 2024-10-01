# Welcome to your CDK Python project!

This is a blank project for CDK development with Python.

The `cdk.json` file tells the CDK Toolkit how to execute your app.

This project uses [Poetry](https://python-poetry.org).

To manually tell Poetry to use a specific Python version (you need to have the executable in your PATH):

```
$ poetry env use 3.11.0
```

Once the virtualenv is activated, you can install the required dependencies.

```
$ poetry install
```

At this point you can now synthesize the CloudFormation template for this code.

```
$ cdk synth
```

Alternatively you may need to prepend the cdk command with poetry like so:

```
$ poetry run cdk synth
```

## Useful commands

- `cdk ls` list all stacks in the app
- `cdk synth` emits the synthesized CloudFormation template
- `cdk deploy` deploy this stack to your default AWS account/region
- `cdk diff` compare deployed stack with current state
- `cdk docs` open CDK documentation

Enjoy!
