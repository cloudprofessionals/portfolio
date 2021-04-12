#install pyathena
resource "null_resource" "lambda_package" {
  provisioner "local-exec" {
    command = "rm -rf ${path.module}/files/tickets && mkdir  ${path.module}/files/tickets && pip3 install -r ${path.module}/files/requirements.txt -t ${path.module}/files/tickets"
  }
}

#create tickets.py file
resource "local_file" "tickets_python_file" {
  content = templatefile("${path.module}/templates/ticket.tpl",
  {
    region = var.region,
    athena_s3_bucket = var.athena_s3_bucket,
    athena_db = var.athena_db_name,
    tickets_table_name = var.athena_table_config.tickets.table_name,
    ticket_details_table_name = var.athena_table_config.ticket_details.table_name
  })
  filename = "${path.module}/files/tickets/tickets.py"
  depends_on = [null_resource.lambda_package]
}

#package tickets directory into tickets.zip
data "archive_file" "tickets_zip" {
  type        = "zip"
  source_dir  = "${path.module}/files/tickets"
  output_path = "${path.module}/files/tickets.zip"
  depends_on = [local_file.tickets_python_file]
}

#create tickets lambda function
resource "aws_lambda_function" "tickets" {
  filename = "${path.module}/files/tickets.zip"
  function_name = "tickets"
  role = aws_iam_role.api_gateway_lambda_role.arn
  handler = "tickets.handler"
  memory_size = "512"
  runtime = "python3.8"
  timeout = 300
  source_code_hash = data.archive_file.tickets_zip.output_base64sha256
}