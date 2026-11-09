# PHASE3_PLAN — Runtime Stabilization

最終更新: 2026-11-10  
開始条件: Processing 4.5.2 / CheerpJ 5.0 / JAVA2D PoCの基本動作確認が完了

## Phase 3の目的

PoCで成功した描画パッチを再現可能なビルド工程として固定し、Processing JAVA2Dランタイムとしての安定性と互換性を段階的に評価する。

Phase 3では、まだ投稿サイト全体や本番のユーザー管理を作らない。まずランタイムの技術的な土台を安定させる。

---

## 3.1 AWTパッチの再現可能なビルド化（最優先）

### 目的

現在手動で実施している `PSurfaceAWT.java` の取得・変更・コンパイル・JAR化を自動化する。別のマシンや別のチャットでも同じ成果物を再生成できる状態にする。

### 推奨ファイル配置

```text
patches/
└── processing-4.5.2/
    ├── README.md
    ├── PSurfaceAWT.cheerpj.patch
    └── UPSTREAM.txt
scripts/
└── build-processing-awt-patch.sh
```

当面は修正済みソースを次の場所に保存し、リポジトリでバージョン管理する。

```text
patches/processing-4.5.2/processing/awt/PSurfaceAWT.java
```

どちらを選ぶ場合も、Processing本体のライセンス表示と著作権表示を保持する。Processing 4.5.2のソースを基準とし、他バージョンのソースを混ぜない。

### 固定情報

- Processing: `4.5.2`
- Upstream repository: `https://github.com/processing/processing4`
- Upstream commit: `c5fec05`
- Source path: `core/src/processing/awt/PSurfaceAWT.java`
- Core JAR: Processing 4.5.2 Java Modeに同梱された `core-4.5.2.jar`
- Target Java bytecode: Java 17 (`javac --release 17`)

### 初回のソース固定

現在動作確認済みの修正済みソースが `.build/patch-src/processing/awt/PSurfaceAWT.java` にあることを前提に、次のようにプロジェクト管理下へコピーする。

```bash
mkdir -p patches/processing-4.5.2/processing/awt
cp .build/patch-src/processing/awt/PSurfaceAWT.java \
  patches/processing-4.5.2/processing/awt/PSurfaceAWT.java
```

このパックに含まれる `scripts/build-processing-awt-patch.sh` は、この固定したソースをコンパイルして `public/lib/processing-awt-patch.jar` を生成する。まだユーザーのリポジトリで実行確認していないため、導入後に実行結果を記録する。

### ビルドスクリプトに求める仕様

`PROCESSING_CORE_JAR` 環境変数でCore JARを受け取る。未指定・存在しない場合は明確なエラーを出す。

実行時に以下を行う。

1. パッチ済みソースの存在確認。
2. 出力ディレクトリをクリーンにする。
3. `javac --release 17` でコンパイル。
4. `processing/awt/PSurfaceAWT*.class` が生成されたことを確認。
5. `public/lib/processing-awt-patch.jar` を生成。
6. JAR内に `PSurfaceAWT.class` とすべての内部クラスがあることを確認。
7. ビルドに使ったProcessingバージョン、コミット、JDKバージョンをログに出す。

### 完了条件

- [ ] 手作業でソースを編集せず、スクリプト1回でパッチJARを再生成できる。
- [ ] 生成JARに `PSurfaceAWT.class` と内部クラスがすべて入る。
- [ ] 既存のProcessingSmokeTestが引き続き正常に描画される。
- [ ] ソース出所、コミット、差分、ライセンスを追跡できる。

---

## 3.2 回帰テストを固定する

現在成功している `ProcessingSmokeTest` を、ランタイム変更時に毎回使うスモークテストとして維持する。

### 必須確認

- [ ] 起動時にProcessingウィンドウが表示される。
- [ ] 背景色が表示される。
- [ ] 円・四角形・三角形が表示される。
- [ ] 文字が表示される。
- [ ] アニメーションが継続する。
- [ ] `frameCount` が増加する。
- [ ] マウスクリックカウントが増加する。
- [ ] `data/sample.png` が読み込まれて表示される。
- [ ] Consoleに対象リソースの404がない。

手動テストでよいが、テスト結果と実施日を `docs/TEST_RESULTS.md` に記録する。

---

## 3.3 描画ライフサイクルと安定性

BufferStrategyを利用しない `repaint()` / `Canvas.paint()` 方式のため、再描画要求とAWT Event Dispatch Threadの動作を確認する。

### テスト項目

| テスト | 操作 | 確認すること |
|---|---|---|
| 初回表示 | ページを開いて実行 | 初期描画が欠けない |
| ウィンドウリサイズ | ウィンドウサイズを変更 | 描画サイズと内容が追従するか |
| 最小化・復帰 | ウィンドウを最小化して戻す | 再描画されるか |
| タブ切り替え | 別タブへ移動して戻る | フレーム更新が再開・継続するか |
| ウィンドウ重なり | 他ウィンドウで一部を隠して戻す | 欠けた領域が再描画されるか |
| 長時間実行 | 10分以上動作 | フリーズ、表示崩れ、メモリ増加がないか |
| 再読み込み | ページを再読み込みして再実行 | 二重起動や古いウィンドウが残らないか |

