module "step_functions" {
  source = "terraform-aws-modules/step-functions/aws"

  name = "cashflow"
  type = "STANDARD"

  use_existing_role = true
  role_arn = aws_iam_role.cashflow_role.arn

  definition = jsonencode({
    Comment = "Process the tickers file from S3, extract market info, and persist results with daily partitioning."
    StartAt = "ProcessTickerFile"
    QueryLanguage = "JSONata"
    States = {
        ProcessTickerFile = {
            Type = "Map"
            MaxConcurrency = 10
            Label = "ProcessTickerFile"
            Next = "PersistExtractedData"
            ItemBatcher = {
                MaxItemsPerBatch = 10
            }

            ItemReader = {
                Resource = "arn:aws:states:::s3:getObject"
                Arguments = {
                    Bucket = var.s3_data_bucket_name
                    Key = "tickers.csv"
                }
                ReaderConfig = {
                    InputType = "CSV"
                    CSVHeaderLocation = "FIRST_ROW"
                    CSVDelimiter = "COMMA"
                }
            }

            ItemProcessor = {
                ProcessorConfig = {
                    Mode = "DISTRIBUTED"
                    ExecutionType = "STANDARD"
                }
                StartAt = "GetMarketInfo"
                States = {
                    GetMarketInfo = {
                        Type = "Task"
                        Resource = "arn:aws:states:::lambda:invoke"
                        Output = "{% $states.result.Payload %}"
                        End = true
                        Arguments = {
                            FunctionName = aws_lambda_function.cashflow_get_market_info.arn
                            Payload = "{% $states.input %}"
                        }
                        Retry = [
                            {
                                ErrorEquals = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException", "Lambda.TooManyRequestsException"]
                                IntervalSeconds = 3
                                MaxAttempts = 5
                                BackoffRate = 2
                                JitterStrategy = "FULL"
                            }
                        ]
                    }
                }
            }
        }

        PersistExtractedData = {
            Type = "Task"
            Resource = "arn:aws:states:::lambda:invoke"
            Next = "UpdateRaw"
            Arguments = {
                FunctionName = aws_lambda_function.cashflow_persist_market_data.arn
                Payload = {
                    results = "{% $states.input %}"
                    bucket_name = var.s3_data_bucket_name
                }
            }
            Retry = [
                {
                    ErrorEquals = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException", "Lambda.TooManyRequestsException"]
                    IntervalSeconds = 2
                    MaxAttempts = 3
                    BackoffRate = 2
                    JitterStrategy = "FULL"
                }
            ]
        }

        UpdateRaw = {
            Type = "Task"
            Resource = "arn:aws:states:::glue:startJobRun"
            End = true
            Arguments = {
                JobName = aws_glue_job.cashflow_update_raw.name
                Arguments = {
                    "--INPUT_FILE" = "{% $states.input.Payload.file %}"
                }
            }
        }
    }
  })
}
