## Description
Layout Management infrastructure terraform files

## Deploy infrastructure
Initialize a working directory containing Terraform configuration files

```sh
terraform init
```

Create an execution plan. You must to be configured a default AWS connection or set when you execute your plan.
The credentials attached to custom domain for our API Gateway nust be in the same region

```sh
terraform plan -var 'aws_profile=default' -var 'aws_region=us-east-2' -var 'environment=v1'
```

Apply the changes required to reach the desired state of the configuration using the following command

```sh
terraform plan -var 'aws_profile=default' -var 'aws_region=us-east-2' -var 'environment=v1'
```
