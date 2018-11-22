#!/bin/bash
#
# Build the lambda
#

# Check for prerequisites
if ! command -v pip;
then
  echo "Error: please ensure 'pip' is installed and in your \$PATH";
  exit 1;
fi
if ! command -v zip;
then
  echo "Error: please ensure 'zip' is installed and in your \$PATH";
  exit 1;
fi

# create a python dependency folder install dependencies
mkdir -vp lambda/git_hooks/package;
pip install certifi urllib3 boto3 --target lambda/git_hooks/package/;

# zip it all up ready for deployment to aws lambda
cd lambda/git_hooks/package;
zip -r9 ../lambda.zip .;
cd ../;
zip -g lambda.zip lambda.py;
