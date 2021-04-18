# Deploying AWS ETL
This is a User documentation on provisioning and deploying sample etl on AWS

## A. Introduction
The purpose of this guide is to provide instructions on how to provision and deploy AWS ETL. This guide assumes that the User has an operating account with Amazon Web Services
[Amazon Web Services](https://aws.amazon.com) and all the necessary administrator's IAM role and permissions in order to create cloud resources. 

### B. Disclaimer
AWS is a Pay As You Go provider, as result the use of this instruction may result in  usage charges. We're in no way responsible for any charges incurred from resources created using this documentation.

All scripts related to this documentation can be found here: [cloudprofessionals](https://github.com/cloudprofessionals/portfolio)

## C. Architecture
The code in this demo will create the following resources via Terraform:

* Rest API Gateway
* Athena
* Lambda
* S3 Bucket

![Architecture](etl/arch_diagram.png)

## D. Pre-requisites
Ensure you have the following tools installed and configured before proceeding. All instructions provided here assumes you have unix-like environment

#### a) AWS CLI
* Follow the instructions on official Amazon Web site to [install](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) AWS CLI on your local machine using platform instruction applicable to you.

#### b) Configure AWS Credentials
Please ensure you have aws credential configured for your environment [aws credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html). This document does not make provision for access and secret keys due to unintended security reasons. 

#### c) Terraform
* Follow the instructions on the official [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html) site to install terraform on your local workstation using platform instruction applicable to you.

#### d) Git
* Follow the instructions on the official [Git](https://github.com/git-guides/install-git) site to install git on your local workstation.



## E. Installations

#### a) Clone cloudprofessionals repo

* Clone  [cloudprofessionals](https://github.com/cloudprofessionals/portfolio) to a working directory. In this guide, I will be using  **/tmp** as my working directory
    
```
cd /tmp && git clone https://github.com/cloudprofessionals/portfolio
```

* Change directory to the scripts location **terraform/etl**

```
cd terraform/etl
```

#### b) Populate vars.tfvars file

*  Using your favorite text editor open and edit **${WORKING-DIRECTORY}/portfio/terraform/etl/vars.tfvars** file. This is a variable file that will be used as input to the terraform. 
*  Please refer to **${WORKING-DIRECTORY}/portfio/terraform/etl/variables.tf** file for full descriptions of each the variables listed in the vars.tfvars file. 
*  At minimum, you will need to provide appropriate values for the following;
	* 	profile - This is the name of the aws crendential profile you set above in step D.a
	*  region - This is the aws region you wish to provision your resources.
	

* Run **terraform init** 

```
terraform init
```

*  Run **terraform plan**. This command gives you insight into all the resources that will be created. Review the output and if satisfy continue to the next step

```
terraform plan -var-file=vars.tfvars
```

* Run **terraform apply** to provision your infrastructure.
```
terraform apply -var-file=vars.tfvars -auto-approve
```

* At this point, if there are no errors your infrastructure will be provisioned. Note it will take about 5 minutes for the application to completely deployed.


### d Verify the ETL deployment
When the deployment is completed, navigate to the **custodian\_url\** to verify that the application is loaded successfully.


### e) Teardown
To destroy resouces created in this demo;

* Run **terraform destroy** to destroy the resources provisioned.

```
terraform destroy -var-file=vars.tfvars -auto-approve
```

