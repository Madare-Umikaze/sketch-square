# PROCESSING_VERSION_POLICY — 投稿と内部ビルドのバージョン方針

最終更新: 2026-11-10
状態: 初期方針案。実際の投稿システム実装時に確定する。

## 1. 結論

投稿者に `processing-java` と `processing` の違いを意識させない。CLI名はローカルのインストール方法・バージョンに依存するビルドツールの詳細であり、PDE作品の投稿形式を分ける理由にはならない。

プラットフォーム側がProcessingのバージョンとCLI呼び出し方を管理し、選択された固定ツールチェーンでコンパイルする。PDEソースをProcessing 4.5.2用から4.5.7用へ自動変換する仕組みとはしない。

## 2. CLI名の変更が意味すること

Processing 4.5.3の公式リリースノートには、macOSのCLIインストールスクリプトが `processing-java` ではなく `processing` を作成する変更が記録されている（PR #1377）。

この変更は、IDE上のCLIインストール機能が作成するコマンド名・導線に関するもの。スケッチの `.pde` ファイル形式を分けたり、4.5.2以前のスケッチを4.5.3以降へ自動変換したりする必要があるという意味ではない。

サーバー側では、ProcessingディストリビューションごとのCLI adapterを用意する。アプリ内CLIを直接指定するか、バージョンごとのラッパーを使い、ホストOSのグローバルPATHに依存しない。

## 3. 投稿者にProcessingバージョンを選ばせるべきか

初期UIでは、バージョン選択を必須の専門知識にしない。

推奨UX:

- デフォルトは **Processing 4.5.7（プラットフォーム標準）**。
- 投稿画面では「Processing Java Mode」と表示する。
- 詳細設定に互換性オプションを設ける場合も、CLI名ではなく「Processing互換バージョン」として説明する。
- ビルド結果・作品情報には実際に使ったProcessingバージョンを表示する。
- 既存作品は、ユーザーの明示的な再ビルド操作なしに新しいProcessingバージョンへ更新しない。

PDEソースだけから作者が使用したIDEの正確なProcessingバージョンを確実に推定することはできない。ソースの構文やAPI名を走査して推測する方式は誤判定しやすい。正確な再現性が必要なら、アップロード時に明示されたバージョン、またはプロジェクトマニフェストに記録されたバージョンを使う。

## 4. 初期の対応プロファイル案

| バージョン | 内部方針 | 投稿者向け表示 |
|---|---|---|
| Processing 4.5.7 | 標準・既定。JAVA2D Smoke Test実証済み | 標準として表示 |
| Processing 4.5.2 | 旧基準。回帰比較用として保持。必要なら限定的な互換オプション | 初期は詳細設定/サポート窓口向け。恒久公開は利用実績を見て判断 |
| Processing 4.5.3〜4.5.6 | 個別のCLI adapterを増やす必要がある場合を除き、独立プロファイルを作らない。4.5.7を標準ビルド対象にする | 個別選択肢にしない |
| Processing 4.4.x〜4.0.x | 未検証。初期サポート対象外 | 非対応と明示 |
| Processing 3.5.4 | 将来の別レガシーランタイム候補。別Java/Core/patch profileが必要 | 初期サポート対象外 |
| Processing 2.x / 1.x | 対象外 | 対応予定なし |

「4.5.7でビルドできる」ことと「元のIDEバージョンと完全に同じ挙動になる」ことは同じではない。Core API・言語処理・ライブラリの差により、個別作品の互換性問題は発生し得る。初期サポート宣言は、プラットフォームの固定ビルド環境とテスト済みAPI範囲を意味する。

## 5. Processing 3を初期対応から外す理由

Processing公式の安定版ページでは、Processing 3.5.4（2020年1月17日）が最後の3系安定版として掲載され、旧版はアーカイブ用途で、公式サポート対象ではない旨が記載されている。

Processing 4はJava 17をサポートする一方、Processing 3をビルドする場合はJava 8が必要になる。CheerpJ 5.0はJava 8と17の両方を実行可能だが、それだけでProcessing 3の互換性が成立するわけではない。

3系を追加する場合は、少なくとも次を独立検証する。

- Processing 3.5.4のCoreとCLI
- Java 8コンパイル/実行profile
- 3.5.4の `PSurfaceAWT` に対する別パッチ
- ライブラリの依存関係とネイティブ依存
- Processing 3→4の言語・API変更点
- CheerpJ Java 8でのAWT/描画/入力/素材読込

そのため、初期ローンチでは3系を切り捨てるのが妥当。将来要望が十分にあれば、独立したProcessing 3.5.4 legacy engineとして追加を判断する。

## 6. ビルド単位で保存すべきメタデータ

最低限、各ビルドに次の値を記録する。

```json
{
  "format": "processing-java",
  "processingVersion": "4.5.7",
  "processingCommit": "ca3999a",
  "javaMajor": 17,
  "cheerpjVersion": "5.0",
  "renderer": "JAVA2D",
  "surfacePatch": "cheerpj-awt-1",
  "cliAdapter": "processing-4.5.7",
  "buildId": "immutable-build-id"
}
```

これは設計例であり、現時点で実装済みのマニフェストではない。

加えて、Core JAR/patch JAR/ユーザー素材のSHA-256、ビルド日時、ビルドログ、元ZIPのハッシュを保存する。

## 7. 更新ポリシー

- 新しいProcessingバージョンを導入しても、既存ビルドは自動で差し替えない。
- 新バージョンは、Smoke Testと互換性テストを通過した後に「標準」に昇格する。
- 古いバージョンを残す場合は、サポート終了日・移行方法・再ビルド条件を明示する。
- 古いCoreを恒久的に全件ホストし続ける必要はない。サポートコストと利用状況を見て、保管のみ/限定サポート/終了を判断する。
- 投稿者が選ぶのは「Processingの互換ターゲット」であって、macOSのCLIコマンド名ではない。

## 8. 公式資料

- Processing 4 releases: https://github.com/processing/processing4/releases
- Processing stable releases: https://processing.org/releases/
- Processing 4 Java support: https://github.com/processing/processing4/wiki/Supported-Platforms
- Processing 4 build notes (Java 8 for building Processing 3): https://github.com/processing/processing4/blob/main/build/README.md
- Processing 3.5.4 release: https://github.com/processing/processing/releases/tag/processing-0270-3.5.4
- CheerpJ 5.0 Java support: https://cheerpj.com/docs/overview
