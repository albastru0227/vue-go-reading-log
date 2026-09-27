//Lambda関数
resource "aws_lambda_function" "bookLog_function" {
  filename      = "${path.module}/../placeholder.zip" // 関数作成時の仮コード。実際のコードはGitHub Actionsがデプロイする
  function_name = "bookLog_function"
  role          = aws_iam_role.role_for_booklog.arn
  handler       = "bootstrap"

  runtime = "provided.al2023" //goはコンパイル言語であるため、runtimeにはamazon linux2023を選択

  architectures = ["x86_64"] //GOARCH=amd64でビルドしたバイナリに合わせてx86_64を指定

  // コードはCIが管理するため、filenameの差分はTerraformの管理対象外とする
  lifecycle {
    ignore_changes = [filename]
  }
}

//API Gatewayからのアクセスを許可
resource "aws_lambda_permission" "allow_apigateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction" //Lambdaの呼び出しを意味する
  function_name = aws_lambda_function.bookLog_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.bookLog_api.execution_arn}/*/*"
}