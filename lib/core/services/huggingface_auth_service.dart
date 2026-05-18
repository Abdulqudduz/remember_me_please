import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:remember_me_please/features/llm_model_download/page/constants/constants.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class HuggingFaceAuthService {
  // PKCE Helpers
  String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
  // --------------------

  /// Opens the browser, lets the user log in, and returns the Access Token
  Future<String?> authenticateUser() async {
    try {
      // Generate our PKCE security keys for this specific login attempt
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);

      // Add the PKCE challenge to our Auth URL
      final authUri = Uri.parse(authEndpoint).replace(
        queryParameters: {
          'client_id': hfClientId,
          'redirect_uri': hfRedirectUri,
          'response_type': 'code',
          'scope': scope,
          'code_challenge': codeChallenge,
          'code_challenge_method': 'S256',
        },
      );

      // Open browser and wait for redirect
      final resultUrl = await FlutterWebAuth2.authenticate(
        url: authUri.toString(),
        callbackUrlScheme: 'com.example.rememberme',
      );

      // Extract code
      final code = Uri.parse(resultUrl).queryParameters['code'];

      if (code == null || code.isEmpty) {
        debugPrint('Auth Error: Hugging Face did not return a code.');
        return null;
      }

      // Pass BOTH the code and the secret verifier to the exchange method
      return await _exchangeCodeForToken(code, codeVerifier);
    } catch (e) {
      debugPrint('Auth Exception: $e');
      return null;
    }
  }

  /// Takes the authorization code and POSTs it to Hugging Face to get the real token
  Future<String?> _exchangeCodeForToken(
    String code,
    String codeVerifier,
  ) async {
    final tokenEndpointUrl = Uri.parse(tokenEndpoint);

    final request = http.post(
      tokenEndpointUrl,
      body: {
        'client_id': hfClientId,
        'code': code,
        'redirect_uri': hfRedirectUri,
        'grant_type': 'authorization_code',
        'code_verifier': codeVerifier, // Added the PKCE verifier here!
      },
    );

    final response = await request;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint('SUCCESS! Token received!');
      return data['access_token'];
    } else {
      // If it fails again, this print statement will tell us EXACTLY why!
      debugPrint('Token Exchange Failed!');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      return null;
    }
  }
}
