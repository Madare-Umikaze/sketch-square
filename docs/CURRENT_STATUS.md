# CURRENT_STATUS — Processing Web Runtime

最終更新: 2026-11-10
状態: **Processing 4.5.7への移行とブラウザ動作確認が完了。Phase 3の安定性・互換性検証へ進む。**

## 1. 現行標準構成

| 項目 | 値 |
|---|---|
| Processing | 4.5.7 |
| Processing commit | `ca3999a` |
| Java | 17 |
| CheerpJ | 5.0 |
| Renderer | JAVA2D |
| 描画Surface | `PSurfaceAWT`（CheerpJ向け差し替え） |
| 確認ブラウザ | Chrome |

## 2. バージョン別の実証状況

| Processing | ローカルPDEビルド | パッチビルド | CheerpJブラウザ描画 | Smoke Test全項目 |
|---|---:|---:|---:|---:|
| 4.5.2 | 成功 | 成功 | 成功 | 成功 |
| 4.5.7 | 成功 | 成功 | 成功 | 成功 |
| 4.5.3〜4.5.6 | 未検証 | 未検証 | 未検証 | 未検証 |
| 4.4.x以前の4系 | 未検証 | 未検証 | 未検証 | 未検証 |
| 3.5.4 | 未対応 | 未対応 | 未検証 | 未検証 |
| 2.x / 1.x | 対象外 | 対象外 | 未検証 | 未検証 |

## 3. 4.5.7で成功した機能

- CheerpJ起動、Java main起動
- Processing AWTウィンドウ
- `setup()` / `draw()`
- JAVA2Dによる図形・文字・背景の描画
- アニメーションと`frameCount`
- マウスクリック入力
- `data/sample.png` の画像読込
- Consoleの404/Java例外なし（Smoke Test）

## 4. バージョン管理の決定

- 新規作品の標準ビルド対象は4.5.7。
- 4.5.2は動作確認済みの旧ランタイムとして保持する。
- 4.5.3〜4.5.6をCLI名の違いだけで個別投稿形式に分けない。
- Processing 3.5.4は別ランタイム候補。初期対応に含めない。
- ソースコードを機械的に変換するのではなく、バージョン固定したCore/CLIでコンパイルする。

詳細: [PROCESSING_VERSION_POLICY.md](PROCESSING_VERSION_POLICY.md)

## 5. 未検証事項

- リサイズ、最小化、画面復帰、ブラウザタブ非表示/復帰
- 長時間実行、CPU・メモリ使用量
- Stop/再起動とAWTスレッド/リソースの解放
- `createGraphics()`、`loadPixels()`、`updatePixels()`、`pixels[]`
- `PFont`、`createFont()`、外部フォント
- `saveFrame()`、`saveStrings()`等の書き込み先
- 外部Processingライブラリ
- P2D/P3D
- Safari/Firefox/モバイルブラウザ
- 本番のR2/Worker配信とRange/Cache
- 投稿ZIPの検証、ビルド隔離、実行制限

## 6. 次の作業

Phase 3.1として、4.5.7のパッチをクリーンな作業ディレクトリから再現可能にビルドできることを確認する。その後、回帰テスト、安定性、API互換性を順に検証する。
