# create s3 to store the files to be analyzed
resource "aws_s3_bucket" "athena_s3_bucket" {
  bucket = var.athena_s3_bucket
  acl = "private"
  tags = merge(
  {
    "Name" = "aws_tickets_files",
  },
  var.tags,
  )
}

#create directories to store sample tickets and athena output results
resource "aws_s3_bucket_object" "folder1" {
  bucket = aws_s3_bucket.athena_s3_bucket.id
  acl    = "private"
  key    = "results"
  source = "/dev/null"
}

#upload sample data files
resource "aws_s3_bucket_object" "object" {
  for_each = fileset("${path.module}/sample", "*")
  bucket = aws_s3_bucket.athena_s3_bucket.id
  key    = "tickets/${each.key}"
  source = "${path.module}/sample/${each.value}"
  etag   = filemd5("${path.module}/sample/${each.value}")
}