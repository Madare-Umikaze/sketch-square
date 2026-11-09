# CURRENT_STATUS — Processing Web Runtime PoC

最終更新: 2026-11-10  
状態: **Phase 2相当の基本実証を完了。Phase 3（ランタイム安定化）へ移行可能。**

## 1. 結論

Processing 4.5.2のJava Mode（JAVA2D）スケッチを、CheerpJ 5.0 + Java 17でブラウザ上から実行できることを確認した。

標準 `PSurfaceAWT` の `BufferStrategy` 描画経路がCheerpJ上で `NullPointerException` になる問題に対して、`PSurfaceAWT` の画面転送部分を修正したクラスを別JARとして優先ロードすることで回避した。

**単なるウィンドウ生成ではなく、図形、文字、アニメーション、マウス操作、画像読み込みまで成功している。**

## 2. 環境

- macOS / Apple Silicon (`arm64`)
- Processing 4.5.2
- Processing release commit: `c5fec05`
- Temurin JDK 17.0.21
- CheerpJ 5.0
- Chrome
- ローカル開発URLのポート: `4173`

## 3. 成功した構成

### クラスパス

```text
/app/lib/processing-awt-patch.jar
/app/ProcessingWebLauncher.jar
/app/works/demo/v1/ProcessingSmokeTest.jar
/app/lib/processing-core.jar
```

この順序を維持する。特に `processing-awt-patch.jar` は最初。

### 実行クラス

`ProcessingWebLauncher`

JavaScriptからスケッチパスを引数で受け取り、Processingの起動オプションとしてクラス名より前に `--sketch-path` を渡す。

### 描画パッチ

ファイル: `processing/awt/PSurfaceAWT.java`

`SmoothCanvas.paint(Graphics)` が `graphics.image` を直接描画し、`render()` は `canvas.repaint()` を要求する。標準のBufferStrategy転送処理は使用しない。

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

protected void render() {
    if (canvas.isDisplayable() && graphics.image != null) {
        canvas.repaint();
    }
}
```

## 4. 動作確認結果

| 項目 | 状態 | 備考 |
|---|---|---|
| ページ表示・CheerpJ loader | 成功 | ブラウザから起動 |
| Java 17クラス実行 | 成功 | `ProcessingWebLauncher` |
| Processing AWTウィンドウ | 成功 | ウィンドウ生成 |
| `setup()` | 成功 | 描画ループ初期化 |
| `draw()` | 成功 | 継続描画 |
| 背景色 | 成功 | 最終確認では元の背景色 |
| 図形描画 | 成功 | 円・四角形・三角形 |
| 文字描画 | 成功 | `text()` |
| アニメーション | 成功 | 円の移動等 |
| `frameCount` | 成功 | カウント増加 |
| マウス入力 | 成功 | クリックカウント |
| `data/sample.png` | 成功 | `loadImage()` で表示 |
| 対象画像404 | 解消 | 最終確認時にエラーなし |

## 5. 原因と解決の要約

### 原因調査

- CheerpJでウィンドウタイトルが表示され、`setup()` / `draw()` のタイトル更新も確認できた。
- 通常の `Canvas.paint(Graphics)` でBufferedImageを描画できた。
- BufferStrategyを使うAWTテストでは、`getDrawGraphics()` で `NullPointerException` が発生した。
- Processing標準 `PSurfaceAWT` もBufferStrategy経由で画面転送する。

### 解決

Processing標準Coreをそのまま使うのではなく、同一バージョンの `PSurfaceAWT` を修正して別JARにし、クラスパスの先頭に置いた。

その後、専用ランチャーを導入して `--sketch-path` の引数順序も解決し、`data/sample.png` の読み込みまで成功した。

## 6. まだ未検証のもの

- ウィンドウのリサイズ
- ブラウザタブ非表示・復帰時の描画継続
- ウィンドウ最小化・復帰
- 長時間稼働時の安定性とメモリ使用量
- Stop / 再起動、連続実行時のリソース解放
- `createGraphics()` / オフスクリーン描画
- `pixels[]` / `loadPixels()` / `updatePixels()`
- `PFont` / `createFont()` / 外部フォント
- `saveFrame()` / `saveStrings()` など書き込み
- 外部ライブラリ
- P2D / P3D
- モバイルブラウザ
- 本番環境のHTTPS配信・R2/Worker構成
- 不正・過大なZIPへの防御とユーザースケッチの隔離

## 7. 直近の次タスク

Phase 3の最初のタスクは、AWTパッチを再現可能なビルド手順にすること。

1. Processing 4.5.2のソースコミット `c5fec05` を固定。
2. オリジナルソースと変更差分を `patches/` または `vendor/` に保存。
3. `scripts/build-processing-awt-patch.sh` を作り、Core JARを指定して一発でコンパイル・JAR化する。
4. パッチJARに必要な `PSurfaceAWT` の内部クラスがすべて含まれているか確認。
5. PoCを再実行し、現在の全成功項目を回帰テストする。

詳細は [PHASE3_PLAN.md](./PHASE3_PLAN.md) を参照。
