#define any tags appropriate to your environment
tags = {
  ManagedBy = "terraform"
  Project = "etl-demo"
  Environment = "demo"
}
region = "change me"
#specify your aws credential profile. Note this is not IAM role but rather profile configured during AWS CLI installation
profile = "change me"
#specify the name you will like to call this project.
stack_name = "etl-demo"
#specify the name of the API Gateway
api_gateway_name = "etl_rest_api"
#specify the name of api key
api_key_name = "etl_api_key"
#provide the name of API Gateway deployment stage
api_stage_name = "demo"
#specify the name of the cloudwatch log group name
cloudwatch_log_group_name = "etl-api-requests/logs"
#specify API Gateway resource usage plan name
api_usage_plan_name = "etl_api_plan"
#provide the name of the iam role for this project
iam_role_name = "etl_iam_role"
#specify the name of the bucket to store sample etl files
athena_s3_bucket = "change me"
athena_db_name = "etl_demo_db"