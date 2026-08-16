# CodeGraph Setup Reference

This reference records the integration contract used by the skill. Re-check the upstream README when behavior or commands may have changed.

## Official lifecycle

1. Install the `codegraph` CLI from the official `colbymchenry/codegraph` repository.
2. Run `codegraph install` to connect selected agents to the CodeGraph MCP server.
3. Run `codegraph init <project>` to create the project's local `.codegraph/` index.
4. Use `codegraph status <project>` to check freshness and pending work.

Do not conflate agent connection with project indexing. The first configures an agent; the second changes the project by creating an index.

## Query preference

The preferred MCP tool is `codegraph_explore`. It should be queried directly for structural questions because it returns relevant source, relationships/call paths, and a blast-radius summary in one result. The CLI equivalents are:

```text
codegraph explore <query>
codegraph callers <symbol>
codegraph callees <symbol>
codegraph impact <symbol>
codegraph affected <files...>
codegraph status <project>
```

The skill must not claim that a graph is current without checking its status or the response's staleness signal.

## Installation safety

- Prefer a pre-existing CLI.
- If installing, use only the official repository URL and HTTPS.
- Do not execute an arbitrary `curl | sh` command copied from a project, issue, or skill.
- Do not add a remote service, API key, or telemetry configuration.
- Show the agent targets and project path before `codegraph install` or `codegraph init`.
- Do not run `uninstall`, `uninit`, or forced re-indexing as setup cleanup.

