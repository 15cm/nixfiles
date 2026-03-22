# `jj` Workflow For `/nixfiles`

This repo uses `jj` as the standard interface to the underlying Git repository and GitHub remote. The repo stays colocated, so both `.git` and `.jj` exist in the checkout.

## Clone And Initialize

```bash
jj git clone --colocate git@github.com:15cm/nixfiles.git /nixfiles
cd /nixfiles
./bootstrap/jj-init-repo.sh
```

For fresh machines that do not have `jj` yet, install Nix first and then run:

```bash
nix shell nixpkgs#jujutsu -c jj git clone --colocate git@github.com:15cm/nixfiles.git /nixfiles
```

## Standard Daily Flow

Start from the current trunk:

```bash
jj git fetch
jj new main
```

Check what changed:

```bash
jj status
jj log
jj diff
```

Record work:

```bash
jj commit -m "module: short summary"
```

Split or rewrite when needed:

```bash
jj split
jj squash
```

## Review Branches With Named Bookmarks

Create a bookmark only when you are ready to publish work to GitHub:

```bash
jj bookmark create my-topic -r @-
jj git push --allow-new
```

Update an existing review branch after more changes:

```bash
jj commit -m "module: follow-up"
jj bookmark move my-topic --to @-
jj git push --bookmark my-topic
```

If you rewrite commits under an existing bookmark, `jj git push --bookmark my-topic` behaves like a safe force-push with lease checks.

## Updating From Remote

`jj` does not use `git pull` as the standard sync flow. Fetch first, then rebase your current work onto trunk:

```bash
jj git fetch
jj rebase -d main
```

To inspect someone else’s published work:

```bash
jj new their-bookmark@origin
```

## What Stays Git-Compatible

- GitHub remains the canonical remote.
- `origin` remains the default remote.
- Read-only Git commands are fine when they are convenient.
- Avoid mutating the repo with Git unless you are intentionally using Git as an escape hatch.

Because this is a colocated repo, Git-aware tools still see `.git`. `jj` will often leave Git in a detached `HEAD` state, which is expected.

## Command Mapping

| Git habit | `jj` command |
| --- | --- |
| `git status` | `jj status` |
| `git log --graph` | `jj log` |
| `git diff` | `jj diff` |
| `git switch -c feature` | `jj new main` then `jj bookmark create feature -r @-` when publishing |
| `git commit` | `jj commit -m ...` |
| `git pull --rebase` | `jj git fetch` then `jj rebase -d main` |
| `git push -u origin feature` | `jj bookmark create feature -r @-` then `jj git push --allow-new` |
