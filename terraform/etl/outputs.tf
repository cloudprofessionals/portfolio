output "api_endpoint" {
  value = aws_api_gateway_stage.api_stage.invoke_url
}
output "api_key" {
  value = aws_api_gateway_api_key.api_key.value
}