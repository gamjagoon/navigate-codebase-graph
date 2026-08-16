# Agent and Skill Detection Matrix

Use this bounded guide only for setup or explicit agent inspection. Runtime
context and the user's wording are stronger evidence than a file name.

| Agent | Project skill path | Global skill path | Instruction hints |
|---|---|---|---|
| Codex | `.agents/skills/`, `.codex/skills/` | `$CODEX_HOME/skills/` or `~/.codex/skills/` | `AGENTS.md`, `.codex/` |
| Claude Code | `.claude/skills/` | `~/.claude/skills/` | `CLAUDE.md`, `.claude/` |
| Cursor | `.cursor/skills/` | `~/.cursor/skills/` | `.cursor/rules/` |
| GitHub Copilot | `.agents/skills/` | `~/.copilot/skills/` | `.github/copilot-instructions.md` |
| Windsurf | `.windsurf/skills/` | `~/.codeium/windsurf/skills/` | `.windsurf/rules/` |
| Gemini CLI | `.agents/skills/` | `~/.gemini/skills/` | `GEMINI.md`, `.gemini/` |
| OpenCode | `.agents/skills/` | `~/.config/opencode/skills/` | `AGENTS.md`, `opencode.json` |
| Kiro | `.kiro/skills/` | `~/.kiro/skills/` | `.kiro/steering/`, `.kiro/agents/` |
| OpenClaw | `skills/` | `~/.openclaw/skills/` | `AGENTS.md`, OpenClaw config |
| Pi | `.pi/skills/` | `~/.pi/agent/skills/` | `AGENTS.md`, `.pi/` |

## Detection procedure

1. Record the agent named by runtime context or the user.
2. Check only the matching project/global paths that exist.
3. Read file names and short metadata first. Do not bulk-read home directories.
4. Distinguish the active agent from other installed agents.
5. For Codex, inspect `$CODEX_HOME` separately from `$HOME`; never assume they
   are the same path.
6. Resolve symlinks with `readlink -f` before treating them as installed.
7. Use `codegraph help install` as the source of truth for current CodeGraph
   target IDs. Do not fail because this table is older than the CLI.

## Instruction update target

`codegraph install` owns its CodeGraph marker block. Read the files it changed
and do not add a duplicate. Only update an existing marker after the user
explicitly asks for custom guidance and confirms the exact file.
