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
      name = "reference_date"
      type = "int"
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
        type = "int"
    }
  }

  partition_keys {
    name = "process_date"
    type = "int"
  }
}

resource "aws_glue_catalog_table" "stocks_refined" {
  name = "stocks_refined"
  database_name = aws_glue_catalog_database.cashflow.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "SNAPPY"
  }

  storage_descriptor {
    location = "s3://${var.s3_data_bucket_name}/refined/stocks"
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
      name = "average_price"
      type = "double"
    }

    columns {
      name = "max_high"
      type = "double"
    }

    columns {
      name = "min_low"
      type = "double"
    }

    columns {
      name = "price_avg_7d"
      type = "double"
    }

    columns {
      name = "price_lag_1_month"
      type = "double"
    }

    columns {
      name = "price_lag_2_month"
      type = "double"
    }

    columns {
      name = "price_lag_3_month"
      type = "double"
    }
  }

  partition_keys {
    name = "reference_date"
    type = "string"
  }

  partition_keys {
    name = "ticker"
    type = "string"
  }
}
