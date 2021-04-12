#create client script for testing sample api
resource "local_file" "rest_client_file" {
  content = templatefile("${path.module}/templates/client.tpl",
  {
    api_key = aws_api_gateway_api_key.api_key.value,
    api_endpoint = aws_api_gateway_stage.api_stage.invoke_url,
  })
  filename = "${path.module}/test/client.py"
  depends_on = [null_resource.lambda_package]
}