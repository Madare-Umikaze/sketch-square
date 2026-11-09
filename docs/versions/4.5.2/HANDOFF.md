# HANDOFF — Processing Web Runtime PoC

最終更新: 2026-11-10  
プロジェクト: `processing-web-runtime-poc`  
目的: Processing Java Mode の作品をブラウザ内で実行するランタイムの技術検証

---

## 1. このプロジェクトの目的

UnityRoomのように、ユーザーが制作した作品を投稿・閲覧できるWebサービスを目指す。最初の実行形式は Processing 4 の Java Mode（PDE）とし、ブラウザ内のJava実行環境としてCheerpJを利用する。

現段階はサービス本体ではなく、Processing作品をブラウザで実行できるかを検証するPoCである。

### 当面の対象

- Processing 4.5.2
- Java Mode
- JAVA2D renderer
- `.pde` のProcessing CLIビルド
- 生成されたJava bytecode/JARをCheerpJ 5.0でブラウザ実行
- スケッチの `data/` ディレクトリに含まれる画像などの静的データ

### 現段階で対象外・未検証

- P2D / P3D
- JOGL / OpenGLに依存する機能
- Processingの全外部ライブラリとの互換性
- ユーザー投稿を受け付ける本番用バックエンド
- 長時間実行時の安定性・性能・メモリ上限
- スケッチの安全な隔離・リソース制限

p5.jsとUnity WebGLは、将来的にそれぞれ別の投稿形式・ランタイムとして扱う構想。Processing Java Mode作品を自動的にp5.jsへ変換する方針ではない。

---

## 2. 検証環境

| 項目 | 実測・使用値 |
|---|---|
| 開発端末 | macOS / Apple Silicon |
| CPUアーキテクチャ | `arm64` |
| Processing | 4.5.2 (Java Mode) |
| Processingリリースコミット | `c5fec05` |
| JDK | Eclipse Temurin 17.0.21 |
| `javac` | 17.0.21 |
| CheerpJ | 5.0 |
| ブラウザ | Chrome（ローカルPoCで確認） |
| ローカル開発サーバー | `localhost:4173` |
| Core JAR | `/Applications/Processing.app/Contents/app/resources/modes/java/mode/core-4.5.2.jar` |
| プロジェクトディレクトリ | `/Users/madare/downloads/processing-web-runtime-poc` |

Processing 4.5.2のリリースページは次のとおり。リリース情報にコミット `c5fec05` が記載されている。

- https://github.com/processing/processing4/releases
- 固定コミットの `PSurfaceAWT.java`: https://raw.githubusercontent.com/processing/processing4/c5fec05/core/src/processing/awt/PSurfaceAWT.java

> 注意: 上記の絶対パスは開発者の現在のMac環境に依存する。別の端末ではProcessing.appの場所とCore JARのパスを再確認すること。

---

## 3. 全体構成

### 実行フロー

```text
ProcessingSmokeTest.pde
        │
        ▼
processing-java --build
        │
        ▼
ProcessingSmokeTest.class
        │
        ▼
ProcessingSmokeTest.jar
        │
        ├── data/sample.png
        │
        ▼
Browser / CheerpJ 5.0
        │
        ├── ProcessingWebLauncher.jar
        ├── processing-awt-patch.jar
        ├── ProcessingSmokeTest.jar
        └── processing-core.jar
                 │
                 ▼
        ProcessingWebLauncher.main()
                 │
                 ▼
        PApplet.main(--sketch-path, class name)
                 │
                 ▼
        PApplet / PGraphicsJava2D
                 │
                 ▼
        PSurfaceAWT (CheerpJ向け差し替え)
                 │
                 ▼
        SmoothCanvas.paint(Graphics)
                 │
                 ▼
        CheerpJ AWT window / browser
```

### 重要な設計判断

Processing標準の `PSurfaceAWT` は `BufferStrategy` を用いて描画内容を画面に転送する。しかし今回のCheerpJ 5.0上の検証では、`BufferStrategy.getDrawGraphics()` で `NullPointerException` が発生した。

