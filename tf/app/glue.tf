resource "aws_glue_job" "cashflow_update_raw" {
  name = "cashflow-update-raw"
  description = "Update raw stocks data"
  role_arn = aws_iam_role.cashflow_role.arn
  glue_version = "5.0"
  worker_type = "G.1X"
  number_of_workers = 2
  execution_class = "STANDARD"

  command {
    script_location = "s3://${var.s3_data_bucket_name}/glue/update_raw.py"
    name = "glueetl"
    python_version = "3.9"
  }
}


resource "aws_glue_catalog_database" "cashflow" {
  name = "cashflow"
}

resource "aws_glue_catalog_table" "stocks_raw" {
  name = "stocks_raw"
  database_name = aws_glue_catalog_database.cashflow.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "SNAPPY"
  }

  storage_descriptor {
    location = "s3://${var.s3_data_bucket_name}/raw/stocks"
    input_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    compressed = false
    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      parameters = {
        "serialization.format" = "1"
      }
    }

    columns {
      name = "company_name"
      type = "string"
    }

    columns {
      name = "company_sector"
      type = "string"
    }

    columns {
      name = "country"
      type = "string"
    }

    columns {
      name = "industry"
      type = "string"
    }

    columns {
        name = "market"
        type = "string"
    }

    columns {
      name = "date"
      type = "string"
    }

    columns {
      name = "ticker"
      type = "string"
    }

    columns {
        name = "open"
        type = "double"
    }

    columns {
        name = "close"
        type = "double"
    }

    columns {
        name = "high"
        type = "double"
    }

    columns {
        name = "low"
        type = "double"
    }

    columns {
        name = "volume"
        type = "bigint"
    }

    columns {
        name = "retrieve_date"
        type = "string"
    }
  }

  partition_keys {
    name = "process_date"
    type = "int"
  }
}
