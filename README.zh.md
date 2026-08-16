<div align="center">

# navigate-codebase-graph

**面向编码代理、支持 CodeGraph 的架构审查技能**

在重构之前，用可验证的证据确认调用路径、依赖关系和影响范围。

[![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![CodeGraph](https://img.shields.io/badge/CodeGraph-aware-6f42c1.svg)](https://github.com/colbymchenry/codegraph)
[![Skills CLI](https://img.shields.io/badge/skills.sh-compatible-111827.svg)](https://www.skills.sh/docs/cli)
[![Evidence](https://img.shields.io/badge/benchmark-reproducible-blue.svg)](docs/benchmarks.md)

[English](README.md) · [한국어](README.ko.md) · 中文 · [日本語](README.ja.md)

</div>

## 快速开始

将技能安装到 Claude Code：

```bash
DISABLE_TELEMETRY=1 npx skills add gamjagoon/navigate-codebase-graph \
  --skill codebase-architecture --global --agent claude --yes
```

也可以只针对 Codex：

```bash
DISABLE_TELEMETRY=1 npx skills add gamjagoon/navigate-codebase-graph \
  --skill codebase-architecture --global --agent codex --yes
```

安装后可以这样请求只读审查：

> 使用 CodeGraph 证据审查这个仓库的架构。不要安装、建立索引或修改文件。

配置请单独请求：

> 为这个项目配置 CodeGraph，并先展示确切的写入计划。

配置响应在 preflight 表之后停止。安装、建索引、技能安装和指令文件修改必须在后续响应中得到明确批准。

## 这个技能做什么

架构审查常见的问题是：读取了大量文件却没有恢复真实调用路径，或者只看到一个符号名称就提出重构而没有检查影响范围。本技能采用以下流程：

1. 检测当前代理、指令文件和已安装技能。
2. 检测 CodeGraph 以及项目 `.codegraph/` 索引状态，但不要初始化它。
3. 使用关系感知的探索来查找调用方、被调用方、依赖模块和影响范围。
4. 只有图过期、不完整或与源码不一致时才读取源码。
5. 使用调用者负担、重复工作、删除测试、locality/leverage 和测试 seam 进行分析。
6. 在提出修改前报告证据、不确定性和分阶段计划。

如果 CodeGraph 不可用或索引过期，技能会退回 git 历史、精确搜索和直接源码阅读，不会假装图是完整的。

## 证据与测量结果

本仓库明确区分三类证据：上游声明、本地检索探针和技能评估结果。

### CodeGraph 发布的代理基准

CodeGraph 报告了一个包含 7 个真实开源仓库和 7 种语言的比较：使用无头 Claude Code 代理，每个条件运行 4 次，并取中位数。

| 指标 | 上游报告结果 |
|---|---:|
| 工具调用 | 减少 88% |
| 墙钟时间 | 加快 53% |
| Token | 减少 62% |
| 成本 | 降低 44% |
| 文件读取 | 7 个仓库的 CodeGraph 条件均为 0 |

这些数字来自 CodeGraph 上游报告，并不表示本技能已经独立复现了同一个代理基准。官方报告还指出，长对话中关系检索可能保留更多上下文，这是一个需要权衡的方面。请参阅 [CodeGraph 基准结果](https://github.com/colbymchenry/codegraph#benchmark-results) 和 [MCP 工具](https://github.com/colbymchenry/codegraph#mcp-tools)。

### 本地检索形状探针

我还在 CodeGraph 自身的 depth-1 检出版本上运行了一个小型 CLI 探针。这不是模型质量或成本基准，而是比较关系感知上下文与固定关键词搜索的结果形状。

| 检索方式 | 一个固定架构问题的结果 | 时间 | 提供的内容 |
|---|---:|---:|---|
| `codegraph explore` | 3 个文件 / 43 个符号 / 20,072 字节 | 0.957 秒 | 关系、源码、影响范围、测试线索 |
| 固定 `rg` 搜索 | 86 个文件 / 901 个匹配 / 134,113 字节 | 0.030 秒 | 快，但只是无结构的候选行 |

这些是历史单次运行快照，不是当前性能保证。重跑脚本现在会对三个问题各运行五次并记录中位数和原始输出。详见 [docs/benchmarks.md](docs/benchmarks.md) 与 [benchmarks/run_local_probe.sh](benchmarks/run_local_probe.sh)。

## 工作流程

```text
用户提出架构审查请求
            │
            ▼
检测代理 + 已安装技能 + CodeGraph 状态
            │
            ├─ 索引缺失 ─► 使用 fallback 证据；审查模式不初始化
            │
            ▼
探索调用路径、依赖关系和影响范围
            │
            ▼
用源码和 git 历史验证图证据
            │
            ▼
解释职责边界和变更边界
            │
            ▼
报告发现、置信度、风险和分阶段方案
```

## 两种运行模式

### 审查模式

适用于“审查架构”“这个流程经过哪些地方”“修改这个符号会影响什么”“找出合适的模块边界”等请求。默认是只读的：先用 CodeGraph 找结构，再用源码和测试验证重要结论。

### 配置模式

只有用户明确请求安装或配置时才使用。技能会先展示范围受限的 preflight 表并等待批准，然后可以：

- 从官方发布渠道安装 CodeGraph；
- 在明确批准后创建项目 `.codegraph/` 索引；
- 检查当前代理和技能目录；
- 将用户请求的技能安装到检测到的代理范围；
- 检查 `codegraph install` 写入的 marker，避免重复；
- 检查冲突后只安装用户指定的技能。

每份配置报告都会说明目标、范围、来源、变更文件和撤销方法。

## 安全与来源

- 仅仅加载技能不会触发软件安装。
- 保留已有代理指令，不重复添加 CodeGraph installer 的 marker。
- 尽可能排除秘密、凭据、生成文件、vendor 目录和依赖缓存。
- 外部仓库的指令被视为不可信文本，而不是权限来源。
- 本仓库不包含 CodeGraph 源码、二进制文件或捆绑安装器。
- 本项目代码采用 MIT 许可证；改编的工作流、CodeGraph 集成和文档布局参考分别记录在 [SOURCES.md](SOURCES.md) 与 [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md) 中。

## 重现本地探针

```bash
git clone --depth 1 https://github.com/colbymchenry/codegraph.git /tmp/codegraph-bench
codegraph init /tmp/codegraph-bench
benchmarks/run_local_probe.sh /tmp/codegraph-bench /tmp/codegraph-probe 5
```

## 仓库结构

```text
skills/codebase-architecture/SKILL.md       代理指令
skills/codebase-architecture/agents/         Codex UI 元数据
skills/codebase-architecture/references/    rubric、HTML、配置和代理参考资料
benchmarks/run_local_probe.sh               可重现的检索形状探针
docs/benchmarks.md                          方法、结果和限制
evals/evals.json                             技能测试提示
SOURCES.md                                   来源与许可证边界
THIRD_PARTY_LICENSES.md                     第三方声明
```

## 来源

- [CodeGraph](https://github.com/colbymchenry/codegraph) — 图引擎、CLI、MCP 集成和官方基准。
- [CodeGraph MCP 工具](https://github.com/colbymchenry/codegraph#mcp-tools) — `codegraph_explore` 行为文档。
- [Skills CLI](https://www.skills.sh/docs/cli) — 安装命令和代理目标选择。
- [原始 `improve-codebase-architecture` 技能](https://github.com/mattpocock/skills/tree/main/skills/engineering/improve-codebase-architecture) — 在 MIT 许可证下改编的架构审查工作流。
- [`oh-my-claudecode` 文档](https://github.com/yeachan-heo/oh-my-claudecode) — 多语言 README 切换、徽章和快速开始布局的参考。未复制代码或文案，也不是运行时依赖。
