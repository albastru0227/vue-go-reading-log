resource "aws_s3_bucket" "booklog" {
  bucket = "booklog-saito-20260923"

  tags = {
    Name = "booklog-saito-20260923"
  }
}

//パブリックアクセスブロック
resource "aws_s3_bucket_public_access_block" "booklog" {
  bucket = aws_s3_bucket.booklog.id

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

//バケットポリシー
data "aws_iam_policy_document" "s3_cloudfront" {
  statement {
    actions = [ 
        "s3:GetObject"
    ]

    resources = [ 
        "${aws_s3_bucket.booklog.arn}/*"
    ]

    principals {
      type = "Service"
      identifiers = [ "cloudfront.amazonaws.com" ]
    }

    condition {
      test = "StringEquals"
      variable = "AWS:SourceArn"
      values = [ aws_cloudfront_distribution.booklog.arn ]
    }
  }
}

resource "aws_s3_bucket_policy" "booklog" {
  bucket = aws_s3_bucket.booklog.id
  policy = data.aws_iam_policy_document.s3_cloudfront.json
}