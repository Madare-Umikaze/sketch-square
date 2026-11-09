# PHASE3_PLAN — Processing 4.5.7

最終更新: 2026-11-10

## Phase 3.1 — ビルド再現性

- Processing 4.5.7 release commit `ca3999a` を固定。
- パッチ適用対象の元ファイルを保存。
- パッチ差分を明示的に保存。
- 4.5.7 CLI wrapper、Core、patch、launcher、sketchを同一profileで生成。
- クリーンビルド後にブラウザSmoke Testを再実行。
- 4.5.2ファイルを上書きしていないことを確認。

## Phase 3.2 — 描画安定性

- ウィンドウサイズ変更
- ブラウザタブ非表示・復帰
- 最小化・復帰
- 連続描画30分以上
- ページ再読み込みを含む停止・再起動
- メモリ/CPU/スレッドの観察

## Phase 3.3 — API互換性

- `createGraphics()`
- `loadPixels()` / `updatePixels()` / `pixels[]`
- `PFont` / `createFont()`
- `PShape` / SVG
- `saveFrame()` / `saveStrings()`等
- 画像ロード形式・相対パス
- 外部ライブラリは個別に評価

## Phase 3.4 — 対応ポリシー

- 4.5.7を初期の標準対象とする。
- 4.5.2は既知の旧profileとして保存。
- 4.5.3〜4.5.6はCLI名の差だけを理由に投稿形式を分けない。
- 3.5.4は独立したlegacy track候補。初期サポート対象外。

## 完了条件

- クリーン環境から4.5.7 runtimeを再生成可能。
- Smoke Testの再現性が確認済み。
- 安定性試験とAPI試験の合否が記録済み。
- 対応API/非対応APIの一覧が作成済み。
