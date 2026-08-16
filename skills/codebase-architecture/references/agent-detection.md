# Agent and Skill Detection Matrix

Use this as a bounded lookup guide. Prefer runtime/tool context and explicit user statements over filesystem guesses. Paths are examples; only inspect paths that exist and are relevant to the detected agent.

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
| OpenClaw | `skills/` | `~/.openclaw/skills/` | `AGENTS.md`, `openclaw` config |
| Pi | `.pi/skills/` | `~/.pi/agent/skills/` | `AGENTS.md`, `.pi/` |

## Detection procedure

1. Record the agent named by the runtime or user.
2. Check only the matching project/global paths for directories and non-empty `SKILL.md` files.
3. Read instruction-file names and short metadata first; do not bulk-read home directories.
4. If several agents are present, distinguish **active** from **installed**. Install to all agents only when the user explicitly requests all agents.
5. For Codex in WSL, inspect `$CODEX_HOME` separately from `$HOME`; never assume they are the same path.
6. Treat symlinks as installed entries only after resolving them with `readlink -f` and verifying the target exists.

## Instruction update targets

Choose the narrowest applicable target:

1. Existing project instruction file explicitly named by the user.
2. Existing root instruction file for the active agent.
3. Existing agent-specific project rules.
4. A new file only after explicit user approval.

Append a marker-fenced block; never replace the file or normalize unrelated content.

