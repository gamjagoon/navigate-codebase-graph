# Sources and Attribution

This repository is an independently authored skill package. It contains no
vendored CodeGraph source, no copied third-party binaries, and no bundled
remote installer. It documents integrations with the following projects.

Full third-party notices are collected in [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).

## Architecture workflow

The review workflow and design vocabulary are adapted from the public
`improve-codebase-architecture` skill in:

- Repository: <https://github.com/mattpocock/skills>
- Source skill: <https://github.com/mattpocock/skills/tree/main/skills/engineering/improve-codebase-architecture>
- License: MIT
- Copyright: Matt Pocock, 2026

This package preserves the required MIT attribution for the adapted workflow
but is not an official Matt Pocock release. The CodeGraph setup, agent
detection, skill installation, safety rules, and fallback behavior are new
material in this repository.

## CodeGraph integration

The integration follows the public documentation for:

- Repository: <https://github.com/colbymchenry/codegraph>
- License: MIT
- Copyright: Colby Mchenry, 2026

This package uses documented command and MCP names such as `codegraph init`,
`codegraph status`, and `codegraph_explore`. It does not include CodeGraph
source code or claim to be affiliated with the CodeGraph project.

## Skills CLI documentation

Installation examples reference the public Skills CLI documentation:

- Documentation: <https://www.skills.sh/docs/cli>
- Source repository: <https://github.com/vercel-labs/skills>

No Skills CLI source code is included in this package. The `DISABLE_TELEMETRY`
setting is used in examples so the installer does not opt the user into the
CLI's anonymous telemetry by default.

## License boundary

The original material in this repository is released under the MIT License in
`LICENSE`. The third-party projects above retain their own copyrights and
licenses. Names and links are provided for attribution and interoperability,
not endorsement.
