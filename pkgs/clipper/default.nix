{ lib, buildGoModule, fetchFromGitHub }:

let version = "2.0.0";
in buildGoModule {
  inherit version;
  pname = "clipper";
  postPatch = ''
    go mod init github.com/wincent/clipper
  '';
  vendorHash = null;

  src = fetchFromGitHub {
    owner = "wincent";
    repo = "clipper";
    rev = version;
    hash = "sha256-ktMBzOPtXW4BAJgh/C7OfJVkqF706Psp06WqHIQZE7c";
  };

  meta = with lib; {
    description = "Clipboard access for local and remote tmux sessions ";
    homepage = "https://github.com/wincent/clipper";
    maintainers = [ "i@15cm.net" ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
