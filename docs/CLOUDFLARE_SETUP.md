# Cloudflare初期準備（R2）

## 今すぐ行う範囲

まずCloudflare DashboardでR2を有効化し、開発用の非公開バケットを1つ作るだけで十分です。Workerの作成・デプロイはローカルPoCが通ってから行います。初回のプレイヤー公開先は `workers.dev` を使う予定なので、現時点で独自ドメインやDNS変更は不要です。

## 1. R2を有効化

1. https://dash.cloudflare.com/ にログイン。
2. 左メニューから **R2 Object Storage** を開く。
3. 初回の場合はR2を有効化する。プラン/支払い方法などDashboardに表示される条件を確認する。
4. アカウントIDを控える（公開情報ではないが、秘密鍵でもない）。

## 2. 開発用バケットを作成

1. R2の **Create bucket** を選ぶ。
2. バケット名を `processing-works-dev` などにする。
3. Locationは初期段階では自動選択でよい。
4. 作成後、**Public accessは有効にしない**。
5. オブジェクトロック、イベント通知、ライフサイクル設定などはPoCでは不要。

この段階ではローカルPoCからR2にアクセスしません。バケットを作っておけばPhase 2でWorker bindingを追加できます。

## 3. まだ作らないもの

- 公開バケット / `r2.dev` 公開URL
- 本番用カスタムドメイン
- Worker route / Custom Domain
- R2 API token（まだアップロード実装をしないため）
- DNSレコード変更

これらはローカルPoCが成功してから、必要な権限だけで追加します。

## 4. Phase 2で追加する予定

- Cloudflare Worker: `processing-play-runtime`
- Static Assets directory: `../../public`
- Static Assets binding: `ASSETS`
- Static Assets `run_worker_first`: `/works/*`
- R2 binding名: `WORKS_BUCKET`
- Binding先: `processing-works-dev`（本番では別バケット推奨）
- 初期URL: `<worker-name>.<account-subdomain>.workers.dev`
- R2 key prefix: `published/{workId}/{version}/...`
- Workerの役割: プレイヤー静的ファイルを配信し、`/works/*` はR2からGET/HEAD/Rangeで読み取り専用配信する。

Worker bindingを使うとWorkerがR2を直接操作できるため、ブラウザにR2資格情報を渡す必要がありません。Worker Static AssetsとR2配信が同一オリジンになるので、原則としてR2 CORS設定も不要です。

## 5. 注意

- CloudflareのアカウントID、API Token、Access Key ID、Secret Access Keyをチャット・GitHub・コードへ貼らない。
- R2 S3 API用のAccess Key/Secretは、必要になった時点で対象バケットに限定した権限で作成する。
- Worker Secrets/Environment Variablesに登録した値をGitへコミットしない。
- `workers.dev` は初期テスト用。長期運用では独自ドメインのCustom Domainを検討する。
- 本番の独自ドメイン設定は、現在のDNS/ネームサーバー構成を確認してから行う。既存サイトのDNSを不用意に変更しない。
