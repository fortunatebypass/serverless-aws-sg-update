#!/bin/bash
#
# Deploy tool
#
# Uses terraform to deploy the AWS stack including:
#  * Security Groups
#  * IAM Roles
#  * Lambda
#  * API Gateway
#

# Check for prerequisites
if ! command -v terraform;
then
  echo "Error: please ensure 'terraform' is installed and in your \$PATH";
  exit 1;
fi

# ensure build is already complete
if [ ! -f lambda/lambda.zip ];
then
  echo "Error: unable to locate lambda/lambda.zip - please run 'build.sh' first";
  exit 1;
fi

# set up terraform
terraform init;

# prepare terraform plan
terraform plan -out serverless.tfplan;

# build aws stack using terraform
terraform apply serverless.tfplan;