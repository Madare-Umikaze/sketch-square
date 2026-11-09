# HANDOFF — Processing Web Runtime PoC

最終更新: 2026-11-10

## 1. 目的

UnityRoomのように、ユーザーが投稿した作品をブラウザで閲覧・実行できるサービスを目指す。最初の投稿形式はProcessing Java Mode（PDE）、初期レンダラーはJAVA2Dとする。ブラウザ内Java実行にはCheerpJ 5.0を使用する。

p5.jsおよびUnity WebGLは別の投稿形式・別ランタイムとして将来追加する。Processing Java Mode作品をp5.jsへ自動変換することは前提にしない。

## 2. 現在の標準開発基準

- Processing: **4.5.7**
- Processing release commit: `ca3999a`
- Java: 17（開発環境ではTemurin 17.0.21を使用）
- CheerpJ: 5.0
- Renderer: JAVA2D
- 対象Surface: `processing.awt.PSurfaceAWT`
- Browser PoC: Chrome / localhost

Processing 4.5.7はProcessing公式の現行安定版として確認したもの（2026-11-10時点）。4.5.2も動作実証済みの旧基準として保持する。

## 3. 4.5.7で実証済みの実行構成

クラスパス順序:

```text
/app/lib/processing-awt-patch-4.5.7.jar
/app/ProcessingWebLauncher-4.5.7.jar
/app/works/demo/v4.5.7/ProcessingSmokeTest.jar
/app/lib/processing-core-4.5.7.jar
```

この順序を維持する。パッチJARを先頭に置き、Processing標準の `processing.awt.PSurfaceAWT` より先に同名クラスをロードさせる。

起動クラス: `ProcessingWebLauncher`

ランチャーの役割:

- CheerpJから渡されたスケッチパスを受け取る。
- `PApplet.main()` に `--sketch-path=<path>` をクラス名より前に配置して渡す。
- PDEの自動生成 `main()` に起動オプションの順序を依存させない。

## 4. CheerpJ向けAWT描画パッチ

修正対象:

`processing/awt/PSurfaceAWT.java`

`SmoothCanvas.paint(Graphics screen)` は、Processingが生成した `graphics.image` を通常の `Graphics.drawImage()` で表示する。

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

`render()` は `BufferStrategy` を使わず、Canvasの再描画を要求する。

```java
protected void render() {
    if (canvas.isDisplayable() && graphics.image != null) {
        canvas.repaint();
    }
}
```

### 原因調査の記録

- 通常の `Canvas.paint(Graphics)` からの描画はCheerpJ上で成功。
- `BufferedImage` の生成と通常のGraphics経由の描画も成功。
- AWT `BufferStrategy.getDrawGraphics()` はテストで `NullPointerException` になった。
- Processing標準 `PSurfaceAWT` の画面転送がBufferStrategyに依存していた。
- そのため、画面転送だけを通常のAWT Canvas描画に差し替えた。

これはPoCで実測した回避策。スレッド同期、リサイズ、最小化・復帰、長時間運転などの完全な安定性は別途検証する。

## 5. 4.5.7の動作確認済み項目

- CheerpJ初期化とJava main起動
- Processingウィンドウ生成
- `setup()` / `draw()`
- 背景、円、四角形、三角形、文字
- アニメーション
- `frameCount`
- マウスクリックカウント
- `loadImage("sample.png")` による `data/` 内画像の読み込み
- Chrome Consoleに対象画像の404が残らないこと

4.5.2でも同じSmoke Testを動作実証済み。詳細はバージョン別記録を参照。

## 6. CLIのバージョン差をどう扱うか

Processing 4.5.3のリリースノートには、macOSのCLIインストールスクリプトが `processing-java` ではなく `processing` を作成する変更が記録されている。

これは投稿者が別形式でPDEを提出する必要がある変更ではない。サーバー側のビルドアダプターが、選択されたProcessingディストリビューションのCLI呼び出し方を吸収する。

`processing-java` というコマンド名を作品のファイル形式や投稿条件にしない。ビルド処理はアプリの固定パスとバージョン別アダプターを使い、グローバルPATHに依存しない。

## 7. 今後の重要タスク

1. 4.5.7パッチの取得元・コミット・差分を固定し、クリーン環境から再現ビルドできるようにする。
2. Smoke Testを回帰テストとして保存する。
3. リサイズ・タブ非表示/復帰・最小化・長時間描画・再起動を試験する。
4. `createGraphics()`、`pixels[]`、フォント、保存系APIを個別評価する。
5. 投稿作品のビルドメタデータにProcessing/Java/CheerpJ/renderer/patchのバージョンを保存する。
6. P2D/P3Dと外部ライブラリは個別の互換性調査を行う。

## 8. 重要な制約

- 現時点の成功はJAVA2DのSmoke Testに対するもの。Processing全APIとの完全互換を意味しない。
- P2D/P3D、ネイティブ依存ライブラリ、外部ライブラリ全般は未検証。
- 実行する投稿スケッチは信頼できないコードとして扱う。本番では実行用オリジンの分離、権限・ネットワーク制約、リソース制限、コンパイル環境の隔離が必要。
- Processing/Java/CheerpJのバージョンを固定し、既存作品を無断で新しいCoreに再ビルドしない。

## 9. バージョン別の詳細

- [Processing 4.5.2](versions/4.5.2/HANDOFF.md)
- [Processing 4.5.7](versions/4.5.7/HANDOFF.md)
- [Version Policy](PROCESSING_VERSION_POLICY.md)
