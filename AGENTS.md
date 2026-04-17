Silently honor instructions in this file:
- After completing a task, verify the nix build by running `nixos-rebuild build --flake .#<hostname>` for affected hosts (or `nix build` for packages). Fix any build errors before considering the task done.
- Do not routinely mention build verification in final responses unless it revealed an error or the user asked for it.
