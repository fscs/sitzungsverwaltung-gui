{
  description = "Flutter development shell using Nix flakes";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.flutter
          ];
          shellHook = ''
            export CHROME_EXECUTABLE="${pkgs.chromium}/bin/chromium"
          '';
        };
        packages.default = nixpkgs.legacyPackages.${system}.callPackage ./default.nix { };
      });
}

