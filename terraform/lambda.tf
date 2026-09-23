//goファイルを圧縮する
data "archive_file" "zip_bootstrap" {
  type        = "zip"
  source_file = "${path.module}/../bootstrap"
  output_path = "${path.module}/../bootstrap.zip"
}

//Lambda関数
resource "aws_lambda_function" "bookLog_function" {
  filename      = data.archive_file.zip_bootstrap.output_path //zip化したgoのバイナリファイル
  function_name = "bookLog_function"
  role          = aws_iam_role.role_for_booklog.arn
  handler       = "bootstrap"
  source_code_hash   = data.archive_file.zip_bootstrap.output_base64sha256

  runtime = "provided.al2023" //goはコンパイル言語であるため、runtimeにはamazon linux2023を選択

  architectures = [ "x86_64" ] //x86_64とarn64の両方に対応させる
}

//API Gatewayからのアクセスを許可
resource "aws_lambda_permission" "allow_apigateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction" //Lambdaの呼び出しを意味する
  function_name = aws_lambda_function.bookLog_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.bookLog_api.execution_arn}/*/*"
}