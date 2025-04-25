{
  lib,
  flutter,
  config ? null,
}:
let
  oldConfig = builtins.fromJSON (lib.readFile ./config.json);
  finalConfig = lib.recursiveUpdate oldConfig config;

  configFile = builtins.toFile "sitzungsverwaltung-config.json" (builtins.toJSON finalConfig);
in
flutter.buildFlutterApplication {
  version = "0.0.1";
  pname = "sitzungsverwaltung";
  src = lib.cleanSourceWith {
    src = ./.;
    filter = name: type: !lib.hasSuffix ".nix" name;
  };

  pubspecLock = lib.importJSON ./pubspec.lock.json;
  targetFlutterPlatform = "web";
  flutterBuildFlags = [
    "--release"
    "--dart-define-from-file"
    "config.json"
  ];

  patchPhase = ''
    rm config.json
    ln -s ${configFile} config.json
  '';

  meta = { };
}
