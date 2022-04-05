variable "aws_profile" {
    description = "AWS profile for provisioning resources."
    default = "default"
}

variable "aws_region" {
    description = "AWS provisioning region."
    default = "us-east-2"
}

variable "table_name" {
    description = "Dynamodb table name (space is not allowed)."
    default = "Layout"
}

variable "table_billing_mode" {
    description = "Controls how you are charged for read and write throughput and how you manage capacity."
    default = "PAY_PER_REQUEST"
}

variable "environment" {
    description = "API Version."
    default = "v1"
}

variable "domain_arn_certificate" {
    description = "API Gateway Domain certificate."
    default = "arn:aws:acm:us-east-2:924628188769:certificate/19df35c7-911e-4548-8d04-9d6abf18ba43"
}

variable "domain_name" {
    description = "API Gateway Domain name."
    default = "api.oferto.io"
}
