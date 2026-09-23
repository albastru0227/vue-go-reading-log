//API Gateway本体
resource "aws_apigatewayv2_api" "bookLog_api" {
  name          = "bookLog-api"
  protocol_type = "HTTP" //HTTP API: リクエストとレスポンスがセットになっている
  
  //クロスオリジンの設定
  cors_configuration {
    allow_origins = [ "http://localhost:5173", "https://d33c8gv5fbhr8f.cloudfront.net" ]
    allow_headers = [ "Content-Type" ]
    allow_methods = [ "GET", "POST", "PUT", "DELETE" ]
  }
}

//リクエストの扱い方を定義する（Lambdaに引き渡す）
resource "aws_apigatewayv2_integration" "integration_lambda" {
  api_id           = aws_apigatewayv2_api.bookLog_api.id
  integration_type = "AWS_PROXY" //リクエスト情報を丸ごと渡す
  integration_uri           = aws_lambda_function.bookLog_function.invoke_arn //統合するLambda関数のARN
  integration_method        = "POST" //API GatewayがLambda関数を呼び出すためPOST
  payload_format_version = "2.0" //version2を指定。RouteKeyなどが含まれるJSONデータを送れる
}

//ルートキーの設定（一覧取得、登録、1件取得、更新、削除）
resource "aws_apigatewayv2_route" "route_GET_books" {
  api_id    = aws_apigatewayv2_api.bookLog_api.id
  route_key = "GET /books"
  target = "integrations/${aws_apigatewayv2_integration.integration_lambda.id}"
}

resource "aws_apigatewayv2_route" "route_POST_books" {
  api_id    = aws_apigatewayv2_api.bookLog_api.id
  route_key = "POST /books"
  target = "integrations/${aws_apigatewayv2_integration.integration_lambda.id}"
}

resource "aws_apigatewayv2_route" "route_GET_book_id" {
  api_id    = aws_apigatewayv2_api.bookLog_api.id
  route_key = "GET /books/{id}"
  target = "integrations/${aws_apigatewayv2_integration.integration_lambda.id}"
}

resource "aws_apigatewayv2_route" "route_PUT_book_id" {
  api_id    = aws_apigatewayv2_api.bookLog_api.id
  route_key = "PUT /books/{id}"
  target = "integrations/${aws_apigatewayv2_integration.integration_lambda.id}"
}

resource "aws_apigatewayv2_route" "route_DELETE_book_id" {
  api_id    = aws_apigatewayv2_api.bookLog_api.id
  route_key = "DELETE /books/{id}"
  target = "integrations/${aws_apigatewayv2_integration.integration_lambda.id}"
}

//APIの公開設定
resource "aws_apigatewayv2_stage" "booklog" {
  api_id = aws_apigatewayv2_api.bookLog_api.id
  name   = "$default" //URLにステージ名を入れないようにする
  auto_deploy = true //API Gatewauの設定変更時に自動で更新してくれる
}

//Terraform Apply後にAPIのURLを出力させる
output "api_endpoint" {
  value = aws_apigatewayv2_api.bookLog_api.api_endpoint
}