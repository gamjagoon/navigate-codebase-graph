#!/usr/bin/env bash
set -euo pipefail

# Reproducible CLI-level retrieval probe.
# This intentionally does not claim to be an agent-quality or token-cost
# benchmark. It compares relationship-aware CodeGraph context with a fixed
# keyword-search baseline on the same checkout.

repo=${1:?usage: $0 <indexed-repository> [output-directory]}
out=${2:-"$(mktemp -d "${TMPDIR:-/tmp}/codebase-architecture-probe.XXXXXX")"}

if [[ ! -d "$repo/.codegraph" ]]; then
  echo "error: repository is not indexed: $repo" >&2
  echo "run: codegraph init \"$repo\"" >&2
  exit 2
fi

mkdir -p "$out"
printf 'query\tmode\telapsed_ms\tfiles_or_symbols\toutput_bytes\toutput_lines\tnote\n' > "$out/results.tsv"

queries=(
  'How does the codegraph_explore MCP request flow from the server entry point to the query worker? Include callers, callees, and the relevant source.'
  'What is the impact radius of changing the CodeGraph class, and which files or tests depend on it?'
  'How does CodeGraph keep the project index fresh after a file change? Include the watcher, sync path, and relevant tests.'
)

terms=(
  'codegraph_explore|query-worker|MCP'
  'CodeGraph|impact|getImpact|test'
  'watch|sync|stale|hash'
)

for i in "${!queries[@]}"; do
  query_file="$out/codegraph-$((i + 1)).txt"
  start_ms=$(date +%s%3N)
  codegraph --no-color explore --path "$repo" "${queries[$i]}" > "$query_file"
  elapsed_ms=$(( $(date +%s%3N) - start_ms ))
  files=$(rg -o '^\*\*`[^`]+`\*\*' "$query_file" | wc -l)
  symbols=$(sed -n 's/^Found \([0-9][0-9]*\) symbols.*/\1/p' "$query_file" | head -n1)
  bytes=$(wc -c < "$query_file")
  lines=$(wc -l < "$query_file")
  printf 'q%d\tcodegraph_explore\t%s\t%s files / %s symbols\t%s\t%s\trelationship-aware source context\n' \
    "$((i + 1))" "$elapsed_ms" "$files" "${symbols:-0}" "$bytes" "$lines" >> "$out/results.tsv"

  baseline_file="$out/baseline-$((i + 1)).txt"
  start_ms=$(date +%s%3N)
  rg -n -i --glob '*.ts' --glob '*.tsx' --glob '*.js' --glob '*.mjs' --glob '*.rs' --glob '*.go' \
    "${terms[$i]}" "$repo/src" "$repo/scripts" "$repo/docs" > "$baseline_file" || true
  elapsed_ms=$(( $(date +%s%3N) - start_ms ))
  files=$(rg -l -i --glob '*.ts' --glob '*.tsx' --glob '*.js' --glob '*.mjs' --glob '*.rs' --glob '*.go' \
    "${terms[$i]}" "$repo/src" "$repo/scripts" "$repo/docs" | wc -l)
  bytes=$(wc -c < "$baseline_file")
  lines=$(wc -l < "$baseline_file")
  printf 'q%d\tkeyword-search\t%s\t%s files / %s matches\t%s\t%s\tunstructured candidate lines\n' \
    "$((i + 1))" "$elapsed_ms" "$files" "$lines" "$bytes" "$lines" >> "$out/results.tsv"
done

printf 'results=%s\n' "$out/results.tsv"
cat "$out/results.tsv"
