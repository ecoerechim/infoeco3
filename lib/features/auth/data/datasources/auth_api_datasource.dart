import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/login_response.dart';
import '../models/register_request.dart';

class AuthApiDatasource {
  final String baseUrl;

  AuthApiDatasource(this.baseUrl);

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Credenciais inválidas');
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
