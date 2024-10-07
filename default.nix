{ pkgs }:
pkgs.flutter.mkFlutterApp {
  version = "0.0.0";
  pname = "test-flutter-app";
  src = ./.;
  meta = { };
}
