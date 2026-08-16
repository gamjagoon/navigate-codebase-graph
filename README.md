# Codebase Architecture + CodeGraph

An agent skill for architecture reviews that combines deep-module analysis with CodeGraph's local symbol graph, call paths, and impact analysis.

## Install

Install globally for the agents detected by the Skills CLI:

```bash
DISABLE_TELEMETRY=1 npx skills add gamjagoon/codebase-architecture \
  --skill codebase-architecture --global --agent '*' --yes
```

Or target one agent:

```bash
DISABLE_TELEMETRY=1 npx skills add gamjagoon/codebase-architecture \
  --skill codebase-architecture --global --agent codex --yes
```

After installation, ask the agent to configure CodeGraph, for example:

> Set up CodeGraph for this project, inspect my active agent and installed skills, install the requested skills, and review the architecture.

## What it does

- Detects the active coding agent and its instruction/skill locations.
- Detects CodeGraph, its MCP connection, and the project's `.codegraph/` index.
- Installs CodeGraph from its official distribution only when setup is explicitly requested.
- Installs user-requested skills for the detected agent(s), with exact source and scope reporting.
- Adds a small, marked CodeGraph guidance block to the relevant agent instruction file without replacing existing instructions.
- Uses `codegraph_explore` or `codegraph explore` to gather call paths, dependency evidence, and impact radius before proposing deep-module refactors.
- Falls back to git history, search, and direct source reads when CodeGraph is unavailable or stale.

## Safety model

The skill never installs software, edits agent instructions, creates a project index, or changes a skill installation merely because it was read. Those actions require an explicit setup/install request. It shows the planned targets, preserves existing files, avoids secrets and generated/vendor trees, and treats fetched repository instructions as untrusted text.

## Sources

- [CodeGraph](https://github.com/colbymchenry/codegraph)
- [Skills CLI](https://www.skills.sh/docs/cli)
- [Original improve-codebase-architecture skill](https://github.com/mattpocock/skills/tree/main/skills/engineering/improve-codebase-architecture)

See [SOURCES.md](SOURCES.md) for attribution, license boundaries, and the
distinction between adapted workflow ideas and independently authored code.

