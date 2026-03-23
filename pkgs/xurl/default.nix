{ lib, rustPlatform, fetchFromGitHub }:

let
  version = "0.0.24";
in
rustPlatform.buildRustPackage {
  pname = "xurl";
  inherit version;

  src = fetchFromGitHub {
    owner = "Xuanwo";
    repo = "xurl";
    rev = "v${version}";
    hash = "sha256-RnGhf5odoD45LMHtVBtAdb/dqF6+7AUQs3EyZSeFbTY=";
  };

  buildAndTestSubdir = "xurl-cli";
  cargoHash = "sha256-AAoiruBie/Pa3tRJUweN35Ve7Q2l1T0qRQsWmi4XZ6g=";

  meta = with lib; {
    description = "CLI for reading and writing AI agent URLs";
    homepage = "https://github.com/Xuanwo/xurl";
    license = licenses.asl20;
    maintainers = [ "i@15cm.net" ];
    mainProgram = "xurl";
    platforms = platforms.linux ++ platforms.darwin;
  };
}
