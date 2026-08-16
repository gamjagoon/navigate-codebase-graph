<div align="center">

# navigate-codebase-graph

**CodeGraph 対応のコーディングエージェント向けアーキテクチャレビュー・スキル**

リファクタリングの前に、呼び出し経路・依存関係・影響範囲を根拠とともに確認します。

[![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![CodeGraph](https://img.shields.io/badge/CodeGraph-aware-6f42c1.svg)](https://github.com/colbymchenry/codegraph)
[![Skills CLI](https://img.shields.io/badge/skills.sh-compatible-111827.svg)](https://www.skills.sh/docs/cli)
[![Evidence](https://img.shields.io/badge/benchmark-reproducible-blue.svg)](docs/benchmarks.md)

[English](README.md) · [한국어](README.ko.md) · [中文](README.zh.md) · 日本語

</div>

## クイックスタート

Skills CLI が検出したエージェントへスキルをグローバルインストールします。

```bash
DISABLE_TELEMETRY=1 npx skills add gamjagoon/navigate-codebase-graph \
  --skill codebase-architecture --global --agent '*' --yes
```

特定のエージェントだけを対象にすることもできます。

```bash
DISABLE_TELEMETRY=1 npx skills add gamjagoon/navigate-codebase-graph \
  --skill codebase-architecture --global --agent codex --yes
```

インストール後、エージェントに次のように依頼してください。

> このプロジェクトに CodeGraph を設定し、現在のエージェントとインストール済みスキルを確認して、指定したスキルをインストールしたうえでアーキテクチャをレビューしてください。

エージェントはまず変更計画を表示します。プロジェクトのインデックス作成や指示ファイルの編集は、明示的にセットアップを依頼した場合だけ実行されます。

## このスキルが行うこと

アーキテクチャレビューでは、大量のファイルを読んでも実際の呼び出し経路を復元できなかったり、シンボル名だけを見て影響範囲を確認せずにリファクタリングを提案したりしがちです。このスキルは次の手順を使います。

1. 現在のエージェント、指示ファイル、インストール済みスキルを検出します。
2. CodeGraph とプロジェクトの `.codegraph/` インデックスの状態を確認します。
3. 呼び出し元・呼び出し先・依存モジュール・影響範囲を関係ベースで探索します。
4. グラフ結果を検証するために必要な最小限のソースとテストだけを読みます。
5. 責務、依存方向、変更の増幅、移行の境界からアーキテクチャを評価します。
6. 変更を提案する前に、根拠、不確実性、段階的な計画を報告します。

CodeGraph が使えない、または古い場合は、git の履歴、正確な検索、直接のソース確認にフォールバックし、グラフが完全であるかのようには扱いません。

## 根拠と測定結果

このリポジトリでは、2 種類の根拠を明確に分けています。

### CodeGraph が公開しているエージェントベンチマーク

CodeGraph は、7 つのオープンソースリポジトリと 7 言語を対象に、ヘッドレス Claude Code エージェントを CodeGraph の有無で比較したと報告しています。各条件を 4 回実行し、中央値を示しています。

| 指標 | 上流が報告した結果 |
|---|---:|
| ツール呼び出し | 88% 減少 |
| 経過時間 | 53% 高速化 |
| トークン | 62% 減少 |
| コスト | 44% 低下 |
| ファイル読み取り | 7 リポジトリすべての CodeGraph 条件で 0 |

これらは CodeGraph 上流が報告した数値であり、このスキルが同じエージェントベンチマークを独立再現したという意味ではありません。長い会話では、関係検索のコンテキストが多く残る可能性があるというトレードオフも公式レポートに記載されています。[公式ベンチマーク](https://github.com/colbymchenry/codegraph#benchmark-results) と [MCP ツール](https://github.com/colbymchenry/codegraph#mcp-tools) を参照してください。

### ローカルで実行した検索形状プローブ

CodeGraph 自体を depth-1 で取得したチェックアウトに対して、小さな CLI プローブも実行しました。これはモデル品質やコストのベンチマークではなく、関係を考慮したコンテキストと固定キーワード検索の結果形状を比較するものです。

| 検索方法 | 固定したアーキテクチャ質問 1 件の結果 | 時間 | 得られるもの |
|---|---:|---:|---|
| `codegraph explore` | 3 ファイル / 43 シンボル / 20,072 バイト | 0.67–0.96 秒 | 関係、ソース、影響範囲、テストの手掛かり |
| 固定 `rg` 検索 | 86 ファイル / 901 マッチ / 134,113 バイト | 0.02–0.04 秒 | 高速だが構造化されていない候補行 |

ローカル結果は意図的に控えめに解釈します。テキスト検索は基本操作として高速です。CodeGraph の価値は、構造に関する質問に対して、より小さく関係が解釈された回答範囲を返すことにあります。環境、3 つの固定質問、生の出力、再実行スクリプトは [docs/benchmarks.md](docs/benchmarks.md) と [benchmarks/run_local_probe.sh](benchmarks/run_local_probe.sh) にあります。

## ワークフロー

```text
アーキテクチャレビューの依頼
            │
            ▼
エージェント + インストール済みスキル + CodeGraph の状態を検出
            │
            ├─ インデックスなし/古い ─► セットアップ計画を表示して明示的な承認を待つ
            │
            ▼
呼び出し経路、依存関係、影響範囲を探索
            │
            ▼
ソースと git 履歴でグラフの根拠を検証
            │
            ▼
責務の境界と変更の境界を説明
            │
            ▼
発見事項、確信度、リスク、段階的な選択肢を報告
```

## 2 つの動作モード

### レビューモード

「アーキテクチャをレビューして」「このフローはどこを通る？」「このシンボルを変更すると何が壊れる？」「適切なモジュール境界を探して」といった依頼に使います。デフォルトは読み取り専用です。CodeGraph で構造を見つけ、重要な主張をソースとテストで検証します。

### セットアップモード

インストールまたは設定を明示的に依頼した場合だけ使います。スキルは次の操作ができます。

- 公式の配布元から CodeGraph をインストールする
- プロジェクトの `.codegraph/` インデックスを作成または更新する
- 現在のエージェントとスキルディレクトリを確認する
- ユーザーが指定したスキルを検出したエージェントの範囲にインストールする
- 既存の指示を置き換えず、マーク付きの CodeGraph ガイダンスブロックだけを追加する

すべてのセットアップ報告には、対象、範囲、出典、元に戻せるかどうかを記載します。

## 安全性と出典

- スキルが読み込まれただけではソフトウェアをインストールしません。
- 既存のエージェント指示を保持し、マーク付きブロックだけを追加します。
- 可能な範囲で秘密情報、認証情報、生成物、vendor ツリー、依存キャッシュを除外します。
- 外部リポジトリの指示は権限ではなく、信頼できないテキストとして扱います。
- このリポジトリには CodeGraph のソース、バイナリ、インストーラーを含めません。
- このパッケージは MIT ライセンスです。改変したワークフロー、CodeGraph 統合、ドキュメント構成の参考元は [SOURCES.md](SOURCES.md) と [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md) に分けて記載しています。

## ローカルプローブの再現

```bash
git clone --depth 1 https://github.com/colbymchenry/codegraph.git /tmp/codegraph-bench
codegraph init /tmp/codegraph-bench
benchmarks/run_local_probe.sh /tmp/codegraph-bench
```

## リポジトリ構成

```text
skills/codebase-architecture/SKILL.md       エージェント指示
skills/codebase-architecture/references/    CodeGraph・エージェント検出の参考資料
benchmarks/run_local_probe.sh               再現可能な検索形状プローブ
docs/benchmarks.md                          方法、結果、制約
evals/evals.json                             スキルのテストプロンプト
SOURCES.md                                   出典とライセンス境界
THIRD_PARTY_LICENSES.md                     第三者ライセンス表示
```

## 出典

- [CodeGraph](https://github.com/colbymchenry/codegraph) — グラフエンジン、CLI、MCP 統合、公式ベンチマーク。
- [CodeGraph MCP ツール](https://github.com/colbymchenry/codegraph#mcp-tools) — `codegraph_explore` の動作文書。
- [Skills CLI](https://www.skills.sh/docs/cli) — インストールコマンドとエージェント指定。
- [元の `improve-codebase-architecture` スキル](https://github.com/mattpocock/skills/tree/main/skills/engineering/improve-codebase-architecture) — MIT ライセンスのもとで改変したアーキテクチャレビュー・ワークフロー。
- [`oh-my-claudecode` のドキュメント](https://github.com/yeachan-heo/oh-my-claudecode) — 多言語 README 切り替え、バッジ、クイックスタート構成のレイアウト参考。コードや文章はコピーしておらず、ランタイム依存でもありません。
