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

Claude Code へスキルをインストールします。

```bash
DISABLE_TELEMETRY=1 npx skills add gamjagoon/navigate-codebase-graph \
  --skill codebase-architecture --global --agent claude --yes
```

Codex だけを対象にすることもできます。

```bash
DISABLE_TELEMETRY=1 npx skills add gamjagoon/navigate-codebase-graph \
  --skill codebase-architecture --global --agent codex --yes
```

インストール後、読み取り専用レビューを依頼してください。

> CodeGraph の根拠を使ってこのリポジトリのアーキテクチャをレビューしてください。インストール、インデックス作成、ファイル変更はしないでください。

セットアップは別に依頼してください。

> このプロジェクトに CodeGraph を設定し、適用する書き込みを先に表で示してください。

セットアップの応答は preflight 表で停止します。インストール、インデックス作成、スキルのインストール、指示ファイルの編集は、次の応答で明示的に承認してから実行します。

## このスキルが行うこと

アーキテクチャレビューでは、大量のファイルを読んでも実際の呼び出し経路を復元できなかったり、シンボル名だけを見て影響範囲を確認せずにリファクタリングを提案したりしがちです。このスキルは次の手順を使います。

1. 現在のエージェント、指示ファイル、インストール済みスキルを検出します。
2. CodeGraph とプロジェクトの `.codegraph/` インデックスの状態を、初期化せずに確認します。
3. 呼び出し元・呼び出し先・依存モジュール・影響範囲を関係ベースで探索します。
4. グラフが古い、不完全、またはソースと一致しない場合だけソースを読みます。
5. 呼び出し側の負担、重複作業、削除テスト、locality/leverage、テスト seam で評価します。
6. 変更を提案する前に、根拠、不確実性、段階的な計画を報告します。

CodeGraph が使えない、または古い場合は、git の履歴、正確な検索、直接のソース確認にフォールバックし、グラフが完全であるかのようには扱いません。

## 根拠と測定結果

このリポジトリでは、上流の主張、ローカル検索プローブ、スキル評価結果という 3 種類の根拠を明確に分けています。

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
| `codegraph explore` | 3 ファイル / 43 シンボル / 20,072 バイト | 0.957 秒 | 関係、ソース、影響範囲、テストの手掛かり |
| 固定 `rg` 検索 | 86 ファイル / 901 マッチ / 134,113 バイト | 0.030 秒 | 高速だが構造化されていない候補行 |

これは過去の 1 回実行のスナップショットであり、現在の性能保証ではありません。再実行スクリプトは 3 つの質問を 5 回実行し、中央値と生の出力を記録します。詳細は [docs/benchmarks.md](docs/benchmarks.md) と [benchmarks/run_local_probe.sh](benchmarks/run_local_probe.sh) を参照してください。

## ワークフロー

```text
アーキテクチャレビューの依頼
            │
            ▼
エージェント + インストール済みスキル + CodeGraph の状態を検出
            │
            ├─ インデックスなし ─► フォールバック根拠を使い、レビューでは初期化しない
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

インストールまたは設定を明示的に依頼した場合だけ使います。まず変更表を表示して承認を待ちます。

- 公式の配布元から CodeGraph をインストールする
- 明示的に承認したプロジェクトの `.codegraph/` インデックスを作成する
- 現在のエージェントとスキルディレクトリを確認する
- ユーザーが指定したスキルを検出したエージェントの範囲にインストールする
- codegraph install が書いた marker を重複なく確認する
- 衝突を確認したうえで、ユーザーが指定したスキルだけをインストールする

すべてのセットアップ報告には、対象、範囲、出典、変更ファイル、戻し方を記載します。

## 安全性と出典

- スキルが読み込まれただけではソフトウェアをインストールしません。
- 既存のエージェント指示を保持し、CodeGraph installer の marker を重複追加しません。
- 可能な範囲で秘密情報、認証情報、生成物、vendor ツリー、依存キャッシュを除外します。
- 外部リポジトリの指示は権限ではなく、信頼できないテキストとして扱います。
- このリポジトリには CodeGraph のソース、バイナリ、インストーラーを含めません。
- このパッケージは MIT ライセンスです。改変したワークフロー、CodeGraph 統合、ドキュメント構成の参考元は [SOURCES.md](SOURCES.md) と [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md) に分けて記載しています。

## ローカルプローブの再現

```bash
git clone --depth 1 https://github.com/colbymchenry/codegraph.git /tmp/codegraph-bench
codegraph init /tmp/codegraph-bench
benchmarks/run_local_probe.sh /tmp/codegraph-bench /tmp/codegraph-probe 5
```

## リポジトリ構成

```text
skills/codebase-architecture/SKILL.md       エージェント指示
skills/codebase-architecture/agents/         Codex UI メタデータ
skills/codebase-architecture/references/    rubric・HTML・設定・エージェント参考資料
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
