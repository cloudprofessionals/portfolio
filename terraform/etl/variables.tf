
variable "tags" {
  description = "tags to associate with this instance"
  type = map(string)
}
variable "stack_name" {
  description = "name of the project"
  type = string
}
variable "region" {
  description = "aws region to deploy"
  type = string
}
variable "profile" {
  description = "iam user profile to use"
  type = string
}
variable "iam_role_name" {
  type = string
  description = "name of the iam role to use for lambda and the api gateway"
}
variable "api_gateway_name" {
  description = "name of the api gateway"
  type = string
}
variable "api_key_name" {
  description = "name of the api key"
  type = string
}
variable "api_stage_name" {
  description = "name of the api stage deployment"
  type = string
}
variable "cloudwatch_log_group_name" {
  description = "name of cloudwatch log group for the api gateway"
  type = string
}
variable "api_usage_plan_name" {
  description = "name of the api usage plan"
  type = string
}
variable "athena_s3_bucket" {
  description = "name of the s3 bucket that holds files to be used by athena"
  type = string
}
variable "aws_managed_policies" {
  description = "use pre-defined managed policies"
  type = list(string)
  default = [
    "arn:aws:iam::aws:policy/AWSLambda_FullAccess",
    "arn:aws:iam::aws:policy/AmazonAPIGatewayInvokeFullAccess",
    "arn:aws:iam::aws:policy/AmazonAthenaFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  ]
}
variable "athena_s3_folders" {
  description = "name of the folders to be created in athena_s3_bucket"
  type = list(string)
  default = [
    "tickets",
    "results"
  ]
}
variable "athena_table_config" {
  description = "map of athena table and columns definition"
  default = {
    tickets = {
      table_name = "tickets"
      column_name = "cases"
      type = "array<struct<caseId:string,categoryCode:string,displayId:string,language:string,serviceCode:string,severityCode:string,status:string,subject:string,submittedBy:string,timeCreated:string>>"
    }
    ticket_details = {
      table_name = "ticket_details"
      column_name = "cases"
      type = "array<struct<recentcommunications:struct<communications:array<struct<body:string,caseid:string,submittedby:string,timecreated:string>>>>>"
    }
  }
}
variable "athena_db_name" {
  description = "the name of the athena database to be created"
  type = string
}