# Example AWS Security Group updates via Lambda

## The goal

Manage AWS Security Groups with automations

1. "github_hooks" - Regularly updated AWS SG based on https://api.github.com/meta (hooks) IPs (TCP 443 & 80)

Due to time contraints, the below are not implemented here

2. "developers_ips" - Add IPs via script or API to an AWS SG (TCP 443 & 80)

**Warning:** this is not for production and is a guide only. Here be dragons.

## Contents

* [Requirements](#requirements)
* [Just deploy it already (TL;DR)](#just-deploy-it-already-tldr)
* [Design](#design)
  * [git_hooks](#git_hooks)
  * [developers_ips](#developers_ips)

## Requirements

* Hashicorp's Terraform - https://www.terraform.io/downloads.html (tested with 0.11.10)
* zip command line tool
* python3 and pip
* curl (or a browser)
* AWS Account (with keys in ENV vars or `~/.aws/credentials`), with the ability to create public EC2 SGs, API Gateways and Lambdas in the us-east-1 region

## Just deploy it already (TL;DR)

We recommend reading the rest of this guide first.
But for those who which to jump straight in the lake without looking:

1. Clone this repo and `cd` into this directory
2. Create the S3 bucket
```
./build.sh
```
3. Deploy the AWS infrastructure, including Security Group and Lambda
```
./deploy.sh
```
4. Test by calling the API Gateway provided as "base_url", should return "Update Complete!"
E.g.:
```
curl https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/test
```
5. Cleanup and wipe all traces (yes at the prompt)
```
./destroy.sh
```

## Design

### git_hooks
```
+--------------------+
|  CloudWatch Event  | --+
|  rate(12 hours)    |   |
+--------------------+   |    +----------+     +----------------------+
                         +--> |  Lambda  | --> |  AWS Security Group  |
+--------------------+   |    +----------+     +----------------------+
|  API Gateway       |   |
|  /test             | --+
+--------------------+
```

**General Concept**

The above design for this project based around the concept of efficiency and automation. For this reason we've chosen to deploy everything with Terraform and keep work and maintenance to a minimum by using AWS Lambda and API Gateway.

This could have been solved with EC2 instances and other code, but would require significantly more work to lock down, cost a lot more to run, and have many more parts to maintain.

**Downsides?**

I'd not used much Python and never API Gateway or Lambdas before this - this will be a bit rough and not production ready.

Much of the code here is based on the Terraform examples and an example python lambda [here](https://blog.eq8.eu/til/configure-aws-lambda-to-alter-security-groups.html).

### developers_ips

Not implemented, only proposed.

**Proposed Concept**
```
+--------------------+     +--------------------+     +----------+     +----------------------+
|  Slack Webhook     | --> |  API Gateway       | --> |  Lambda  | --> |  AWS Security Group  |
|  /addip x.x.x.x    |     |  /slack            |     +----------+     +----------------------+
+--------------------+     +--------------------+
```