最初から全項目を自動化する必要はない。まずは手動で再現性のあるチェック手順を記録する。

### 特に確認したい技術的ポイント

- `paint(Graphics)` が常に最新の `graphics.image` を参照するか。
- `repaint()` が高頻度で呼ばれてもイベントキューが過剰に蓄積しないか。
- `graphics.image` が更新中に読み出される際のちらつきや競合がないか。
- `sketchWidth` / `sketchHeight` とCanvas実サイズが異なる場合に正しく表示されるか。
- Processingの `redraw()`、`noLoop()`、`loop()` と整合するか。

---

## 3.4 Processing API互換性テスト

JAVA2Dを中心に、一般的なProcessing作品で使用頻度の高い機能を小さなテストスケッチに分けて検証する。

### 推奨順序

1. **画像**: `loadImage()`、複数画像、画像形式、相対パス
2. **文字・フォント**: `text()`、`PFont`、`createFont()`、`loadFont()`
3. **オフスクリーン描画**: `createGraphics()`、`PGraphics.beginDraw()` / `endDraw()`
4. **ピクセル操作**: `loadPixels()`、`pixels[]`、`updatePixels()`、`get()`、`set()`
5. **入出力**: `saveFrame()`、`saveStrings()`、`loadStrings()` など
6. **入力イベント**: キーボード、マウスドラッグ、ホイール、フォーカス
7. **時間・音声**: `millis()`、`delay()`、サウンド関連（別途依存関係を確認）

### ファイルシステム上の注意

CheerpJの `/app/` はHTTP配信アセット用の読み取り領域として扱う。作品が保存処理を行う場合は、永続領域 `/files/` などの利用方法を別途設計・検証する。ブラウザから利用できる領域とProcessingが想定する通常のローカルファイルシステムは同じではない。

---

## 3.5 Stop / 再起動 / リソース管理

現在のPoCはページ再読み込みで停止・再起動する前提がある。作品投稿サイトへ進む前に、次を確認する。

- [ ] ページ再読み込みで前のAWTウィンドウが残らない。
- [ ] 同じページ内で連続起動した場合に二重のProcessingウィンドウが生成されない。
- [ ] 作品切り替え時に旧スケッチの描画処理が残らない。
- [ ] 停止操作の実装方法とCheerpJのライフサイクルを確認する。

安全な停止APIが確認できるまでは、ページリロードを確実なリセット手段として扱う。未確認の内部APIを推測して実装しない。

---

## 3.6 ブラウザ・画面サイズ検証

最低限、現在のChromeデスクトップ環境を基準にし、その後Safari、Firefox、モバイルブラウザを検証する。

- [ ] Chromeデスクトップ
- [ ] Safari macOS
- [ ] Firefoxデスクトップ
- [ ] iOS Safari
- [ ] Android Chrome
- [ ] 表示領域が小さい場合のウィンドウ挙動
- [ ] 高DPI / Retinaでのサイズと描画品質

CheerpJの対応ブラウザ情報とProcessingの描画パッチの両方を確認する。PoCでChromeが動作したことを、全ブラウザ対応の根拠にしない。

---

## 3.7 外部ライブラリ・非対応機能の整理

Processingの全ライブラリを一度に対応させようとしない。依存関係ごとに次の区分を作る。

- JAVA2Dのみで動く可能性が高いもの
- Java標準APIに依存するもの
- JNI・ネイティブライブラリに依存するもの
- OpenGL / JOGLに依存するもの
- ファイルシステムやネットワークへのアクセスを必要とするもの

P2D/P3DはJAVA2Dの検証とは分け、別の技術調査として扱う。

---

## Phase 3の完了条件

- [ ] AWTパッチを再現可能なビルドスクリプトで生成できる。
- [ ] パッチの出所、差分、Processingバージョン、ライセンスが記録されている。
- [ ] ProcessingSmokeTestの全スモークテストが再現できる。
- [ ] リサイズ、タブ切り替え、最小化・復帰、長時間実行を検証済み。
- [ ] 対応するProcessing APIと未対応・未検証APIが一覧化されている。
- [ ] Stop / 再起動時の挙動と制約が明確になっている。
- [ ] 次の投稿・ビルド基盤Phaseへ進めるだけの技術的制約が整理されている。

## Phase 3で急がないこと

- 投稿画面やSNS機能の作り込み
- ユーザー認証・課金
- P2D / P3D対応の断定
- 全外部ライブラリ対応
- 公開サービスとしての受け入れ開始

まずランタイムの再現性・安定性・互換性を優先する。
