//OACの設定
resource "aws_cloudfront_origin_access_control" "booklog" {
  name                              = "booklog"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

//CloudFrontのAPI Gateway向けキャッシュポリシー
data "aws_cloudfront_cache_policy" "cache_policy_apigateway" {
  name = "Managed-CachingDisabled" //AWSマネージドのキャッシュを無効化するポリシー
}

//CloudFrontのAPI Gateway向けオリジンリクエストポリシー
data "aws_cloudfront_origin_request_policy" "origin_request_policy_apigateway" {
  name = "Managed-AllViewerExceptHostHeader" //Host以外（クエリ文字列など）を付加する
}


//CloudFrontディストリビューション
resource "aws_cloudfront_distribution" "booklog" {
  //静的コンテンツが置かれているS3バケットへの紐づけ
  origin {
    domain_name              = aws_s3_bucket.booklog.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.booklog.id
    origin_id                = "s3-booklog"
  }

  //リクエスト処理を行うAPI Gatewayへの紐づけ
  origin {
    domain_name = trimprefix(aws_apigatewayv2_api.bookLog_api.api_endpoint, "https://")
    origin_id   = "apigateway-booklog"

    //API Gatewayへのアクセスの設定
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_protocol_policy = "https-only"
    }
  }

  enabled             = true         //ディストリビューションを有効化する
  default_root_object = "index.html" //デフォルトでみるS3内のファイル

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"] //S3バケット内のファイルを取得するためのメソッド
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-booklog"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https" //http通信をhttpsにリダイレクトする
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  //API Gatewayへのリクエスト送信の振る舞いを設定
  ordered_cache_behavior {
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT", "DELETE"]                  //API GatewayにGET, POST, PUT, DELETEを送るため、CloudFrontの仕様上7つすべてを指定する必要がある
    cached_methods           = ["GET", "HEAD"]                                                               //キャッシュは使わないため最低限
    cache_policy_id          = data.aws_cloudfront_cache_policy.cache_policy_apigateway.id                   //レスポンスをキャッシュに入れない
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.origin_request_policy_apigateway.id //クエリ文字を含めた情報を送信するために設定
    path_pattern             = "/api/*"                                                                      //URLに/apiから始まるものを対象とする
    target_origin_id         = "apigateway-booklog"                                                          //originに指定したAPI Gatewayをターゲットとする
    viewer_protocol_policy   = "https-only"                                                                  //JavaScriptからのリクエストで基本はhttpsのためhttpsのみを受け付けるようにする
  }

  //北米・欧州のみを使用し、最安のものを使用する
  price_class = "PriceClass_100"

  //アクセス制限に関する設定
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "booklog"
  }

  //SSL証明書の設定
  viewer_certificate {
    //CloudFrontデフォルトのものを使用する
    cloudfront_default_certificate = true
  }

  //パスへの直接アクセスの際、index.htmlにリダイレクトする
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }
}

//ドメイン名をアウトプットする
output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.booklog.domain_name
}