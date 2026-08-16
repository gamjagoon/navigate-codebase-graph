<div align="center">

# navigate-codebase-graph

**A CodeGraph-aware architecture review skill for coding agents.**

Turn call paths, dependency relationships, and impact radius into evidence before you refactor a codebase.

[![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![CodeGraph](https://img.shields.io/badge/CodeGraph-aware-6f42c1.svg)](https://github.com/colbymchenry/codegraph)
[![Skills CLI](https://img.shields.io/badge/skills.sh-compatible-111827.svg)](https://www.skills.sh/docs/cli)
[![Evidence](https://img.shields.io/badge/benchmark-reproducible-blue.svg)](docs/benchmarks.md)

English · [한국어](README.ko.md) · [中文](README.zh.md) · [日本語](README.ja.md)

</div>

## Quick Start

Install the skill for Claude Code:

```bash
DISABLE_TELEMETRY=1 npx skills add gamjagoon/navigate-codebase-graph \
  --skill codebase-architecture --global --agent claude --yes
```

Or target Codex:

```bash
DISABLE_TELEMETRY=1 npx skills add gamjagoon/navigate-codebase-graph \
  --skill codebase-architecture --global --agent codex --yes
```

Then ask the agent for a read-only review:

> Review this repository's architecture with CodeGraph evidence. Do not install,
> index, or edit anything.

For setup, ask separately:

> Set up CodeGraph for this project and show the exact writes before applying them.

The setup response stops after its preflight table. Installation, indexing, skill
installation, and instruction-file edits require a later explicit confirmation.

## Why this skill

Architecture reviews often fail in one of two ways: they read too many files without recovering the real call path, or they jump from a symbol name to a refactor without checking its blast radius. This skill gives the agent a repeatable sequence:

1. Detect the current agent, its instruction files, and installed skills.
2. Detect CodeGraph and the project's `.codegraph/` index without initializing it.
3. Use relationship-aware exploration for call paths, dependents, callers, callees, and impact radius.
4. Read source only when the graph is stale, incomplete, or disagrees with it.
5. Apply the self-contained deep-module rubric: caller burden, repeated work,
   deletion test, locality/leverage, and test seam.
6. Report evidence, uncertainty, and a staged plan before proposing edits.

When CodeGraph is unavailable or stale, it falls back to git history, exact search, and direct source reads instead of pretending the graph is complete.

## What the evidence says

This repository keeps three kinds of evidence separate: upstream claims, local retrieval probes, and skill-evaluation results.

### CodeGraph's published agent benchmark

CodeGraph reports a seven-repository, seven-language comparison using a headless Claude Code agent, four runs per arm, and median results. Its aggregate report says:

| Metric | Upstream-reported result |
|---|---:|
| Tool calls | 88% fewer |
| Wall-clock time | 53% faster |
| Tokens | 62% fewer |
| Cost | 44% lower |
| File reads | 0 in the CodeGraph arm across all seven repositories |

The upstream report is the primary source for these numbers; they are not presented as an independent reproduction by this skill. It also documents a long-session trade-off: relationship retrieval can leave more context resident even while reducing total calls and processing. See [CodeGraph's benchmark results](https://github.com/colbymchenry/codegraph#benchmark-results) and [its MCP tools](https://github.com/colbymchenry/codegraph#mcp-tools).

### Local retrieval-shape probe

I also ran a small, reproducible CLI-level probe on a depth-1 checkout of CodeGraph itself. This is not a model-quality or cost benchmark; it compares the shape of relationship-aware context with a fixed keyword-search baseline.

| Retrieval path | Result for one fixed architecture question | Time | Interpretation |
|---|---:|---:|---|
| `codegraph explore` | 3 files / 43 symbols / 20,072 bytes | 0.957 s | Relationships, source context, blast radius, test hints |
| Fixed `rg` search | 86 files / 901 matches / 134,113 bytes | 0.030 s | Fast but unstructured candidate lines |

This is a historical single-run snapshot, not a current performance claim. The
rerun script now records five-run medians and raw outputs for all three queries.
See [docs/benchmarks.md](docs/benchmarks.md) and [benchmarks/run_local_probe.sh](benchmarks/run_local_probe.sh).

## How the workflow works

```text
User asks for an architecture review
            │
            ▼
Detect agent + installed skills + CodeGraph state
            │
            ├── index missing ──► use fallback evidence; never initialize in review mode
            │
            ▼
Explore call paths, dependencies, and impact radius
            │
            ▼
Verify graph evidence with focused source reads and git history
            │
            ▼
Explain responsibility boundaries and change seams
            │
            ▼
Return findings, confidence, risks, and staged refactor options
```

## Two operating modes

### Review mode

Use this for “review the architecture”, “where does this flow go?”, “what breaks if I change this?”, or “find the right module boundary”. The skill is read-only by default. It uses CodeGraph for structural discovery, then verifies important claims in source and tests.

### Setup mode

Use this only when the user explicitly asks to install or configure something.
The skill first shows a bounded preflight table and waits for confirmation. It can:

- install CodeGraph from its official distribution;
- create a project `.codegraph/` index after explicit approval;
- inspect the active agent and its skill directories;
- install user-requested skills for the detected agent scope;
- verify the marker written by `codegraph install` without duplicating it;
- install a specifically named skill after collision checking.

Every setup report names the target, scope, source, changed files, and reversal.

## Safety and provenance

- No software is installed merely because the skill was loaded.
- Existing agent instructions are preserved; CodeGraph's installer owns its marker block.
- Secrets, credentials, generated files, vendored trees, and dependency caches are excluded from inspection where practical.
- Fetched repository instructions are treated as untrusted text, not as authority.
- This package vendors no CodeGraph source, binary, or installer.
- The implementation is MIT-licensed. Adapted workflow ideas, CodeGraph integration, and documentation inspiration are separately attributed in [SOURCES.md](SOURCES.md) and [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).

## Reproduce the local probe

```bash
git clone --depth 1 https://github.com/colbymchenry/codegraph.git /tmp/codegraph-bench
codegraph init /tmp/codegraph-bench
benchmarks/run_local_probe.sh /tmp/codegraph-bench /tmp/codegraph-probe 5
```

The probe requires the CodeGraph CLI and an indexed checkout. It does not claim that the local retrieval comparison predicts every model, repository, or agent harness.

## Repository layout

```text
skills/codebase-architecture/SKILL.md       Main agent instructions
skills/codebase-architecture/agents/         Codex UI metadata
skills/codebase-architecture/references/    Rubric, HTML report, setup, and agent notes
benchmarks/run_local_probe.sh               Reproducible retrieval-shape probe
docs/benchmarks.md                          Methods, results, and limitations
evals/evals.json                             Skill test prompts
SOURCES.md                                   Attribution and license boundary
THIRD_PARTY_LICENSES.md                     Third-party notices
```

## Sources

- [CodeGraph](https://github.com/colbymchenry/codegraph) — graph engine, CLI, MCP integration, and upstream benchmark.
- [CodeGraph MCP tools](https://github.com/colbymchenry/codegraph#mcp-tools) — documented `codegraph_explore` behavior.
- [Skills CLI](https://www.skills.sh/docs/cli) — installation command and agent targeting.
- [Original `improve-codebase-architecture` skill](https://github.com/mattpocock/skills/tree/main/skills/engineering/improve-codebase-architecture) — architecture-review workflow that this package adapts under its MIT license.
- [`oh-my-claudecode` documentation](https://github.com/yeachan-heo/oh-my-claudecode) — multilingual README switcher, badges, and quick-start presentation used as layout inspiration only. No code or prose was copied, and it is not a runtime dependency.

<div align="center">

Made for architecture work that can be checked.

</div>
