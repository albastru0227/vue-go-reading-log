resource "aws_dynamodb_table" "vue_go_reading_log" {
  name           = "vue-go-reading-log"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "Id"

  attribute {
    name = "Id"
    type = "S"
  }

  attribute {
    name = "Status"
    type = "S"
  }

  //ステータスで検索をかけるためにGSIを設定する
  global_secondary_index {
    name = "status-index"
    hash_key = "Status"
    projection_type = "ALL"
  }

  tags = {
    Name        = "vue-go-reading-log"
  }
}