そのため、Processingの描画APIや `PGraphicsJava2D` は維持し、画面への転送部分のみを変更する方針を採用した。

---

## 4. 確認された主要な技術的問題と解決

### 4.1 JARとHTTP配信

CheerpJは次のJARをHTTP経由で取得した。ローカルサーバーログではJAR要求に `206 Partial Content` が返っており、Rangeリクエストを利用した取得が行われたことを確認している。

```text
/works/demo/v1/ProcessingSmokeTest.jar
/lib/processing-core.jar
```

### 4.2 スケッチのdataパス

当初、`loadImage("sample.png")` が `/data/sample.png` や `/sample.png` を要求して404になった。

原因の一つは、Processing起動オプション `--sketch-path` がクラス名の後ろに渡され、`PApplet.main()` の起動オプションとして解釈されない引数順序になっていたこと。

Processingのコマンドライン形式は概ね次の順序。

```text
PApplet [options] <class name> [sketch args]
```

そのため専用ランチャー `ProcessingWebLauncher` を導入し、JavaScriptから渡されたスケッチパスを、ランチャー内部でクラス名より前に指定するようにした。

### 4.3 CheerpJ上のBufferStrategyの問題

AWT単体テストで以下を確認した。

| 描画方式 | 結果 |
|---|---|
| `Canvas.paint(Graphics)` から直接描画 | 成功 |
| `BufferedImage` の生成・描画 | 成功 |
| `BufferStrategy.getDrawGraphics()` | `NullPointerException` |
| `BufferStrategy.show()` 経由の表示 | 成功せず |

この結果から、AWTウィンドウと通常のCanvas描画は使える一方、BufferStrategyを使った描画経路に互換性上の問題があると判断した。

### 4.4 Processing PSurfaceAWTの差し替え

Processing 4.5.2の `processing.awt.PSurfaceAWT` をソースからコンパイルし、次の変更を行った。

#### `SmoothCanvas.paint(Graphics screen)`

変更後:

```java
@Override
public void paint(Graphics screen) {
    if (canvas.isDisplayable() && graphics.image != null) {
        screen.drawImage(
            graphics.image,
            0,
            0,
            sketchWidth,
            sketchHeight,
            null
        );
    }
}
```

#### `protected void render()`

変更後:

```java
protected void render() {
    if (canvas.isDisplayable() && graphics.image != null) {
        canvas.repaint();
    }
}
```

これにより、BufferStrategyによる画面転送をやめ、Processingが生成した `graphics.image` を通常のAWT `Canvas.paint(Graphics)` から直接表示する。

この方式で、デモの背景・図形・文字・アニメーションが表示され、マウスクリックと `frameCount` も正常に動くことを確認した。

> 注意: この変更はPoCで動作確認した試験的な差し替えであり、Processing全機能との完全互換を意味しない。リサイズ、描画中断・復帰、複数ウィンドウ、長時間運転などはPhase 3で検証する。

---

## 5. 現在の重要ファイル

```text
processing-web-runtime-poc/
├── docs/
│   ├── HANDOFF.md
│   ├── CURRENT_STATUS.md
│   └── PHASE3_PLAN.md
├── examples/
│   ├── ProcessingSmokeTest/
│   │   ├── ProcessingSmokeTest.pde
│   │   └── data/
│   │       └── sample.png
│   ├── AwtRenderTest/
│   │   └── AwtRenderTest.java       # AWT切り分け用テスト
│   └── ProcessingWebLauncher.java
├── scripts/
│   ├── build-sketch.sh
│   └── build-processing-awt-patch.sh  # Phase 3で追加する再現ビルド用
├── public/
│   ├── index.html
│   ├── styles.css
│   ├── js/
│   │   └── runner.js
│   ├── ProcessingWebLauncher.jar
│   ├── lib/
│   │   ├── processing-core.jar
│   │   └── processing-awt-patch.jar
│   └── works/demo/v1/
│       ├── ProcessingSmokeTest.jar
│       └── data/sample.png
└── .build/
    ├── ProcessingWebLauncher/
    ├── ProcessingSmokeTest/
    ├── patch-src/processing/awt/PSurfaceAWT.java
    └── processing-awt-patch/
```

