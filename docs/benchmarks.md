# Evidence and Benchmarks

This document separates upstream claims from the local probe run for this
skill. The local probe is intentionally modest: it measures retrieval shape,
not model intelligence, answer correctness, or a universal cost guarantee.

## Upstream CodeGraph report

The CodeGraph project reports a 2026-08-05 re-measurement over seven real
open-source repositories and seven languages. Its methodology compares a
headless Claude Code agent answering one architecture question with and
without CodeGraph, using four runs per arm and reporting medians.

The reported aggregate result is:

| Metric | CodeGraph's reported result |
|---|---:|
| Tool calls | 88% fewer |
| Wall-clock time | 53% faster |
| Tokens | 62% fewer |
| Cost | 44% lower |
| File reads | 0 in the CodeGraph arm across seven repositories |

These are **upstream-reported results**, not a claim that this skill has
reproduced the same agent benchmark. The same report also notes an important
trade-off: CodeGraph can leave more retrieval context resident in a long
conversation even while reducing total processing and tool calls.

Read the primary source and methodology:

- [CodeGraph README — Why CodeGraph and benchmark results](https://github.com/colbymchenry/codegraph#benchmark-results)
- [CodeGraph README — MCP tools](https://github.com/colbymchenry/codegraph#mcp-tools)
- [CodeGraph benchmark methodology](https://github.com/colbymchenry/codegraph#benchmark-results)

## Local retrieval-shape probe

Run date: 2026-08-16 (Asia/Seoul)

Environment:

- CodeGraph CLI: `1.5.0`
- Repository: a depth-1 clone of `colbymchenry/codegraph`
- Index: 570 files, 12,733 nodes, 44,903 edges, 53.30 MiB database
- Initial indexing: 3.1 seconds
- Questions: three fixed architecture/flow questions
- Baseline: fixed `rg` keyword search over the same source areas

One representative question was:

> How does the `codegraph_explore` MCP request flow from the server entry point to the query worker? Include callers, callees, and the relevant source.

Representative result:

| Retrieval path | Files/symbols or matches | Output | Time | What it provides |
|---|---:|---:|---:|---|
| `codegraph explore` | 3 files / 43 symbols | 20,072 bytes | 0.67–0.96 s observed across repeated runs | source, relationships, blast radius, test hints |
| fixed keyword search | 86 files / 901 matches | 134,113 bytes | 0.02–0.04 s | unstructured candidate lines |

Interpretation: raw search is faster as a text primitive, but it returns a
much larger candidate set and does not resolve the call path or impact radius.
CodeGraph adds query overhead in exchange for relationship-aware context that
is smaller and closer to an architecture answer. This is evidence for the
skill's routing rule — use CodeGraph for structural questions, and keep normal
search for exact text lookup and verification.

The latest three-query run produced this additional shape comparison:

| Query | CodeGraph result | Fixed keyword-search result |
|---|---|---|
| MCP request flow | 3 files / 43 symbols / 20,072 bytes / 0.96 s | 86 files / 901 matches / 134,113 bytes / 0.03 s |
| `CodeGraph` impact radius | 4 files / 28 symbols / 15,211 bytes / 0.67 s | 178 files / 2,741 matches / 403,976 bytes / 0.03 s |
| index freshness | 1 file / 27 symbols / 25,325 bytes / 0.71 s | 156 files / 2,093 matches / 291,938 bytes / 0.02 s |

Times are single-run wall-clock observations on the local machine and are
not a performance guarantee. The comparison is about context shape and
relationship resolution, not answer correctness.

Re-run the probe:

```bash
git clone --depth 1 https://github.com/colbymchenry/codegraph.git /tmp/codegraph-bench
codegraph init /tmp/codegraph-bench
benchmarks/run_local_probe.sh /tmp/codegraph-bench
```

The script is a retrieval probe, not a replacement for a controlled agent
benchmark. For a model-level comparison, reuse CodeGraph's published harness,
pin the model and repository snapshots, block CLI contamination in the
without arm, and report medians over repeated runs.
