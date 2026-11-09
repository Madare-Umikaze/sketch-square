# PHASE3_PLAN — Runtime Stabilization

最終更新: 2026-11-10
現行基準: **Processing 4.5.7 / Java 17 / CheerpJ 5.0 / JAVA2D**

## 目的

4.5.7で成功したJAVA2Dランタイムを再現可能なビルド工程として固定し、描画の安定性・Processing API互換性・停止と復帰を検証する。4.5.2は回帰比較用の旧基準として保持する。

## 3.1 ビルド再現性とパッチ固定

- 4.5.7 source commit `ca3999a` を固定。
- 元の `PSurfaceAWT.java` とCheerpJ向け変更差分を管理。
- 4.5.7専用CLI wrapperを使い、PATHに依存しない。
- Core / patch / launcher / sketchの全てを同じ4.5.7 profileから生成。
- クリーン作業ディレクトリから再生成できることを確認。
- 4.5.2 profileも破壊されず保持されることを確認。

## 3.2 回帰テスト

基準作品 `ProcessingSmokeTest` について以下を確認する。

- 起動
- `setup()` / `draw()`
- 背景・図形・文字・アニメーション
- `frameCount`
- mouse/key events
- `data/` からの画像読込
- Consoleに予期しない404/Java例外がない

4.5.7を必須、4.5.2は変更時の比較基準として実行する。

## 3.3 描画・ウィンドウ安定性

個別テストケースを作る。

1. ウィンドウ/Canvasのサイズ変更
2. ブラウザタブを非表示にしてから復帰
3. ウィンドウ最小化/復帰
4. 連続フレーム描画を30分以上実行
5. 描画中にウィンドウを閉じる/ページ再読込
6. 同じ作品を複数回起動し、スレッド・メモリが蓄積しないか観察
7. 高DPI/異なるCanvasサイズで表示が破綻しないか確認

今回の `render() -> canvas.repaint()` パッチは、表示中の連続再描画とAWT repaintスケジューリングの相互作用を重点的に試験する。

## 3.4 API互換性テスト

単機能の小さなスケッチを個別に用意する。

- `createGraphics()` / PGraphicsのオフスクリーン描画
- `loadPixels()` / `updatePixels()` / `pixels[]`
- `PFont` / `createFont()` / `textFont()`
- `loadImage()`、複数形式、相対パス
- `saveFrame()`、`saveStrings()`、`saveBytes()`など書き込み系
- `PShape` / SVG
- `PShader`はJAVA2D対象外も含め、失敗の仕方を記録

ネイティブ依存やP2D/P3Dは別の検討トラックとし、JAVA2Dの合格範囲に混ぜない。

## 3.5 入力とフォーカス

- mousePressed/Released/Dragged/Moved
- keyPressed/Released
- フォーカス移動、キー入力がブラウザショートカットと競合しないか
- HiDPI時の座標

## 3.6 Stop/再起動・リソース解放

- CheerpJ mainの終了方法とProcessing animation threadの停止を確認。
- AWT window、executor/timer、画像Bitmap、スレッドの解放。
- stop → restart → stopの反復試験。
- 現状ページ再読み込みに依存している場合は、後から安全な停止APIを設計する。

## 3.7 サポート範囲の確定

- 初期標準: Processing 4.5.7 / JAVA2D。
- 4.5.2: 既知の旧profileとして保持。
- 4.5.3〜4.5.6: CLI aliasだけでは別投稿形式にせず、必要が生じたときにCore単位でテスト。
- Processing 3.5.4: 初期対象外。需要がある場合に独立レガシープロファイルを評価。
- P2D/P3D: 初期対象外。

## Phase 3 完了条件

- 4.5.7パッチとランタイムを再現可能に生成できる。
- Smoke Testが安定して成功する。
- リサイズ、タブ復帰、長時間描画、停止/再起動の結果が文書化される。
- 対応するProcessing APIと非対応APIが明確になる。
- ビルドメタデータでProcessing/Java/CheerpJ/renderer/patchを追跡できる。

## 次の最初の作業

既存の4.5.7動作済みファイルをGit管理下に固定し、ビルドスクリプトをクリーン実行して同じJARとブラウザ動作を再現する。次に、リサイズとタブ非表示/復帰のテストを追加する。