> このツリーは、会話で確認できた構成をもとにした代表的な一覧。`.gitignore` やその他の既存ファイルは省略している。`AwtRenderTest` は切り分け用であり、本番ランタイムの構成要素ではない。

---

## 6. ビルドと実行

### 6.1 Processingスケッチのビルド

プロジェクトルートで実行。

```bash
PROCESSING_CORE_JAR="/Applications/Processing.app/Contents/app/resources/modes/java/mode/core-4.5.2.jar" \
./scripts/build-sketch.sh
```

スクリプトはProcessing CLIを利用して `.pde` をJavaクラスへ変換・コンパイルし、スケッチJAR、Core JAR、`data/` を `public/` 以下に配置する。

### 6.2 ProcessingWebLauncherのビルド

```bash
mkdir -p .build/ProcessingWebLauncher

PROCESSING_CORE_JAR="/Applications/Processing.app/Contents/app/resources/modes/java/mode/core-4.5.2.jar"

javac --release 17 \
  -cp "$PROCESSING_CORE_JAR" \
  -d .build/ProcessingWebLauncher \
  examples/ProcessingWebLauncher.java

jar --create \
  --file public/ProcessingWebLauncher.jar \
  -C .build/ProcessingWebLauncher .
```

### 6.3 AWTパッチJARの手動ビルド（現状）

現時点で成功確認済みの手順。

```bash
mkdir -p .build/patch-src/processing/awt
mkdir -p .build/processing-awt-patch

curl -fL \
  "https://raw.githubusercontent.com/processing/processing4/c5fec05/core/src/processing/awt/PSurfaceAWT.java" \
  -o .build/patch-src/processing/awt/PSurfaceAWT.java
```

取得した `PSurfaceAWT.java` に本書4.4節の2か所の変更を加えた後、次を実行する。

```bash
PROCESSING_CORE_JAR="/Applications/Processing.app/Contents/app/resources/modes/java/mode/core-4.5.2.jar"

javac --release 17 \
  -cp "$PROCESSING_CORE_JAR" \
  -d .build/processing-awt-patch \
  .build/patch-src/processing/awt/PSurfaceAWT.java

jar --create \
  --file public/lib/processing-awt-patch.jar \
  -C .build/processing-awt-patch processing/awt
```

生成された内部クラスを含め、`processing/awt/PSurfaceAWT*.class` がJARに入っていることを確認する。

```bash
jar tf public/lib/processing-awt-patch.jar
```

> Phase 3の最初の作業は、この手動作業をバージョン固定された再現可能なスクリプトへ置き換えること。

### 6.4 runner.jsの重要設定

現在の検証で成功した設定の要点は次のとおり。

```js
const SKETCH_CLASS = "ProcessingWebLauncher";

const SKETCH_CLASSPATH = [
  "/app/lib/processing-awt-patch.jar",
  "/app/ProcessingWebLauncher.jar",
  "/app/works/demo/v1/ProcessingSmokeTest.jar",
  "/app/lib/processing-core.jar"
].join(":");

const SKETCH_PATH = "/app/works/demo/v1";

const exitCode = await window.cheerpjRunMain(
  SKETCH_CLASS,
  SKETCH_CLASSPATH,
  SKETCH_PATH
);
```

**クラスパス順序は重要。** 差し替えクラスを含む `processing-awt-patch.jar` を先頭に配置する。Processing Core JARは最後に配置する。

JavaScriptから渡す第3引数はスケッチパス文字列。`ProcessingWebLauncher.main(String[] args)` が受け取り、次の形で `PApplet.main()` を呼び出す。

