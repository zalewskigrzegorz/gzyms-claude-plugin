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

A file holds the session id, the state and since when, the folder, the terminal it runs in, and the session's title. While Claude waits, it also holds the question Claude asks you or the command it wants to run. It holds no other text from the conversation.

The title can be your own words. Claude Desktop names a session after your first message, so "fix the login bug" becomes the title. In a terminal the title is Claude's own summary of the task.

The plugin sends nothing anywhere, it only writes these files. Gzyms shows the title and the question on the bar and on its banners. If you turned on phone pings in Gzyms, they go to your phone too.

The hooks run in the background and always exit 0, so they never slow down or stop Claude Code, even when Gzyms is not running.

## Try it from a clone

```sh
claude --plugin-dir ./gzyms-claude-plugin
```

## License

MIT
