resource "aws_glue_job" "cashflow_process_extracted_data" {
  name = "cashflow-process-extracted-data"
  description = "Process extracted market data"
  role_arn = aws_iam_role.cashflow_role.arn
  glue_version = "5.0"
  worker_type = "G.1X"
  number_of_workers = 2
  execution_class = "STANDARD"

  command {
    script_location = "s3://${var.s3_data_bucket_name}/glue/process_extracted_data.py"
    name = "glueetl"
    python_version = "3.9"
  }
}
