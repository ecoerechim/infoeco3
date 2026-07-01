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
    return LoginResponse(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      nome: json['nome'] ?? '',
      role: json['role'] ?? '',
    );
  }
}
