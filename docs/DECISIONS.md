# Architecture Decision Records

## ADR-001: Java Modeをp5.jsへ一括自動変換しない

状態: 採用

理由: Java言語機能、Javaライブラリ、ファイルパス、素材読込の意味を完全に保った自動変換は現実的でない。p5.jsは独立した投稿形式として扱う。

## ADR-002: Java版の初期実行方式にCheerpJを採用して検証

状態: 検証中

理由: JavaバイトコードをJVMで実行し、Java 17、AWT、Java2Dのベース機能を利用できる。ProcessingのPSurfaceAWTまで含む互換性は未確認であるため、PoCを先行させる。

## ADR-003: 初期Processingバージョンを4.5.7に固定

状態: 採用（PoC用）

理由: 2026-11-08時点の公式Stable Release。再現性のためバージョンを固定する。

## ADR-004: 初期レンダラーはJAVA2Dに限定

状態: 採用

理由: ProcessingのP2D/P3DはOpenGL/JOGL等の追加要件を含む。初期PoCではAWT/Java2Dに集中する。

## ADR-005: 素材をJARへ強制的に埋め込まない

状態: 採用

理由: Processingの `data/` 構造を保ち、CheerpJ `/app/` からHTTPで取得する。原本と実行成果物のフォルダ構成を対応させやすい。

## ADR-006: ローカルPoC成立後にCloudflare R2を統合

状態: 採用

理由: R2配信障害とJava/Processing互換性障害を同時に調べると切り分けが困難。まずRange対応ローカルHTTPサーバーで成立性を確認する。

## ADR-007: R2を初期状態で非公開にする

状態: 採用

理由: 作品の公開可否をアプリケーション側で管理し、未公開ソースやビルド途中の成果物を不用意に公開しない。
