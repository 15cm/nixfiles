{
  fetchFromGitHub,
  lib,
  rustPlatform,
  tmuxPlugins,
}:

let
  version = "0.13.0";
  src = fetchFromGitHub {
    owner = "hiroppy";
    repo = "tmux-agent-sidebar";
    tag = "v${version}";
    hash = "sha256-NiqLgMvWbSW3M80ZUWdmmm2VkVqy8eTGcPkrOCsaasI=";
  };
  binary = rustPlatform.buildRustPackage {
    pname = "tmux-agent-sidebar";
    inherit version src;
    cargoHash = "sha256-mOEs2J1o9VeVOXY55r8O52TqoM2GuYU3tVoh5h+yH0s=";
    doCheck = false;

    meta = {
      homepage = "https://github.com/hiroppy/tmux-agent-sidebar";
      description = "Tmux sidebar for monitoring AI coding agents";
      license = lib.licenses.mit;
      mainProgram = "tmux-agent-sidebar";
    };
  };
in
tmuxPlugins.mkTmuxPlugin {
  pluginName = "agent-sidebar";
  inherit version src;
  rtpFilePath = "tmux-agent-sidebar.tmux";

  postInstall = ''
    mkdir -p "$target/bin"
    cp ${binary}/bin/tmux-agent-sidebar "$target/bin/"
  '';

  meta = binary.meta // {
    platforms = lib.platforms.unix;
  };
}
