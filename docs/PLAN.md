# 開発計画

## Phase 0 — 設計とリスクの固定（完了）

- Java ModeのPDEを対象とする。
- Processing 4.5.7 / Java 17 / CheerpJ 5.0 / JAVA2Dに初期対象を固定。
- Vercel / Supabase / R2の責務を分離。
- ローカルHTTP配信で最初の互換性検証を行う。

## Phase 1 — ローカルPoC（次に実施）

### 実装

- `processing-java --build` によるコンパイル。
- 生成クラスをJAR化。
- Processing Core JARを独立依存として配置。
- CheerpJ 5.0をページへ読み込む。
- Java 17を指定して初期化する。
- `cheerpjCreateDisplay()` で表示領域を確保。
- `cheerpjRunMain()` でPDE生成クラスを起動する。
- `data/` の画像をHTTP経由で読み込む。

### 完了条件

- 生成クラスがCheerpJのJVM上でロードされる。
- Processingのウィンドウ/Surfaceがページ内に表示される。
- 連続描画（draw）が動作する。
- JAVA2Dで図形・文字・画像を描画できる。
- マウスとキー入力が届く。
- `data/` からPNG画像をロードできる。
- 起動/失敗時のログがブラウザConsoleと画面に表示される。

### 停止条件

AWT SurfaceまたはJava2Dの根本的な互換性障害が出た場合、サイト全体を作り込まずPoCで停止し、代替案（独自Surfaceアダプタ、p5.js投稿形式、サーバー実行）を評価する。

## Phase 2 — R2配信PoC

- Cloudflareに非公開R2バケットを作成。
- Worker Static Assetsでプレイヤーを配信し、最初は `workers.dev` を使用。
- WorkerにR2 binding `WORKS_BUCKET` を追加。
- `run_worker_first: ["/works/*"]` で同一オリジン `/works/*` をWorkerへ渡し、R2から配信。
- HTTP Range、HEAD、Content-Type、ETag、Cache-Controlを検証。
- JAR/素材をR2からCheerpJ `/app/works/...` として読めるようにする。
- 作品オブジェクトは公開領域と非公開領域を分離する。

## Phase 3 — コンパイルワーカー

- Processing 4.5.7 / JDK 17を固定した隔離ビルド環境を用意。
- ZIPのサイズ、展開後サイズ、ファイル数、階層、パスを検証。
- `processing-java --build` を実行。
- クラス/JAR/素材をバージョン付きprefixでR2へ配置。
- CPU/メモリ/実行時間/同時実行数を制限。
- 投稿時のソース原本を保持。

## Phase 4 — Webアプリ

- Vercel + Next.js等でサイトUI/API。
- Supabase AuthとPostgreSQLでユーザー/作品メタデータ。
- Supabase RLSを有効化。
- 大きなZIPはVercel Functionを経由させず、短命のpresigned PUT URLなどでR2へ直接アップロード。
- 公開作品の一覧、詳細、作品ページ、通報/削除フローを実装。

## Phase 5 — 安全性・運用

- 実行用オリジンをサイト本体から分離。
- iframe sandbox、CSP、Permissions Policyを検討・検証。
- ログインcookie、管理API、Supabase secretを実行環境へ渡さない。
- CPU/メモリ/実行時間とブラウザ停止時の復旧UXを設計。
- ZIP Slip、ZIP bomb、悪意あるビルドスクリプト/依存JARへの防御。
- Abuse対策、削除、著作権申立て、利用規約を整備。

## Phase 6 — 投稿形式拡張

- p5.jsは別投稿形式として追加（Java版の自動変換は前提にしない）。
- P2D/P3D、追加Javaライブラリは個別互換性評価。
- Unity WebGLは独立したランタイム種別として将来追加。

## 運用上の原則

- 作品の原本ZIPを必ず保持する。
- Processing / Java / CheerpJのバージョンを作品ビルド単位で記録する。
- コンパイル済み成果物は再生成できるものとして扱う。
- 初期版の対応範囲を明示し、対応外のライブラリやレンダラーはビルド時に拒否または警告する。
