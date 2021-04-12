resource "aws_iam_role" "api_gateway_lambda_role" {
  name = "api_gateway_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.api-gateway-lambda-policy.json
  path = "/"
}

resource "aws_iam_policy_attachment" "api_gateway_lambda_policy_attachment" {
  for_each = toset(var.aws_managed_policies)
  name = "api_gateway_lambda_policy_attachment"
  policy_arn = each.key
  roles = [
    aws_iam_role.api_gateway_lambda_role.name
  ]
}
