# AGENTS.md

When the user asks for a VCS commit, generate the commit message yourself and proceed with the commit using that message.
When detecting version control in a workspace, use Git conventions by default.

## Skills

### obsidian-cli

Use the `obsidian` CLI to interact with a running Obsidian instance. Requires Obsidian to be open.

Run `obsidian help` to see all available commands. Full docs: https://help.obsidian.md/cli

Common operations:

```bash
obsidian read file="My Note"
obsidian create name="New Note" content="# Hello" silent
obsidian append file="My Note" content="New line"
obsidian search query="search term" limit=10
obsidian daily:read
obsidian daily:append content="- [ ] New task"
obsidian property:set name="status" value="done" file="My Note"
```

- `file=<name>` — wikilink-style resolution; `path=<path>` — exact path from vault root
- `vault=<name>` as first param to target a specific vault
- `--copy` copies output to clipboard; `silent` prevents files from opening
