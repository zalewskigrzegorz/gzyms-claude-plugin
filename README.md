# gzyms-claude-plugin

Your Claude Code sessions on the [Gzyms](https://gzyms.dev) bar. You see which one works, which one waits for you and which one is done. When you answer, its notification goes away.

## Install

```sh
claude plugin marketplace add zalewskigrzegorz/gzyms-claude-plugin
claude plugin install gzyms@gzyms
```

The Agents pill in Gzyms reading these sessions comes in the next Gzyms release.

## What it does

Hooks write one small JSON file per session to `~/Library/Application Support/Gzyms/agents/claude/`. The Agents pill in Gzyms reads them.

| Claude Code event | State |
| --- | --- |
| `SessionStart` | `idle` |
| `UserPromptSubmit`, `PreToolUse` | `working` |
| `PermissionRequest`, `Notification` (permission prompt, question) | `waits`, with the question or command |
| `Stop` | `done` |
| `SessionEnd` | file removed |

A file holds the session id, the state and since when, the folder, the Notification text, and the terminal it runs in. It never holds your prompts or Claude's answers. Nothing leaves your Mac.

The hooks run in the background and always exit 0, so they never slow down or stop Claude Code, even when Gzyms is not running.

## Try it from a clone

```sh
claude --plugin-dir ./gzyms-claude-plugin
```

## License

MIT
