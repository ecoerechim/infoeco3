class RegisterRequest {
  final String nome;
  final String email;
  final String password;
  final String role;
  final String documento; // CPF ou CNPJ
  final String telefone;

  RegisterRequest({
    required this.nome,
    required this.email,
    required this.password,
    required this.role,
    required this.documento,
    required this.telefone,
  });

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'email': email,
      'password': password,
      'role': role,
      'documento': documento,
      'telefone': telefone,
    };
  }
}
