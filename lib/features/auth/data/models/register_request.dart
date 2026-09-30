class RegisterRequest {
  final String nome;
  final String email;
  final String password;
  final String role;
  final String documento; // CPF ou CNPJ
  final String telefone;
  final String? prefeituraNome;
  final String? prefeituraId;

  RegisterRequest({
    required this.nome,
    required this.email,
    required this.password,
    required this.role,
    required this.documento,
    required this.telefone,
    this.prefeituraNome,
    this.prefeituraId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'nome': nome,
      'email': email,
      'password': password,
      'role': role.toUpperCase(),
      'documento': documento,
      'telefone': telefone,
    };

    if (prefeituraNome != null && prefeituraNome!.trim().isNotEmpty) {
      map['prefeituraNome'] = prefeituraNome!.trim();
      map['nomePrefeitura'] = prefeituraNome!.trim();
    }
    if (prefeituraId != null && prefeituraId!.trim().isNotEmpty) {
      map['prefeituraId'] = prefeituraId!.trim();
    }

    return map;
  }
}
