{ lib, pkgs }:
pkgs.flutter.buildFlutterApplication {
  version = "0.0.1";
  pname = "sitzungsverwaltung_gui";
  src = ./.;
  pubspecLock = lib.importJSON ./pubspec.lock.json;
  meta = { };
}
