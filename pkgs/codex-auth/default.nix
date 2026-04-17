{ stdenv, lib, fetchurl, autoPatchelfHook, glibc }:

let
  version = "0.2.5";
in stdenv.mkDerivation {
  pname = "codex-auth";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@loongphy/codex-auth-linux-x64/-/codex-auth-linux-x64-${version}.tgz";
    hash = "sha256-nvg9WsEl1dE136rgpiauYi6kUkKYUvRY+kku9jLGxP4=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ glibc ];

  unpackPhase = ''
    tar xzf $src
  '';

  installPhase = ''
    install -Dm755 package/bin/codex-auth $out/bin/codex-auth
  '';

  meta = with lib; {
    description = "Switch between multiple Codex accounts without restarting client";
    homepage = "https://github.com/loongphy/codex-auth";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "codex-auth";
  };
}
