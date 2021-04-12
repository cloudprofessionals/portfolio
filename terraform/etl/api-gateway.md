#API Gateway Deployment
This is a documentation on the API Gateway implementation for CUR AWS Project

## Introduction
The purpose of this guide is to provide instructions on design and implementation of API Gateway for CUR AWS Project.

# Disclaimer
AWS is a Pay As You Go provider, as result the use of this instruction may result in usage charges. We're in no way 
responsible for any cost incurred from resources created using this documentation.

#Architecture
The code in this documentation will create the following resources via Terraform
* Api Gateway
* Lambda Function
* Cloudwatch Log Groups

![Architecture](arch_diagram.png)

## Pre-requisite
Ensure you have the following tools installed and configured before proceeding. All instructions provided
here assume you have a unix-like environment.

#### AWS CLI
* Follow the instructions on official Amazon Web Services site to [install](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
AWS CLI on your local machine using platform instructions applicable to you.

#### Configure AWS Credentials
Please ensure you aws credentials configured for your environment [aws credentials]()