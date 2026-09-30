class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final String nome;
  final String role;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.nome,
    required this.role,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final token = (json['accessToken'] ?? json['token'] ?? '').toString();
    final refreshToken =
        (json['refreshToken'] ?? json['refresh_token'] ?? '').toString();
    final role = (json['role'] ?? '').toString().toLowerCase();

    return LoginResponse(
      accessToken: token,
      refreshToken: refreshToken,
      nome: (json['nome'] ?? json['name'] ?? '').toString(),
      role: role,
    );
  }
}
