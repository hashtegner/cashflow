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

# resource "aws_glue_job" "cashflow_update_refined" {
#   name = "cashflow-update-refined"
#   description = "Update refined stocks data"
#   role_arn = aws_iam_role.cashflow_role.arn
#   glue_version = "5.0"
#   worker_type = "G.1X"
#   number_of_workers = 2
#   execution_class = "STANDARD"

#   command {
#     script_location = "s3://${var.s3_data_bucket_name}/glue/update_refined.py"
#     name = "glueetl"
#     python_version = "3.9"
#   }

# }

