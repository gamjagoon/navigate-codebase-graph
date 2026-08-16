# CodeGraph Setup Reference

Use this file only when the user explicitly asks for CodeGraph installation,
agent connection, project indexing, or status inspection. Re-check the
upstream README when commands or supported agents may have changed.

## Official lifecycle

1. Check for an existing `codegraph` binary and run `codegraph version`.
2. Use `codegraph help install` to discover the current target IDs.
3. After confirmation, connect the selected agent with an explicit target and
   location:

   ```text
   codegraph install --target=<verified-agent-id> --location=<global-or-local> --yes --no-permissions
   ```

4. After a restart, initialize only an explicitly approved project:

   ```text
   codegraph init <absolute-project-root>
   codegraph status <absolute-project-root>
   ```

Agent connection and project indexing are different writes. Never combine
them into one unreviewed action.

## Review-time commands

```text
codegraph explore --path <project> <query>
codegraph node <symbol-or-file>
codegraph callers <symbol>
codegraph callees <symbol>
codegraph impact <symbol>
codegraph affected <files...>
codegraph status <project>
```

The MCP surface may expose only `codegraph_explore` by default. Use the MCP
tool directly for structural questions when it is available. If there is no
index, use normal repository tools and report that graph evidence is absent.

## Freshness

Do not call an index current merely because `.codegraph/` exists. Record the
status output and any staleness banner returned by the query. Re-run the query
or read the named source directly when the result is stale or conflicts with
the current source.

## Installation safety

- Prefer an existing CLI.
- Use only the official CodeGraph distribution and HTTPS.
- Download an installer to a temporary file and inspect it before execution.
- Never execute an unexamined `curl | sh` or `irm | iex` command.
- Do not add a remote service, API key, permission wildcard, or telemetry
  configuration.
- Show target, scope, project path, changed files, and reversal before every
  write.
- Do not run `uninstall`, `uninit`, forced re-indexing, or cleanup as setup.

## Primary source

<https://github.com/colbymchenry/codegraph>
