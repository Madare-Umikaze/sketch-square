# HANDOFF — Processing 4.5.7 Runtime

最終更新: 2026-11-10
状態: **CheerpJ 5.0上でProcessing JAVA2D Smoke Testが全項目成功。**

## 固定情報

- Processing 4.5.7
- Upstream repository: `https://github.com/processing/processing4`
- Release commit: `ca3999a`（GitHub verified release commit）
- macOS app: `$HOME/Applications/Processing-4.5.7/Processing.app`
- Java: 17（開発端末はTemurin 17.0.21）
- CheerpJ: 5.0 (`cheerpjInit({ version: 17 })`)
- Renderer: JAVA2D

## ビルド入力

- Sketch source: `examples/ProcessingSmokeTest/ProcessingSmokeTest.pde`
- Sketch data: `examples/ProcessingSmokeTest/data/`
- Launcher source: `examples/ProcessingWebLauncher.java`
- Patched source: `patches/processing-4.5.7/processing/awt/PSurfaceAWT.java`
- Core source/JAR: Processing 4.5.7 Java Mode distribution

## 出力パス

```text
public/ProcessingWebLauncher-4.5.7.jar
public/lib/processing-awt-patch-4.5.7.jar
public/lib/processing-core-4.5.7.jar
public/works/demo/v4.5.7/ProcessingSmokeTest.jar
public/works/demo/v4.5.7/data/sample.png
```

## CLI

4.5.3以降のmacOS CLI install scriptは `processing-java` ではなく `processing` を作る変更がリリースノートに記録される。4.5.7 wrapperはProcessingアプリ内CLIを呼び出す。グローバル `/usr/local/bin/processing-java` は4.5.2の検証用に残し、変更しない。

## ブラウザ実行

`runner.js` のクラスパス順:

```text
/app/lib/processing-awt-patch-4.5.7.jar
/app/ProcessingWebLauncher-4.5.7.jar
/app/works/demo/v4.5.7/ProcessingSmokeTest.jar
/app/lib/processing-core-4.5.7.jar
```

```js
const exitCode = await window.cheerpjRunMain(
  "ProcessingWebLauncher",
  SKETCH_CLASSPATH,
  "/app/works/demo/v4.5.7"
);
```

`ProcessingWebLauncher` は `PApplet.main()` に `--sketch-path` をクラス名より前に渡す。

## パッチ仕様

4.5.7の `PSurfaceAWT` に対し、`SmoothCanvas.paint(Graphics)` は `graphics.image` を通常のGraphicsで描き、`render()` は `canvas.repaint()` を要求する。BufferStrategyの表示経路を利用しない。

## 実測結果

ユーザーによるブラウザテストで以下すべて正常:

- CheerpJ初期化
- AWTウィンドウ
- Processing起動
- `setup()` / `draw()`
- 背景・図形・文字
- アニメーション
- `frameCount`
- マウスクリックカウント
- `data/sample.png` の読み込み
- Consoleに画像404/Java例外なし

## 未検証

リサイズ、ページ表示/非表示・復帰、最小化、長時間実行、Stop/再起動、API互換性全般、P2D/P3D、外部ライブラリ、他ブラウザ・モバイル。

詳細は [MIGRATION.md](MIGRATION.md) と [CURRENT_STATUS.md](CURRENT_STATUS.md) を参照。
