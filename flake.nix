{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };
  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      lib = nixpkgs.lib;

      forAllSystems = lib.genAttrs systems;
      devShell =
        system:
        let
          pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        in
        {
          default =
            with pkgs;
            mkShell {
              nativeBuildInputs = [
                pkgs.flutter
                pkgs.google-chrome
              ];
              shellHook = ''
                export CHROME_EXECUTABLE="${pkgs.google-chrome}/bin/google-chrome-stable"
              '';
            };
        };
    in
    {
      nixpkgs.config.allowUnfree = true;
      devShells = forAllSystems devShell;
    };
}
