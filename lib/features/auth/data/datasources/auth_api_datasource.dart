import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/login_response.dart';
import '../models/register_request.dart';

class AuthApiDatasource {
  final String baseUrl;

  AuthApiDatasource(this.baseUrl);

  Future<LoginResponse> login({
    required String identifier,
    required String password,
  }) async {
    final body = jsonEncode({
      'email': identifier,
      'password': password,
    });
    developer.log('DEBUG: Login Request Body: $body');

    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    developer.log('DEBUG: Login Response Status: ${response.statusCode}');
    developer.log('DEBUG: Login Response Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Erro no login (${response.statusCode}): ${response.body}');
    }

    return LoginResponse.fromJson(
      jsonDecode(response.body),
    );
  }

  Future<void> register(RegisterRequest request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/registrar'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erro ao registrar usuário: ${response.body}');
    }
  }
}
