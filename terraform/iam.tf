//Lambdaの実行ポリシー

//信頼ポリシー
data "aws_iam_policy_document" "assume_role_for_booklog" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

//IAMポリシー
resource "aws_iam_role" "role_for_booklog" {
  name               = "role_for_booklog"
  assume_role_policy = data.aws_iam_policy_document.assume_role_for_booklog.json
}

//CloudWatch Logsへの出力を許可するマネージドポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_logs" {
  role       = aws_iam_role.role_for_booklog.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

//DynamoDBへの読み書き更新削除クエリのアクションを許可する
data "aws_iam_policy_document" "lambda_use_dynamodb_policy" {
  statement {
    actions = [ 
        "dynamodb:Scan",
        "dynamodb:Query",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
    ]

    resources = [ 
        aws_dynamodb_table.vue_go_reading_log.arn,
        "${aws_dynamodb_table.vue_go_reading_log.arn}/index/*"
    ]
  }
}

resource "aws_iam_role_policy" "role_policy_for_dynamodb_lambda" {
  name = "dynamodb-access"
  role = aws_iam_role.role_for_booklog.id
  policy = data.aws_iam_policy_document.lambda_use_dynamodb_policy.json
}