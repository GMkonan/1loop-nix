{
  lib,
  upstream,
  buildGoModule,
  makeWrapper,
  bash,
  git,
}:
let
  common = import ./common.nix { inherit lib upstream; };
in
buildGoModule (
  common
  // {
    pname = "1loop-server";
    subPackages = [ "cmd/1loop-server" ];
    env.CGO_ENABLED = 0;
    nativeBuildInputs = [ makeWrapper ];

    postFixup = ''
      wrapProgram "$out/bin/1loop-server" \
        --prefix PATH : ${
          lib.makeBinPath [
            bash
            git
          ]
        }
    '';

    meta = common.meta // {
      description = "Headless 1loop coding agent server";
      mainProgram = "1loop-server";
    };
  }
)
