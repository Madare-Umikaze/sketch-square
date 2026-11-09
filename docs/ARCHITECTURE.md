# アーキテクチャ設計

## 1. 概要

最初の検証では、ローカルの静的HTTPサーバーが `/`、`/lib/`、`/works/` を同一オリジンから配信する。CheerpJはページ内で初期化され、JARと素材を `/app/` 仮想ファイルシステムから取得する。

```text
Browser
  ├── index.html / js/runner.js
  ├── CheerpJ 5.0 loader (CDN)
  └── CheerpJ Runtime (WebAssembly + JavaScript)
        ├── /app/lib/processing-core.jar
        ├── /app/works/demo/v1/ProcessingSmokeTest.jar
        └── /app/works/demo/v1/data/sample.png
```

## 2. 実行時の責務

### ブラウザ

- CheerpJ loaderの取得とJVM初期化。
- AWTウィンドウ/Surfaceを表示するdisplay hostの提供。
- Javaクラスのロードと実行。
- 画像等の素材をHTTP Range/HTTP GETで取得。
- ユーザーのマウス・キーボード入力をブラウザ経由で処理。

### コンパイル環境

- Processing CLIでPDEプリプロセスとJavaコンパイル。
- コンパイル済みクラスのJAR化。
- Processing Coreと追加依存の管理。
- 原本の `data/` ディレクトリはJARへ無理に埋め込まず、スケッチ相対パスに置く。

## 3. クラスパスと起動

想定クラスパス:

```text
/app/works/demo/v1/ProcessingSmokeTest.jar
/app/lib/processing-core.jar
```

想定起動:

```js
await cheerpjInit({ version: 17 });
cheerpjCreateDisplay(-1, -1, displayHost);
await cheerpjRunMain(
  "ProcessingSmokeTest",
  "/app/works/demo/v1/ProcessingSmokeTest.jar:/app/lib/processing-core.jar",
  "--sketch=/app/works/demo/v1"
);
```

これはPoCの初期仮説である。PDE生成クラスの完全修飾名、Processingの引数処理、CheerpJ `/app/` 上のsketchPathが動くかは実測する。

## 4. 素材ファイル

元のスケッチ構成:

```text
ProcessingSmokeTest/
├── ProcessingSmokeTest.pde
└── data/
    └── sample.png
```

Web配信先:

```text
public/works/demo/
├── ProcessingSmokeTest.jar
└── data/
    └── sample.png
```

PDEの `loadImage("sample.png")` は通常スケッチの `data/` を参照する。実行時にProcessingへ `--sketch=/app/works/demo/v1` を渡し、`/app/works/demo/v1/data/sample.png` を参照できるかを確認する。

CheerpJの `/app/` は配信元ルートに対応する読み取り専用HTTPベースの仮想FS。書き込みには使わない。Java側の永続領域は `/files/` だが、Processingの保存処理がそのまま期待どおりに働くかは別途検証する。

## 5. 本番構成（Phase 2以降）

```text
www.example.com (Vercel)
  ├── Next.js UI / API
  └── Supabase Auth + Postgres (作品メタデータ)

<worker-name>.<account-subdomain>.workers.dev (Cloudflare Worker)
  ├── Static Assets: player page / CheerpJ loader caller
  └── /works/* -- Worker R2 binding --> private R2 bucket

Build worker (隔離コンテナ)
  ├── source ZIP (R2から取得)
  ├── Processing 4.5.7 + JDK 17
  ├── processing-java --build
  └── compiled JAR + assets --> R2
```

初期の本番前テストは `workers.dev` を使い、Cloudflare WorkerのStatic AssetsでプレイヤーHTML/CSS/JSを配信し、同じWorkerが `/works/*` をR2 bindingから返す。CheerpJからは同一オリジンの `/app/works/...` として読める。Vercelのメインサイトとは別オリジンなので、作品プレイヤーをiframeに隔離しやすく、独自ドメインやDNS変更も初期段階では不要。

後で独自ドメインを持ち、Cloudflare DNSを利用する段階になれば `play.example.com` をWorkerのCustom Domainにする。Vercel側はiframe URLを `workers.dev` から独自ドメインに差し替えるだけにする。

## 6. R2の保存設計

```text
private bucket: processing-works
  ├── source/{userId}/{workId}/{version}/source.zip
  ├── build/{workId}/{version}/sketch.jar
  ├── build/{workId}/{version}/manifest.json
  └── build/{workId}/{version}/data/**
```

- バケットは初期状態で非公開。
- ブラウザからR2 APIを直接操作しない。
- Worker bindingまたはサーバー側署名済みURLで権限を限定。
- 公開ページは公開ステータスが確認された `published/{workId}/{version}/...` prefixだけを配信。
- WorkerのR2 bindingはGET/HEAD専用で、公開prefix以外を返さない。
- R2オブジェクト配信はRange、Content-Type、ETag、Cache-Controlを扱う。
- Worker Static Assetsでプレイヤーと `/works/*` を同一オリジンに置くため、ブラウザからR2へのCORS設定は原則不要。

## 7. Supabaseデータモデル案

初期の作品メタデータ案:

- `works`: `id`, `owner_id`, `title`, `description`, `visibility`, `runtime`, `created_at`, `published_at`
- `work_versions`: `id`, `work_id`, `processing_version`, `java_version`, `cheerpj_version`, `renderer`, `build_status`, `source_object_key`, `artifact_prefix`, `created_at`

RLSで所有者だけが下書き/編集/削除できるようにする。公開作品の閲覧は公開状態の行だけ許可する。

## 8. アップロード

Vercel Functionsのリクエストボディには4.5MB制限があるため、大きなZIPをVercel APIに直接POSTする構成は避ける。認証と権限確認後、短命のpresigned PUT URLを発行してブラウザからR2へ直接アップロードする案を採用する。presigned URLはBearer tokenとして扱い、短い有効期限・単一オブジェクト・単一HTTPメソッドに制限する。

## 9. セキュリティ

- `workers.dev` または `play` と `www` を別オリジンにする。
- 実行用ページにSupabase service role keyや管理APIトークンを含めない。
- 公開作品と未公開/原本を異なるobject prefixに分ける。
- コンパイルは信頼しないZIPを隔離コンテナで処理する。
- ZIP展開前にパストラバーサル、展開後サイズ、ファイル数、階層深度を制限する。
- ブラウザ実行はユーザー端末のCPU/メモリを消費する。iframeの破棄で実行画面を終了できるUIを用意する。
- CSPとPermissions Policyを段階的に強化し、必要な機能をテストする。

## 10. スコープ外

- 初期PoCではP2D/P3D、JOGL、JNI、ネイティブDLL/SO/dylib、Serial、フルスクリーン、任意ファイル保存、任意ネットワークアクセスを保証しない。
- Unity WebGLとp5.js投稿は別ランタイムとして将来追加。
