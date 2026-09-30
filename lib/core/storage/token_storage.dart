import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _tokenKey = 'access_token';

  Future<void> saveToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, trimmed);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.trim().isEmpty) {
      return null;
    }
    return token.trim();
  }

  /// Checks if the provided token string is an expired JWT token.
  static bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        // Not a standard 3-part JWT, treat non-empty opaque string as non-expired
        return false;
      }

      String normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      switch (normalized.length % 4) {
        case 2:
          normalized += '==';
          break;
        case 3:
          normalized += '=';
          break;
      }

      final payloadString = utf8.decode(base64.decode(normalized));
      final Map<String, dynamic> payload = jsonDecode(payloadString);

      if (payload.containsKey('exp')) {
        final exp = payload['exp'];
        if (exp is num) {
          final expirationDate =
              DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
          // Add 5 second buffer for clock skew
          return DateTime.now().add(const Duration(seconds: 5)).isAfter(expirationDate);
        }
      }
      return false;
    } catch (_) {
      return true;
    }
  }

  /// Checks if the stored token exists and is not expired.
  Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null) return false;
    return !isTokenExpired(token);
  }

  /// Returns the stored token if valid, or clears and returns null if expired or missing.
  Future<String?> getValidToken() async {
    final token = await getToken();
    if (token == null) return null;

    if (isTokenExpired(token)) {
      await clear();
      return null;
    }

    return token;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
