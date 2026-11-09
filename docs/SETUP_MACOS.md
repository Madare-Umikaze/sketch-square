# macOS ローカル開発環境の準備

この手順はローカルPoC用です。Cloudflare/Vercelへのデプロイはまだ行いません。

## 1. 必要なもの

- macOS
- Processing 4.5.7
- JDK 17（Temurin 17等）
- Node.js LTS / npm
- Git（任意だが推奨）

Processing公式ダウンロード: https://processing.org/download/

## 2. JDK 17の確認

ターミナルで実行:

```bash
java -version
javac -version
jar --version
```

JDKが17でない場合は、JDK 17をインストールし、ターミナルで次を設定します。

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export PATH="$JAVA_HOME/bin:$PATH"
```

`java -version` と `javac -version` が17系であることを確認します。

## 3. Processing 4.5.7のインストール

公式サイトからProcessing 4.5.7をインストールします。最初にPDEを一度起動し、初期設定を完了してください。

## 4. processing-java CLIを有効化

Processingのメニューに `Tools > Install "processing-java"` が表示される環境では、それを実行します。インストール先に `~/bin/processing-java` が作成される構成があります。

ターミナルで確認:

```bash
which processing-java
processing-java --help
```

`--build`、`--sketch`、`--output` がヘルプに表示されることを確認してください。

PATHに見つからない場合、Processingアプリ内のCLI実行ファイルを探して、`PROCESSING_JAVA` に絶対パスを指定します。

## 5. Processing Core JARを探す

Processing 4.5.7のアプリ内にあるCore JARを探します。

```bash
find /Applications/Processing.app -name 'core.jar' -o -name 'core-*.jar' 2>/dev/null
```

見つかった正しいCore JARの絶対パスを環境変数へ指定します。例のパスを決め打ちせず、実際に見つかったものを使用してください。

```bash
export PROCESSING_CORE_JAR="/実際に見つかったパス/core.jar"
```

`processing-java` CLIがProcessing本体の別の場所にインストールされている場合は、そのインストール先も確認してください。

## 6. PoCをビルド

プロジェクトルートで:

```bash
npm run build:demo
```

スクリプトは次の環境変数を使います。

- `PROCESSING_JAVA`: `processing-java` 実行ファイルのパス（PATHにあれば省略可能）
- `PROCESSING_CORE_JAR`: Processing Core JARのパス（必須）

成功すると次が生成されます。

```text
public/lib/processing-core.jar
public/works/demo/v1/ProcessingSmokeTest.jar
```

ビルドスクリプトが生成クラスを見つけられない場合は、Processing CLIの実際の出力構造を確認し、エラーログを保存してください。雛形のスクリプトは出力形式を推測しているため、最初のCLI実行時に調整が必要になる可能性があります。

## 7. HTTP Rangeに対応したHTTPサーバーで実行

CheerpJ公式は `npx serve` と `npx http-server` をローカル検証用として案内しています。

```bash
npm run serve
```

ブラウザで http://localhost:4173 を開きます。

Pythonの `python3 -m http.server` はCheerpJのJAR取得に必要なHTTP Rangeに対応しないため使わないでください。`file://` で開くこともできません。

## 8. HTTP Rangeを確認する

別ターミナルで:

```bash
curl -i -H 'Range: bytes=0-0' http://localhost:4173/lib/processing-core.jar
```

`206 Partial Content` と `Content-Range` が返ることを確認します。サーバーやバージョンによってヘッダー表現は異なりますが、Rangeに応じた部分応答が必要です。

## 9. ブラウザでの確認

最初はChromeまたはEdgeのデスクトップ版で確認し、その後Safariでもテストします。

- DevTools Consoleのエラー全文
- NetworkタブのJARと画像のHTTPステータス
- `ProcessingSmokeTest.jar` と `processing-core.jar` が取得できているか
- `data/sample.png` が取得できているか
- AWT displayが生成されるか

エラーが出たら、Consoleの最初の例外から末尾まで、Networkの失敗URL/ステータス、実行したコマンドを記録してください。
