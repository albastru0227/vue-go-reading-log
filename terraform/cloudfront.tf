//OACの設定
resource "aws_cloudfront_origin_access_control" "booklog" {
  name                              = "booklog"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

//CloudFrontディストリビューション
resource "aws_cloudfront_distribution" "booklog" {
  origin {
    domain_name              = aws_s3_bucket.booklog.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.booklog.id
    origin_id                = "s3-booklog"
  }

  enabled             = true //ディストリビューションを有効化する
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
    error_code = 404
    response_code = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code = 403
    response_code = 200
    response_page_path = "/index.html"
  }
}

//ドメイン名をアウトプットする
output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.booklog.domain_name
}