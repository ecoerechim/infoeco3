import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
}

class AuthenticatedApiClient {
  AuthenticatedApiClient(this._tokenStorage, {String? baseUrl})
      : _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final TokenStorage _tokenStorage;
  final String _baseUrl;

  Future<http.Response> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _tokenStorage.getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final uri = Uri.parse('$_baseUrl$path');
    final encodedBody = body == null ? null : jsonEncode(body);

    http.Response response;
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response =
              await http.get(uri, headers: headers).timeout(ApiConfig.timeout);
          break;
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: encodedBody)
              .timeout(ApiConfig.timeout);
          break;
        case 'PUT':
          response = await http
              .put(uri, headers: headers, body: encodedBody)
              .timeout(ApiConfig.timeout);
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: headers, body: encodedBody)
              .timeout(ApiConfig.timeout);
          break;
        default:
          throw UnsupportedError('Método HTTP não suportado: $method');
      }
    } on Exception {
      rethrow;
    }

    if (response.statusCode >= 400) {
      throw ApiException(
        response.statusCode,
        _extractMessage(response.body),
      );
    }

    return response;
  }

  dynamic decodeBody(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }
    return jsonDecode(response.body);
  }

  String _extractMessage(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        final map = json;
        if (map.containsKey('message')) return map['message'].toString();
        if (map.containsKey('error')) return map['error'].toString();
      }
      if (json is List) {
        return json.first.toString();
      }
      return body;
    } catch (_) {
      return body;
    }
  }
}
