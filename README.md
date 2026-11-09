# Processing Web Runtime PoC

Java Mode の Processing 4 スケッチを、CheerpJ 5.0（Java 17）でブラウザ実行するための技術検証用プロジェクトです。

> **現状**: 初期設計・PoC用コードの雛形。Processing CLIでのビルドとCheerpJ実ブラウザ実行は、Processingをインストールした開発マシンでこれから検証します。動作確認済みとは扱わないでください。

## 最初に読む資料

1. [`docs/HANDOFF.md`](docs/HANDOFF.md) — 次のチャット/LLMへ引き継ぐための要約
2. [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — システム設計
3. [`docs/PLAN.md`](docs/PLAN.md) — 開発段階と完了条件
4. [`docs/SETUP_MACOS.md`](docs/SETUP_MACOS.md) — Macでのローカル準備
5. [`docs/CLOUDFLARE_SETUP.md`](docs/CLOUDFLARE_SETUP.md) — Cloudflare/R2の初期準備
6. [`docs/TEST_PLAN.md`](docs/TEST_PLAN.md) — 互換性検証

## PoCの目的

- Processing 4 Java Mode の `.pde` を公式 `processing-java --build` でコンパイルする。
- コンパイルしたクラスと Processing Core をJARとしてHTTP配信する。
- CheerpJ 5.0をJava 17で初期化し、Processingスケッチの `main()` を実行する。
- CheerpJの `/app/` 仮想ファイルシステムから `data/` 内の画像を読む。
- JAVA2D、描画ループ、マウス入力、キー入力の可否を確認する。

## セットアップ概要

1. macOSにJDK 17とProcessing 4.5.7をインストールする。
2. Processingのメニューから `processing-java` CLIをインストールし、PATHを通す。
3. Processing Core JARの場所を確認する。
4. `scripts/build-sketch.sh` でデモスケッチをコンパイルする。
5. `public/lib/processing-core.jar` と `public/works/demo/v1/ProcessingSmokeTest.jar` を配置する。
6. `npx serve public --listen 4173` で配信し、`http://localhost:4173` を開く。

詳細は `docs/SETUP_MACOS.md` を参照。

## 注意

- CheerpJのJAR配信はHTTP Range Requestsに対応したサーバーが必要です。Python標準の `http.server` は使わず、`npx serve` または `npx http-server` を使用してください。
- `file://` で直接HTMLを開かないでください。
- `public/lib/processing-core.jar` と生成JARはビルド成果物です。このリポジトリにはProcessing本体やCheerpJランタイムを同梱しません。
- CheerpJの標準AWT対応は、Processingの `PSurfaceAWT` と `PGraphicsJava2D` が完全動作する保証ではありません。実機検証が必要です。
- 初期PoCの対象はJAVA2Dのみです。P2D/P3D、JNIを使うライブラリ、OS固有機能は対象外です。
