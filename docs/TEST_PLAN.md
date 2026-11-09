# Processing + CheerpJ 互換性テスト

## 段階1: クラス起動

- [ ] `processing-java --build` が成功
- [ ] 出力JARに `ProcessingSmokeTest.class` が含まれる
- [ ] Processing Core JARが取得できる
- [ ] `cheerpjInit({ version: 17 })` が成功
- [ ] `cheerpjRunMain()` が対象クラスをロード

## 段階2: AWT / Surface

- [ ] `cheerpjCreateDisplay()` が生成した領域内にAWTウィンドウが表示
- [ ] ProcessingのSurfaceが表示
- [ ] ウィンドウの初期サイズが適用
- [ ] ブラウザリサイズ時に表示が破綻しない（必須ではない）

## 段階3: JAVA2D

- [ ] `background()`
- [ ] `line()` / `rect()` / `ellipse()`
- [ ] `fill()` / `stroke()` / `noStroke()`
- [ ] `text()`
- [ ] `PImage` / `image()`
- [ ] 連続描画とフレームレートが安定

## 段階4: 入力

- [ ] `mouseX` / `mouseY`
- [ ] `mousePressed()`
- [ ] `keyPressed()`
- [ ] キャンバスにフォーカスがある場合とない場合の違いを記録

## 段階5: ファイル

- [ ] `/app/works/demo/data/sample.png` がHTTP 200/206相当で読める
- [ ] `loadImage("sample.png")` が成功
- [ ] `loadStrings()` でUTF-8テキストを読み込める
- [ ] 保存系APIは別タスクとして扱い、初期合格条件に含めない

## 段階6: ブラウザ

- [ ] Chromeデスクトップ
- [ ] Safari macOS
- [ ] Firefoxデスクトップ
- [ ] iOS Safari（PoC後）

## テスト結果記録フォーマット

`TEST_RESULTS.md` に以下を記録する:

- 日時
- OS/ブラウザ/バージョン
- Processingバージョン
- Java/JDKバージョン
- CheerpJバージョン
- 実行コマンド
- 成功したテスト項目
- 最初に発生した例外全文
- Networkで失敗したURLとステータス
- スクリーンショット（任意）
