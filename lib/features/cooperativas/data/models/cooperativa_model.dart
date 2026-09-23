enum CooperativaStatus { pendente, ativa, inativa, rejeitada }

extension CooperativaStatusExtension on CooperativaStatus {
  String get label {
    switch (this) {
      case CooperativaStatus.pendente:
        return 'Pendente';
      case CooperativaStatus.ativa:
        return 'Ativa';
      case CooperativaStatus.inativa:
        return 'Inativa';
      case CooperativaStatus.rejeitada:
        return 'Rejeitada';
    }
  }

  static CooperativaStatus fromValue(dynamic value) {
    switch ((value ?? '').toString().toLowerCase()) {
      case 'pendente':
        return CooperativaStatus.pendente;
      case 'ativa':
      case 'active':
      case 'ativo':
        return CooperativaStatus.ativa;
      case 'inativa':
      case 'inactive':
      case 'inativo':
        return CooperativaStatus.inativa;
      case 'rejeitada':
      case 'rejeitado':
        return CooperativaStatus.rejeitada;
      default:
        return CooperativaStatus.pendente;
    }
  }
}

class CooperativaModel {
  CooperativaModel({
    this.id,
    required this.nome,
    required this.cnpj,
    required this.email,
    required this.telefone,
    required this.endereco,
    this.status = CooperativaStatus.pendente,
  });

  final String? id;
  final String nome;
  final String cnpj;
  final String email;
  final String telefone;
  final String endereco;
  final CooperativaStatus status;

  factory CooperativaModel.fromJson(Map<String, dynamic> json) {
    return CooperativaModel(
      id: json['id']?.toString(),
      nome: (json['nome'] ?? '').toString(),
      cnpj: (json['cnpj'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      telefone: (json['telefone'] ?? '').toString(),
      endereco: (json['endereco'] ?? '').toString(),
      status: CooperativaStatusExtension.fromValue(
        json['status'] ?? json['situacao'] ?? json['statusCooperativa'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'cnpj': cnpj,
      'email': email,
      'telefone': telefone,
      'endereco': endereco,
      'status': status.name,
    };
  }

  Map<String, dynamic> toCreatePayload() {
    return {
      'nome': nome,
      'cnpj': cnpj,
      'email': email,
      'telefone': telefone,
      'endereco': endereco,
      'status': status.name,
    };
  }
}
