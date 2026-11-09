# BUILD_MATRIX — Processing toolchain profiles

最終更新: 2026-11-10

## 目的

ProcessingのCLI名・Core JAR・パッチを分離し、バージョン取り違えを防ぐ。投稿作品ごとに固定されたビルドプロファイルを使用する。

| Profile | CLI | Core | AWT patch | Java major | 状態 |
|---|---|---|---|---:|---|
| `processing-4.5.2` | macOSでは旧 `processing-java` 導線 | `core-4.5.2.jar` | `processing-awt-patch.jar` | 17 | PoC動作実証済み・旧基準 |
| `processing-4.5.7` | アプリ内 `Processing cli` を専用wrapperで呼ぶ | `core-4.5.7.jar` | `processing-awt-patch-4.5.7.jar` | 17 | 現行標準・PoC動作実証済み |
| `processing-3.5.4` | 未実装 | 3.5.4 Core | 未実装 | 8想定 | 初期対象外 |

## 4.5.2 profile

- CLI: 現行Macの `/usr/local/bin/processing-java` は `/Applications/Processing.app/Contents/MacOS/Processing cli $@` のラッパーとして確認済み。
- Core: `/Applications/Processing.app/Contents/app/resources/modes/java/mode/core-4.5.2.jar`
- Upstream commit: `c5fec05`
- Patch output: `public/lib/processing-awt-patch.jar`
- Sketch output: `public/works/demo/v1/`

## 4.5.7 profile

- App: `$HOME/Applications/Processing-4.5.7/Processing.app`
- Core想定: `Contents/app/resources/modes/java/mode/core-4.5.7.jar`（実際の配置は `find` で確認）
- Upstream commit: `ca3999a`
- CLI wrapper: `scripts/bin/processing-4.5.7`
- Patch output: `public/lib/processing-awt-patch-4.5.7.jar`
- Core output: `public/lib/processing-core-4.5.7.jar`
- Sketch output: `public/works/demo/v4.5.7/`
- Launcher output: `public/ProcessingWebLauncher-4.5.7.jar`

## CLI変更の意味

Processing 4.5.3のリリースノートは、macOSのCLIインストールスクリプトが `processing-java` ではなく `processing` を作成するよう変更されたと説明している。これはビルドアダプターで吸収すべきホスト側CLI登録の差であり、PDE投稿形式を分ける根拠ではない。

## 運用ルール

1. `processingVersion` を曖昧な `4.x` でなく、完全なバージョン文字列で記録する。
2. Processing Coreとpatch JARは同じバージョンから生成する。
3. patch JARをCore JARよりクラスパスの前に置く。
4. ProcessingWebLauncherは対象Core JARに対して再コンパイルする。
5. CLIラッパーは固定アプリパスを使い、グローバルPATHに依存しない。
6. 出力先をバージョン別にし、旧バージョンの生成物を上書きしない。
7. ビルド結果にCore/patch/元ZIPのSHA-256を保存する。
