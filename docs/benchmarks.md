# Evidence and Benchmarks

This document keeps three measurements separate:

1. **Upstream report:** numbers published by CodeGraph.
2. **Local retrieval probe:** context size and elapsed time from this
   repository's shell script.
3. **Skill eval:** whether an agent followed the review/setup contract.

The local probe is not a model-quality, correctness, token-cost, or universal
speed benchmark.

## Upstream CodeGraph report

CodeGraph's own README reports a multi-repository comparison with and without
CodeGraph. Treat those values as upstream-reported claims, not as experiments
performed by this skill. Read the primary methodology before repeating them:

- <https://github.com/colbymchenry/codegraph#benchmark-results>
- <https://github.com/colbymchenry/codegraph#mcp-tools>

The report also describes a throughput/context trade-off. Do not quote one
side without the other.

## Local retrieval-shape probe

Run the script against an indexed checkout:

```bash
git clone --depth 1 https://github.com/colbymchenry/codegraph.git /tmp/codegraph-bench
codegraph init /tmp/codegraph-bench
benchmarks/run_local_probe.sh /tmp/codegraph-bench /tmp/codegraph-probe 5
```

The script records:

- CodeGraph version, repository path, commit, OS, and run count;
- raw output for every query and run;
- per-run elapsed time, output bytes, lines, and relationship-aware file/symbol
  counts;
- median CodeGraph and keyword-search time/bytes for each of three fixed
  questions.

It alternates retrieval order to reduce cache-order bias. The keyword baseline
is intentionally simple and is not a correctness-equivalent implementation of
CodeGraph.

## Historical single-run snapshot

The following values came from an earlier one-run probe on 2026-08-16. They are
kept only as a reproducibility reference; regenerate the table with the new
five-run script before making a current performance claim.

| Query | CodeGraph | Keyword search |
|---|---:|---:|
| MCP request flow | 3 files / 43 symbols / 20,072 bytes / 957 ms | 86 files / 901 matches / 134,113 bytes / 30 ms |
| CodeGraph impact radius | 4 files / 28 symbols / 15,211 bytes / 668 ms | 178 files / 2,741 matches / 403,976 bytes / 26 ms |
| Index freshness flow | 1 file / 27 symbols / 25,325 bytes / 705 ms | 156 files / 2,093 matches / 291,938 bytes / 23 ms |

Interpretation: raw text search is a fast primitive, while CodeGraph returns a
smaller relationship-aware context for structural questions. This does not
prove that an agent will answer every question faster or more correctly.

## Skill evaluation

Use `evals/evals.json` with isolated fixture repositories. Compare the previous
skill snapshot and the revised skill on the same prompts. Grade explicit
expectations such as:

- review mode does not write or initialize;
- setup preflight stops before writes;
- evidence is labelled and unknown values are not invented;
- high fan-in alone is not reported as a defect;
- instruction markers are not duplicated;
- mixed setup/review requests wait for restart.

Keep skill-eval results separate from the local retrieval probe.
