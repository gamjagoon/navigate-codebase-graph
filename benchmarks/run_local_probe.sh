#!/usr/bin/env bash
set -euo pipefail

# Retrieval-shape probe only. This does not measure model correctness, skill
# quality, token cost, or universal speed.

repo=${1:?usage: $0 <indexed-repository> [output-directory] [runs]}
out=${2:-"$(mktemp -d "${TMPDIR:-/tmp}/codebase-architecture-probe.XXXXXX")"}
runs=${3:-5}

command -v codegraph >/dev/null || { echo "error: codegraph is not on PATH" >&2; exit 2; }
command -v rg >/dev/null || { echo "error: rg is not on PATH" >&2; exit 2; }
[[ -d "$repo" ]] || { echo "error: repository does not exist: $repo" >&2; exit 2; }
[[ -d "$repo/.codegraph" ]] || {
  echo "error: repository is not indexed: $repo" >&2
  echo "run: codegraph init \"$repo\"" >&2
  exit 2
}
[[ "$runs" =~ ^[1-9][0-9]*$ ]] || { echo "error: runs must be a positive integer" >&2; exit 2; }

mkdir -p "$out/raw"
printf 'codegraph_version\t%s\n' "$(codegraph version)" > "$out/metadata.tsv"
printf 'repository\t%s\n' "$(cd "$repo" && pwd -P)" >> "$out/metadata.tsv"
printf 'repository_commit\t%s\n' "$(git -C "$repo" rev-parse HEAD 2>/dev/null || echo unavailable)" >> "$out/metadata.tsv"
printf 'os\t%s\n' "$(uname -srm)" >> "$out/metadata.tsv"
printf 'runs\t%s\n' "$runs" >> "$out/metadata.tsv"

printf 'query\trun\tmode\telapsed_ms\tfiles_or_symbols\toutput_bytes\toutput_lines\tnote\n' > "$out/results.tsv"
printf 'query\tcodegraph_median_ms\tkeyword_median_ms\tcodegraph_median_bytes\tkeyword_median_bytes\n' > "$out/summary.tsv"

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

search_roots=()
for candidate in src scripts docs lib packages; do
  [[ -d "$repo/$candidate" ]] && search_roots+=("$repo/$candidate")
done
if ((${#search_roots[@]} == 0)); then
  search_roots=("$repo")
fi

median() {
  local value
  mapfile -t values < <(printf '%s\n' "$@" | sort -n)
  value=${values[$(( ${#values[@]} / 2 ))]}
  printf '%s' "$value"
}

for i in "${!queries[@]}"; do
  qnum=$((i + 1))
  graph_times=()
  text_times=()
  graph_bytes=()
  text_bytes=()

  for ((run=1; run<=runs; run++)); do
    graph_file="$out/raw/codegraph-${qnum}-${run}.txt"
    baseline_file="$out/raw/baseline-${qnum}-${run}.txt"

    run_graph_first=$(( (run + i) % 2 ))
    if ((run_graph_first == 0)); then
      start_ms=$(date +%s%3N)
      codegraph --no-color explore --path "$repo" "${queries[$i]}" > "$graph_file"
      elapsed_ms=$(( $(date +%s%3N) - start_ms ))
      graph_times+=("$elapsed_ms")

      graph_files=$(rg -o '^\*\*\x60[^\x60]+\x60\*\*' "$graph_file" | wc -l || true)
      graph_symbols=$(sed -n 's/^Found \([0-9][0-9]*\) symbols.*/\1/p' "$graph_file" | head -n1)
      [[ -n "$graph_symbols" ]] || { echo "error: CodeGraph output format did not contain a symbol count" >&2; exit 3; }
      graph_bytes+=("$(wc -c < "$graph_file")")
      printf 'q%d\t%d\tcodegraph_explore\t%s\t%s files / %s symbols\t%s\t%s\trelationship-aware source context\n' \
        "$qnum" "$run" "$elapsed_ms" "$graph_files" "$graph_symbols" "${graph_bytes[-1]}" "$(wc -l < "$graph_file")" >> "$out/results.tsv"
    fi

    start_ms=$(date +%s%3N)
    rg -n -i --glob '*.ts' --glob '*.tsx' --glob '*.js' --glob '*.mjs' --glob '*.rs' --glob '*.go' \
      "${terms[$i]}" "${search_roots[@]}" > "$baseline_file" || true
    elapsed_ms=$(( $(date +%s%3N) - start_ms ))
    text_times+=("$elapsed_ms")
    text_files=$(rg -l -i --glob '*.ts' --glob '*.tsx' --glob '*.js' --glob '*.mjs' --glob '*.rs' --glob '*.go' \
      "${terms[$i]}" "${search_roots[@]}" | wc -l || true)
    text_bytes+=("$(wc -c < "$baseline_file")")
    printf 'q%d\t%d\tkeyword-search\t%s\t%s files / %s matches\t%s\t%s\tunstructured candidate lines\n' \
      "$qnum" "$run" "$elapsed_ms" "$text_files" "$(wc -l < "$baseline_file")" "${text_bytes[-1]}" "$(wc -l < "$baseline_file")" >> "$out/results.tsv"

    if ((run_graph_first != 0)); then
      start_ms=$(date +%s%3N)
      codegraph --no-color explore --path "$repo" "${queries[$i]}" > "$graph_file"
      elapsed_ms=$(( $(date +%s%3N) - start_ms ))
      graph_times+=("$elapsed_ms")
      graph_files=$(rg -o '^\*\*\x60[^\x60]+\x60\*\*' "$graph_file" | wc -l || true)
      graph_symbols=$(sed -n 's/^Found \([0-9][0-9]*\) symbols.*/\1/p' "$graph_file" | head -n1)
      [[ -n "$graph_symbols" ]] || { echo "error: CodeGraph output format did not contain a symbol count" >&2; exit 3; }
      graph_bytes+=("$(wc -c < "$graph_file")")
      printf 'q%d\t%d\tcodegraph_explore\t%s\t%s files / %s symbols\t%s\t%s\trelationship-aware source context\n' \
        "$qnum" "$run" "$elapsed_ms" "$graph_files" "$graph_symbols" "${graph_bytes[-1]}" "$(wc -l < "$graph_file")" >> "$out/results.tsv"
    fi
  done

  printf 'q%d\t%s\t%s\t%s\t%s\n' "$qnum" \
    "$(median "${graph_times[@]}")" "$(median "${text_times[@]}")" \
    "$(median "${graph_bytes[@]}")" "$(median "${text_bytes[@]}")" >> "$out/summary.tsv"
done

printf 'results=%s\nsummary=%s\n' "$out/results.tsv" "$out/summary.tsv"
cat "$out/summary.tsv"
