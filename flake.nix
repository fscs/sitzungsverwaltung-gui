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
          CHROME_EXECUTABLE = "chromium";
          JAVA_HOME = pkgs.jdk21.home;
          FLUTTER_ROOT = pkgs.flutter;
          DART_ROOT = "${pkgs.flutter}/bin/cache/dart-sdk";
          QT_QPA_PLATFORM = "wayland;xcb"; # emulator related: try using wayland, otherwise fall back to X
          # NB: due to the emulator's bundled qt version, it currently does not start with QT_QPA_PLATFORM="wayland".
          # Maybe one day this will be supported.
          buildInputs = with pkgs;[
            flutter
            gradle
            jdk21
            protobuf
            buf
            pandoc
            libsecret.dev
            gtk3.dev
            grpcurl
            pkg-config
            chromium
          ];
          # emulator related: vulkan-loader and libGL shared libs are necessary for hardware decoding
          LD_LIBRARY_PATH = "/run/opengl-driver/lib:/run/opengl-driver-32/lib";
          CMAKE_PREFIX_PATH = "${pkgs.lib.makeLibraryPath [pkgs.libsecret.dev pkgs.gtk3.dev]}";
          # Globally installed packages, which are installed through `dart pub global activate package_name`,
          # are located in the `$PUB_CACHE/bin` directory.
          shellHook = ''
            if [ -z "$PUB_CACHE" ]; then
              export PATH="$PATH:$HOME/.pub-cache/bin"
            else
              export PATH="$PATH:$PUB_CACHE/bin"
            fi

            dart pub global activate protoc_plugin
          '';
        };
        packages.default = nixpkgs.legacyPackages.${system}.callPackage ./default.nix { };
      });
}

