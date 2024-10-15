import 'package:flutter/widgets.dart';
import 'package:openidconnect/openidconnect.dart';
import 'dart:html';

class OAuth {
  static Future<String> getToken(BuildContext context) async {
    final cookie = document.cookie!;

    final token = cookie
        .split(";")
        .map((e) => e.trim())
        .where((e) => e.startsWith("access_token="))
        .map((e) => e.substring("access_token=".length))
        .firstWhere((e) => true, orElse: () => "");

    // if (token.isNotEmpty) {
    //   return token;
    // }

    final response = await OpenIdConnect.authorizeInteractive(
      // ignore: use_build_context_synchronously
      context: context,
      title: "SSO Login",
      request: await InteractiveAuthorizationRequest.create(
          clientId: "cZgfgWqx4h1Mn0jhLgUem6vS6m3zFvPwtIcOSyDg",
          redirectUrl: "${Uri.base.origin}/callback.html",
          scopes: ["openid", "profile"],
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

    document.cookie = "access_token=${response!.accessToken}; path=/;";

    return response!.accessToken;
  }
}
