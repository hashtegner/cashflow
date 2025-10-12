resource "aws_lambda_function" "cashflow_get_market_info" {
    function_name = "cashflow_get_market_info"
    role = aws_iam_role.lambda_role.arn

    package_type = "Image"
    image_uri = var.lambda_image_uri
    architectures = ["x86_64"]
    timeout = 30 # 30 seconds

    image_config {
        command = ["get_market_info.handler"]
    }
}
