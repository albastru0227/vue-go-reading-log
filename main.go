package main

import (
	"context"
	"encoding/json"
	"log"
	"time"

	"github.com/google/uuid"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
)

// 変数の定義
const tableName = "vue-go-reading-log" //DynamoDBのテーブル名
var client *dynamodb.Client

// 読書アプリに必要な属性をまとめた構造体
type ReadLog struct {
	Id        string     `dynamodbav:"Id" json:"id"`
	Title     string     `dynamodbav:"Title" json:"title"`
	Author    string     `dynamodbav:"Author" json:"author"`
	Note      *string    `dynamodbav:"Note" json:"note"`
	Status    string     `dynamodbav:"Status" json:"status"`
	CreatedAt time.Time  `dynamodbav:"CreatedAt" json:"createdAt"`
	Completed *time.Time `dynamodbav:"Completed" json:"completed"` //*time.Timeにすることで読了していない場合は空欄にすることができる
	Rating    *int       `dynamodbav:"Rating" json:"rating"`
}

// AWS設定の読み込みとクライアントの作成を行う関数
func init() {
	//デフォルトのAWSの設定を取得
	cfg, err := config.LoadDefaultConfig(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	//DynamoDBに接続するためのクライアントを作成
	client = dynamodb.NewFromConfig(cfg)
}

func main() {
	lambda.Start(handler)
}

// context.Content: Lambda実行の残り時間などが含まれる。Lambdaのハンドラーでは必ず第一引数にする
// events.APIGatewayV2HTTPRequest: API Gatewayが持っているHTTPリクエスト（JSON形式）
// events.APIGatewayV2HTTPResponse: API Gatewayに返すレスポンス
func handler(ctx context.Context, req events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	//RouteKey: API Gateway側で定義したMethodとPathの組み合わせ
	switch req.RouteKey {
	case "GET /books":
		//一覧取得
		return getBooks(req)
	case "POST /books":
		//登録
		return createBook(req)
	case "GET /books/{id}":
		//1件取得
		return getBook(req)
	case "PUT /books/{id}":
		//更新
		return updateBook(req)
	case "DELETE /books/{id}":
		//削除
		return deleteBook(req)
	default:
		//どれにも該当しない場合の処理
		return events.APIGatewayV2HTTPResponse{
			StatusCode: 404,
			Body:       "not found",
		}, nil
	}
}

// 処理成功時のレスポンス用関数
func jsonResponse(statusCode int, data any) (events.APIGatewayV2HTTPResponse, error) {
	//取得したデータをAPI Gateway用に変換する
	body, err := json.Marshal(data)
	if err != nil {
		return events.APIGatewayV2HTTPResponse{
			StatusCode: 500,
			Body:       err.Error(),
		}, nil
	}

	//API Gatewayにレスポンスを送る
	return events.APIGatewayV2HTTPResponse{
		StatusCode: statusCode,
		Headers:    map[string]string{"Content-Type": "application/json"},
		Body:       string(body),
	}, nil
}

// エラー発生時のレスポンス用関数
func errorResponse(statusCode int, err error) (events.APIGatewayV2HTTPResponse, error) {
	return events.APIGatewayV2HTTPResponse{
		StatusCode: statusCode,
		Body:       err.Error(),
	}, nil
}

func getBooks(req events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	//クエリパラメータの取得
	status := req.QueryStringParameters["status"]

	//ステータスのクエリパラメータが空の時の処理
	if status == "" {
		//dynamoDBからデータを取得
		scan, err := client.Scan(context.Background(), &dynamodb.ScanInput{
			TableName: aws.String(tableName),
		})
		if err != nil {
			return errorResponse(500, err)
		}

		//取得したデータをgoの形式に変換して格納
		var scanLogs []ReadLog
		err = attributevalue.UnmarshalListOfMaps(scan.Items, &scanLogs)
		if err != nil {
			return errorResponse(500, err)
		}

		//格納したデータを返す
		return jsonResponse(200, scanLogs)
	} else {
		//ExpressionAttributeValuesに引き渡すための型変換
		value, err := attributevalue.MarshalMap(map[string]string{":status": status})
		if err != nil {
			return errorResponse(500, err)
		}

		//指定されたステータスのみのデータをDyanmoDBから取得
		queryResult, err := client.Query(context.Background(), &dynamodb.QueryInput{
			TableName:                 aws.String(tableName),
			IndexName:                 aws.String("status-index"),             //GSIの名前
			KeyConditionExpression:    aws.String("#status = :status"),        //dynamoDBに渡す値
			ExpressionAttributeNames:  map[string]string{"#status": "Status"}, //KeyConditionExpressionのKeyに入れる値の定義
			ExpressionAttributeValues: value,                                  //KeyConditionExpressionのvalueに入れる値
		})
		if err != nil {
			return errorResponse(500, err)
		}

		//取得したデータをGO用に変換
		var querylogs []ReadLog
		err = attributevalue.UnmarshalListOfMaps(queryResult.Items, &querylogs)
		if err != nil {
			return errorResponse(500, err)
		}

		//取得したデータを表示
		return jsonResponse(200, querylogs)
	}

}

func createBook(req events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	//リクエストを受け取る
	var newBook ReadLog
	if err := json.Unmarshal([]byte(req.Body), &newBook); err != nil {
		return errorResponse(400, err)
	}

	//受け取ったリクエストにID、作成日時、評価を加える
	newBook.Id = uuid.New().String()
	newBook.CreatedAt = time.Now()
	newBook.Status = "未読"

	//取得したリクエストをDynamoDB用に変換する
	av, err := attributevalue.MarshalMap(newBook)
	if err != nil {
		return errorResponse(500, err)
	}

	//リクエストをDynamoDBに格納する
	_, err = client.PutItem(context.Background(), &dynamodb.PutItemInput{
		TableName: aws.String(tableName),
		Item:      av,
	})
	if err != nil {
		return errorResponse(500, err)
	}

	//処理成功時のレスポンス
	return jsonResponse(201, newBook)
}

func getBook(req events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	//指定されたidを取得する
	id := req.PathParameters["id"]

	//idをdynamodb形式に変換する
	readId := map[string]string{"Id": id}
	av, err := attributevalue.MarshalMap(readId)
	if err != nil {
		return errorResponse(500, err)
	}

	//idを持つデータをdynamodbから取得する
	book, err := client.GetItem(context.Background(), &dynamodb.GetItemInput{
		TableName: aws.String(tableName),
		Key:       av,
	})
	if err != nil {
		return errorResponse(500, err)
	}

	//取得したデータをgo用に変換する
	var bookData ReadLog
	err = attributevalue.UnmarshalMap(book.Item, &bookData)
	if err != nil {
		return errorResponse(500, err)
	}

	//取得したデータを返す
	return jsonResponse(200, bookData)
}

func deleteBook(req events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	//指定されたidの取得
	id := req.PathParameters["id"]

	//idをdynamodb形式に変換する
	deleteId := map[string]string{"Id": id}
	av, err := attributevalue.MarshalMap(deleteId)
	if err != nil {
		return errorResponse(500, err)
	}

	//指定されたIDのデータを削除する
	_, err = client.DeleteItem(context.Background(), &dynamodb.DeleteItemInput{
		TableName: aws.String(tableName),
		Key:       av,
	})
	if err != nil {
		return errorResponse(500, err)
	}

	//削除されたことをレスポンスする
	return jsonResponse(200, map[string]string{"message": "deleted"})
}

func updateBook(req events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	//idを取得する
	id := req.PathParameters["id"]

	//リクエストを取得する
	var updateLog ReadLog
	if err := json.Unmarshal([]byte(req.Body), &updateLog); err != nil {
		return errorResponse(400, err)
	}

	//idをdynamodb用にmarshalmapする
	updateId := map[string]string{"Id": id}
	av, err := attributevalue.MarshalMap(updateId)
	if err != nil {
		return errorResponse(500, err)
	}

	//dynamodbで変更対象のデータを取得する
	book, err := client.GetItem(context.Background(), &dynamodb.GetItemInput{
		TableName: aws.String(tableName),
		Key:       av,
	})
	if err != nil {
		return errorResponse(500, err)
	}

	//取得したデータをunmarshalmapする
	var beforeLog ReadLog
	err = attributevalue.UnmarshalMap(book.Item, &beforeLog)
	if err != nil {
		return errorResponse(500, err)
	}

	//リクエストの整形
	if updateLog.Status == "読了" {
		now := time.Now()
		updateLog.Completed = &now
	} else {
		updateLog.Completed = nil
	}

	updateLog.Id = id
	updateLog.CreatedAt = beforeLog.CreatedAt

	//リクエストをmarshalmap
	updateav, err := attributevalue.MarshalMap(updateLog)
	if err != nil {
		return errorResponse(500, err)
	}

	//DynamoDBのデータを更新する
	_, err = client.PutItem(context.Background(), &dynamodb.PutItemInput{
		TableName: aws.String(tableName),
		Item:      updateav,
	})
	if err != nil {
		return errorResponse(500, err)
	}

	//処理成功時のレスポンス
	return jsonResponse(200, map[string]string{"message": "updated"})
}
