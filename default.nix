{ lib, flutter }:
flutter.buildFlutterApplication {
  version = "0.0.1";
  pname = "sitzungsverwaltung_gui";
  src = ./.;

  pubspecLock = lib.importJSON ./pubspec.lock.json;
  targetFlutterPlatform = "web";
  flutterBuildFlags = [
    "--release"
    "--dart-define-from-file"
    "config.json"
  ];

  meta = { };
}
