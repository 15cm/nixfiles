#!/usr/bin/env bash
set -euo pipefail

repo_root="$(jj root)"
cd "$repo_root"

jj config set --repo git.fetch '["origin"]'
jj config set --repo git.push origin

printf 'Configured repo-local jj defaults in %s\n' "$repo_root"
