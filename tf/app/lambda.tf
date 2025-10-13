resource "aws_lambda_function" "cashflow_get_market_info" {
    function_name = "cashflow_get_market_info"
    role = aws_iam_role.cashflow_role.arn

    package_type = "Image"
    image_uri = var.lambda_image_uri
    architectures = ["x86_64"]
    timeout = 30 # 30 seconds

    image_config {
        command = ["get_market_info.handler"]
    }
}

resource "aws_lambda_function" "cashflow_persist_market_data" {
    function_name = "cashflow_persist_market_data"
    role = aws_iam_role.cashflow_role.arn

    package_type = "Image"
    image_uri = var.lambda_image_uri
    architectures = ["x86_64"]
    timeout = 60 # 60 seconds for S3 operations


    image_config {
        command = ["write_market_info.handler"]
    }
}
