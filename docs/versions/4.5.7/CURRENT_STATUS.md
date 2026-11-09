# CURRENT_STATUS — Processing 4.5.7

最終更新: 2026-11-10
状態: **移行完了。JAVA2D Smoke Testのブラウザ確認は全項目成功。**

## 確認環境

- macOS Apple Silicon (`arm64`)
- Processing 4.5.7 (`ca3999a`)
- Temurin Java 17.0.21
- CheerpJ 5.0
- Chrome

## 成功項目

| 機能 | 結果 |
|---|---|
| PDEの4.5.7 CLIビルド | 成功 |
| パッチクラスのコンパイル | 成功 |
| パッチ/Core/Launcher/Sketchの組み合わせ | 成功 |
| CheerpJ起動 | 成功 |
| AWTウィンドウ | 成功 |
| Processing `setup()` / `draw()` | 成功 |
| JAVA2D背景・図形・文字 | 成功 |
| アニメーション | 成功 |
| `frameCount` | 成功 |
| マウスクリック入力 | 成功 |
| `loadImage()` / `data/sample.png` | 成功 |
| Consoleの404/Java例外なし | 成功 |

## 使用するパッチ

- `processing/awt/PSurfaceAWT.java`
- `SmoothCanvas.paint(Graphics)` で `graphics.image` を直接表示
- `render()` で `canvas.repaint()`
- BufferStrategyによる転送を回避

## 現時点で保証しないこと

Smoke Testで通った機能以外のProcessing API、外部ライブラリ、P2D/P3D、長時間安定性、リサイズ・休止復帰、Stop/再起動、モバイルブラウザは未検証。

## 次の作業

共通の [PHASE3_PLAN.md](../../PHASE3_PLAN.md) を参照。
