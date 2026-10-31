{
  description = "Independent Nix packaging for the upstream 1loop desktop and server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    upstream = {
      url = "github:tpm28/1loop/main";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      upstream,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      packagesFor = pkgs: {
        "1loop" = pkgs.callPackage ./nix/package.nix { inherit upstream; };
        "1loop-server" = pkgs.callPackage ./nix/server.nix { inherit upstream; };
      };
    in
    {
      packages = forAllSystems (
        system:
        let
          packages = packagesFor nixpkgs.legacyPackages.${system};
        in
        packages // { default = packages."1loop"; }
      );

      apps = forAllSystems (system: {
        default = self.apps.${system}."1loop";
        "1loop" = {
          type = "app";
          program = "${self.packages.${system}."1loop"}/bin/1loop";
          meta.description = "1loop desktop";
        };
        "1loop-server" = {
          type = "app";
          program = "${self.packages.${system}."1loop-server"}/bin/1loop-server";
          meta.description = "1loop headless server";
        };
      });

      overlays.default = final: _prev: packagesFor final;

      checks = forAllSystems (system: {
        inherit (self.packages.${system}) "1loop" "1loop-server";
      });

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${system}."1loop" ];
            packages = [
              pkgs.gnumake
              pkgs.git
            ];
          };
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
