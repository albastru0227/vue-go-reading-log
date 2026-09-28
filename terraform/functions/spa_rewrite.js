async function handler(event) {
    var request = event.request; // リクエスト本体
    var uri = request.uri; //URIのパス。パスを書き換える処理を行うため、URIを切り出しておく。

    // S3向けのリクエストで "." を含まないパスの場合はindex.htmlに変換する
    // 画面のURL（Vue Routerのルートや本のID）には . を含まず、S3上のファイルには拡張子の . がある、という前提で判定している
    if (!uri.includes('.')) {
        request.uri = '/index.html';
    }

    // 書き換えたリクエストをCloudFrontに返し、そのパスでS3に問い合わせる
    return request;
}