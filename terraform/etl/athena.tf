#create athena database
resource "aws_athena_database" "etl_demo" {
  name = var.athena_db_name
  bucket = aws_s3_bucket.athena_s3_bucket.bucket
}

#create athena table for data parsing
resource "aws_glue_catalog_table" "etl_athena_table" {
  for_each = var.athena_table_config
  name          = each.value.table_name
  database_name = aws_athena_database.etl_demo.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL = "TRUE"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.athena_s3_bucket.bucket}/tickets/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
//    output_format = "org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat"
    ser_de_info {
      name                  = "jsonserde"
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = each.value.column_name
      type = each.value.type
    }

  }
}
