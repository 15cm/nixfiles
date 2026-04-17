{
  git,
  lib,
  codex,
  writeShellApplication,
}:

writeShellApplication {
  name = "codex-trusted";
  runtimeInputs = [
    git
  ];

  text = ''
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
      root="$(git rev-parse --show-toplevel)"
    else
      root="$PWD"
    fi

    exec ${lib.getExe codex} \
      -C "$root" \
      -c "projects.$root.trust_level=\"trusted\"" \
      "$@"
  '';
}
