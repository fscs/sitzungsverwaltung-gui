import 'package:flutter/widgets.dart';
import 'package:openidconnect/openidconnect.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'package:http/http.dart' as http;

class OAuth {
  static final Uri tokenUrl =
      Uri.parse(const String.fromEnvironment("OAUTH_TOKEN_URL"));

  static Future<String> refreshToken() async {
    final cookie = document.cookie!;

    final token = cookie
        .split(";")
        .map((e) => e.trim())
        .where((e) => e.startsWith("refresh_token="))
        .map((e) => e.substring("refresh_token=".length))
        .firstWhere((e) => true, orElse: () => "");

    var res = await http.post(tokenUrl, body: {
      "grant_type": "refresh_token",
      "refresh_token": token,
      "client_id": const String.fromEnvironment("OAUTH_CLIENT_ID"),
      "client_secret": const String.fromEnvironment("OAUTH_CLIENT_SECRET")
    });

    final json = res.body;

    if (res.statusCode != 200) {
      document.cookie = "refresh_token=; path=/";
    }

    final accessToken = json.split('"access_token": "')[1].split('"')[0];

    document.cookie =
        "refresh_token=${json.split('"refresh_token": "')[1].split('"')[0]}; path=/";

    return accessToken;
  }

  static Future<String> getToken(BuildContext context) async {
    final cookie = document.cookie!;

    final token = cookie
        .split(";")
        .map((e) => e.trim())
        .where((e) => e.startsWith("refresh_token="))
        .map((e) => e.substring("refresh_token=".length))
        .firstWhere((e) => true, orElse: () => "");

    if (token.isNotEmpty) {
      var res = await http.post(tokenUrl, body: {
        "grant_type": "refresh_token",
        "refresh_token": token,
        "client_id": const String.fromEnvironment("OAUTH_CLIENT_ID"),
        "client_secret": const String.fromEnvironment("OAUTH_CLIENT_SECRET"),
      });

      final json = res.body;

      if (res.statusCode != 200) {
        document.cookie = "refresh_token=; path=/";

        return getToken(context);
      }

      final accessToken = json.split('"access_token": "')[1].split('"')[0];

      document.cookie =
          "refresh_token=${json.split('"refresh_token": "')[1].split('"')[0]}; path=/";

      return accessToken;
    }

    final response = await OpenIdConnect.authorizeInteractive(
      // ignore: use_build_context_synchronously
      context: context,
      title: "SSO Login",
      request: await InteractiveAuthorizationRequest.create(
          clientId: const String.fromEnvironment("OAUTH_CLIENT_ID"),
          clientSecret: const String.fromEnvironment("OAUTH_CLIENT_SECRET"),
          redirectUrl: "${Uri.base.origin}/callback.html",
          scopes: ["openid", "profile", "offline_access"],
          configuration: OpenIdConfiguration(
            issuer: const String.fromEnvironment("OAUTH_ISSUER_URL"),
            jwksUri: const String.fromEnvironment("OAUTH_JWKS_URL"),
            authorizationEndpoint: const String.fromEnvironment("OAUTH_AUTH_URL"),
            tokenEndpoint: const String.fromEnvironment("OAUTH_TOKEN_URL"),
            userInfoEndpoint: const String.fromEnvironment("OAUTH_USERINFO_URL"),
            requestUriParameterSupported: false,
            document: {
              "response_types_supported": ["code"]
            },
            codeChallengeMethodsSupported: ["plain", "S256"],
            subjectTypesSupported: ["public"],
            idTokenSigningAlgValuesSupported: ["RS256"],
            tokenEndpointAuthMethodsSupported: ["client_secret_post"],
            responseModesSupported: ["query", "fragment", "form_post"],
            responseTypesSupported: ["code"],
          ),
          autoRefresh: true,
          useWebPopup: true,
          additionalParameters: {}),
    );

    document.cookie = "refresh_token=${response!.refreshToken}; path=/";
    document.cookie = "access_token=${response.accessToken}; path=/";

    return response.accessToken;
  }
}
