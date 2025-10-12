module "step_functions" {
  source = "terraform-aws-modules/step-functions/aws"

  name = "cashflow-get-market-info"
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
            End = true
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
                                IntervalSeconds = 1
                                MaxAttempts = 3
                                BackoffRate = 2
                                JitterStrategy = "FULL"
                            }
                        ]
                    }
                }
            }
        }

    }
  })

#   definition = <<EOF
#   {
#     "Comment": "Process the tickers file from S3, extract market info, and persist results with daily partitioning.",
#     "StartAt": "ProcessTickerFile",
#     "QueryLanguage": "JSONata",
#     "End": true,
#     "States": {
#       "ProcessTickerFile": {
#         "Type": "Map",
#         "MaxConcurrency": 10,
#         "Label": "ProcessTickerFile",
#         "End": true,
#         "ItemBatcher": {
#           "MaxItemsPerBatch": 10
#         },

#         "ItemReader": {
#           "Resource": "arn:aws:states:::s3:getObject",
#           "ReaderConfig": {
#             "InputType": "CSV",
#             "CSVHeaderLocation": "FIRST_ROW",
#             "CSVDelimiter": "COMMA"
#           },
#           "Arguments": {
#             "Bucket": "${var.s3_data_bucket_name}",
#             "Key": "tickers.csv"
#           }
#         },

#         "ItemProcessor": {
#           "ProcessorConfig": {
#             "Mode": "DISTRIBUTED",
#             "ExecutionType": "STANDARD"
#           },
#           "StartAt": "GetMarketInfo",
#           "States": {
#             "GetMarketInfo": {
#               "Type": "Task",
#               "Resource": "arn:aws:states:::lambda:invoke",
#               "Output": "{% $states.result.Payload %}",
#               "End": true,
#               "Arguments": {
#                 "FunctionName": "${ aws_lambda_function.cashflow_get_market_info.arn }:LATEST",
#                 "Payload": "{% $states.input %}"
#               },
#               "Retry": [
#                 {
#                   "ErrorEquals": ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException", "Lambda.TooManyRequestsException"],
#                   "IntervalSeconds": 1,
#                   "MaxAttempts": 3,
#                   "BackoffRate": 2,
#                   "JitterStrategy": "FULL"
#                 }
#               ],
#             }
#           }
#         }
#       }
#     }
#   }
#   EOF
}
