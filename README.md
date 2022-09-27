## Description
Layout Management infrastructure terraform files

## Deploy infrastructure
Initialize a working directory containing Terraform configuration files

```sh
terraform init
```

Create an execution plan. 

- You must configure your mango profile in your ~/.aws/credentials with the credentias: aws access and secret keys. 
- If you select a diferent default aws_region you must create and validate your certificate for your Custom DNS API Gateway in the same region selected and configure de default domain_arn_certificate correctly.
- If you select a diferent default domain_name you must create your certificate for your Custom DNS API Gateway

```sh
terraform plan -var 'aws_profile=mango' -var 'environment=v1'
```

Apply the changes required to reach the desired state of the configuration using the following command

```sh
terraform apply -var 'aws_profile=mango' -var 'environment=v1'
```

Apply the changes required to reach the desired state of the configuration using the following command

```sh
terraform plan -var 'aws_profile=default' -var 'aws_region=us-east-2' -var 'environment=v1'
```
