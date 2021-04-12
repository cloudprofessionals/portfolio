
data "aws_iam_policy_document" "api-gateway-lambda-policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = [
        "lambda.amazonaws.com",
        "apigateway.amazonaws.com"
      ]
    }
  }
}


