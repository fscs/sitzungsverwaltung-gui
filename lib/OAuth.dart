import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:openidconnect/openidconnect.dart';
import 'dart:html';
import 'package:http/http.dart' as http;

class OAuth {
  static Future<String> getToken(BuildContext context) async {
    final cookie = document.cookie!;

    final token = cookie
        .split(";")
        .map((e) => e.trim())
        .where((e) => e.startsWith("refresh_token="))
        .map((e) => e.substring("refresh_token=".length))
        .firstWhere((e) => true, orElse: () => "");

    if (token.isNotEmpty) {
      var res = await http.post(
          Uri.parse("https://auth.inphima.de/application/o/token/"),
          body: {
            "grant_type": "refresh_token",
            "refresh_token": token,
            "client_id": "cZgfgWqx4h1Mn0jhLgUem6vS6m3zFvPwtIcOSyDg",
            "client_secret": "q9J1X7Jz4zq8mF7m8w9vZ2g6s6z4rN1v6z5pC1fP"
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
          clientId: "cZgfgWqx4h1Mn0jhLgUem6vS6m3zFvPwtIcOSyDg",
          redirectUrl: "${Uri.base.origin}/callback.html",
          scopes: ["openid", "profile", "offline_access"],
          configuration: OpenIdConfiguration(
            issuer: "https://auth.inphima.de/application/o/fscs-website/",
            jwksUri: "https://auth.inphima.de/application/o/fscs-website/jwks/",
            authorizationEndpoint:
                "https://auth.inphima.de/application/o/authorize/",
            tokenEndpoint: "https://auth.inphima.de/application/o/token/",
            userInfoEndpoint: "https://auth.inphima.de/application/o/userinfo/",
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
