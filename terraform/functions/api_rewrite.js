async function handler(event) {
    var request = event.request; // リクエスト本体
    var uri = request.uri; //URIのパス。パスを書き換える処理を行うため、URIを切り出しておく。

    // /api/booksのようなパスを/booksにする（クエリ文字列は uri に含まれないので影響しない）
    request.uri = uri.replace(/^\/api/, "");

    // 書き換えたリクエストをCloudFrontに返し、そのパスでAPI Gatewayに問い合わせる
    return request;
}