```java
import processing.core.PApplet;

public final class ProcessingWebLauncher {
    public static void main(String[] args) {
        String sketchPath = args.length > 0
            ? args[0]
            : "/app/works/demo/v1";

        PApplet.main(new String[] {
            "--sketch-path=" + sketchPath,
            "ProcessingSmokeTest"
        });
    }
}
```

### 6.5 実行

```bash
npm run serve
```

表示されたローカルURLをブラウザで開き、実行ボタンを押す。CheerpJ loaderのロード、JAR取得、スケッチの描画を確認する。

---

## 7. 実証済みの機能

最終確認時点で、以下の全項目が成功。

- [x] ProcessingのJava ModeスケッチをProcessing CLIでビルド
- [x] CheerpJ 5.0でJava 17のクラスをロード・実行
- [x] ProcessingのAWTウィンドウを生成
- [x] `setup()` を実行
- [x] `draw()` を継続実行
- [x] 暗色の背景を表示
- [x] `ellipse()`、`rect()`、`triangle()` などの図形描画
- [x] `text()` による文字描画
- [x] `frameCount` の増加
- [x] `mousePressed()` によるクリックカウント
- [x] `loadImage("sample.png")` によるdata画像の読み込みと表示
- [x] ブラウザConsole上の該当画像404が解消

---

## 8. 注意点・既知の制約

1. `processing-awt-patch.jar` はProcessing 4.5.2に対するバイナリ差し替え。別バージョンへ流用しない。
2. クラスパスでパッチJARを先頭に置く。
3. パッチは `BufferStrategy` を使わず `repaint()` / `Canvas.paint()` で表示する。描画更新とAWT Event Dispatch Threadの相互作用は引き続き検証する。
4. 現在のPoCは単一スケッチ・単一実行を中心にした構成。停止・再起動はページリロードに依存している。
5. `/app/` はCheerpJからHTTP配信される読み取り用アセット領域として扱う。ユーザー作品の書き込み先、永続保存先の仕様は未決定。
6. ユーザーが投稿するコードは信頼できないコードとして扱う。本番化ではプレイヤーを独立オリジンに置くこと、認証Cookieや秘密情報を渡さないこと、ネットワーク・CPU・メモリ・ファイルアクセスなどの制限が必要。
7. P2D/P3D、JNI、ネイティブライブラリ、外部ライブラリは未検証。

---

## 9. 参考資料

- Processing 4.5.2 release / commit `c5fec05`: https://github.com/processing/processing4/releases
- Processing 4.5.2 `PSurfaceAWT.java`: https://raw.githubusercontent.com/processing/processing4/c5fec05/core/src/processing/awt/PSurfaceAWT.java
- Processing `PApplet` Javadoc (`main()` と `--sketch-path`): https://processing.github.io/processing4-javadocs/processing/core/PApplet.html
- CheerpJ 5.0 release overview: https://labs.leaningtech.com/blog/cheerpj-5.0
- CheerpJ documentation: https://cheerpj.com/docs/

---

## 10. Phase 3の最初の作業

現在動作確認済みの修正済みソースをプロジェクト内に固定する。

```bash
mkdir -p patches/processing-4.5.2/processing/awt
cp .build/patch-src/processing/awt/PSurfaceAWT.java \
  patches/processing-4.5.2/processing/awt/PSurfaceAWT.java
```

`scripts/build-processing-awt-patch.sh`をプロジェクトの `scripts/` に配置し、次を実行する。

```bash
PROCESSING_CORE_JAR="/Applications/Processing.app/Contents/app/resources/modes/java/mode/core-4.5.2.jar" \
./scripts/build-processing-awt-patch.sh
```

このビルドスクリプトは今回のドキュメントパックに含まれる。まだ実プロジェクト上での実行確認前なので、生成JARをブラウザで再検証すること。

## 11. 次に着手すること

Phase 3は [PHASE3_PLAN.md](./PHASE3_PLAN.md) の順番で進める。最初にパッチの出所・差分・ビルド手順を固定し、同じ環境で何度でも再生成できるようにする。その後、表示ライフサイクルとProcessing API互換性を検証する。
