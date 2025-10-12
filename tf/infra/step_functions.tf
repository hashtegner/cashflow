# Step Functions for CSV processing workflow
resource "aws_sfn_state_machine" "csv_processor" {
  name     = "cashflow-csv-processor"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "Process CSV files from S3 in batches and download market info"
    StartAt = "ProcessCSV"

    ProcessCSV = {
      Type = "Task"
      Resource = "arn:aws:states:::s3:getObject"
      Parameters = {
        Bucket = aws_s3_bucket.cashflow.bucket
        "Key.$" = "$.csvFile"
      }
      Next = "ParseCSV"
    }

    ParseCSV = {
      Type = "Task"
      Resource = "arn:aws:states:::lambda:invoke"
      Parameters = {
        FunctionName = aws_lambda_function.csv_parser.arn
        "Payload.$" = "$"
      }
      Next = "ProcessBatch"
      Retry = [
        {
          ErrorEquals = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"]
          IntervalSeconds = 2
          MaxAttempts = 3
          BackoffRate = 2.0
        }
      ]
    }

    ProcessBatch = {
      Type = "Map"
      ItemsPath = "$.batches"
      MaxConcurrency = 5
      Iterator = {
        StartAt = "GetMarketInfo"
        States = {
          GetMarketInfo = {
            Type = "Task"
            Resource = "arn:aws:states:::lambda:invoke"
            Parameters = {
              FunctionName = aws_lambda_function.cashflow_get_market_info.arn
              "Payload.$" = "$"
            }
            Next = "SaveToS3"
            Retry = [
              {
                ErrorEquals = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"]
                IntervalSeconds = 2
                MaxAttempts = 3
                BackoffRate = 2.0
              }
            ]
          }

          SaveToS3 = {
            Type = "Task"
            Resource = "arn:aws:states:::s3:putObject"
            Parameters = {
              Bucket = aws_s3_bucket.cashflow.bucket
              "Key.$" = "$.outputKey"
              "Body.$" = "$.marketData"
            }
            End = true
          }
        }
      }
      End = true
    }
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.step_functions_logs.arn}:*"
    include_execution_data = true
    level                  = "ERROR"
  }
}

# CloudWatch Log Group for Step Functions
resource "aws_cloudwatch_log_group" "step_functions_logs" {
  name              = "/aws/stepfunctions/cashflow-csv-processor"
  retention_in_days = 14
}

# IAM Role for Step Functions
resource "aws_iam_role" "step_functions_role" {
  name = "cashflow-step-functions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Step Functions
resource "aws_iam_policy" "step_functions_policy" {
  name = "cashflow-step-functions-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.cashflow.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.cashflow_get_market_info.arn,
          aws_lambda_function.csv_parser.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "step_functions_policy_attachment" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = aws_iam_policy.step_functions_policy.arn
}

# Lambda function for CSV parsing
resource "aws_lambda_function" "csv_parser" {
  function_name = "cashflow_csv_parser"
  role          = aws_iam_role.lambda_role.arn

  package_type = "Image"
  image_uri     = var.lambda_image_uri
  architectures = ["x86_64"]
  timeout       = 60 # 60 seconds

  image_config {
    command = ["csv_parser.handler"]
  }
}

# S3 bucket folders for organized data storage
resource "aws_s3_object" "raw_data_folder" {
  bucket = aws_s3_bucket.cashflow.bucket
  key    = "raw-data/"
}

resource "aws_s3_object" "processed_data_folder" {
  bucket = aws_s3_bucket.cashflow.bucket
  key    = "processed-data/"
}

resource "aws_s3_object" "input_data_folder" {
  bucket = aws_s3_bucket.cashflow.bucket
  key    = "input-data/"
}
