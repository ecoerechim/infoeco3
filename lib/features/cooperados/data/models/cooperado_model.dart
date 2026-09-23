enum CooperadoStatus { pendente, ativo, inativo }

extension CooperadoStatusExtension on CooperadoStatus {
  String get label {
    switch (this) {
      case CooperadoStatus.pendente:
        return 'Pendente';
      case CooperadoStatus.ativo:
        return 'Ativo';
      case CooperadoStatus.inativo:
        return 'Inativo';
    }
  }

  static CooperadoStatus fromValue(dynamic value) {
    switch ((value ?? '').toString().toLowerCase()) {
      case 'pendente':
      case 'pending':
        return CooperadoStatus.pendente;
      case 'ativo':
      case 'active':
      case 'aprovado':
        return CooperadoStatus.ativo;
      case 'inativo':
      case 'inactive':
      case 'desativado':
        return CooperadoStatus.inativo;
      default:
        return CooperadoStatus.pendente;
    }
  }
}

class CooperadoModel {
  CooperadoModel({
    this.id,
    required this.nome,
    required this.cpf,
    required this.telefone,
    required this.email,
    this.status = CooperadoStatus.pendente,
  });

  final String? id;
  final String nome;
  final String cpf;
  final String telefone;
  final String email;
  final CooperadoStatus status;

  factory CooperadoModel.fromJson(Map<String, dynamic> json) {
    return CooperadoModel(
      id: json['id']?.toString(),
      nome: (json['nome'] ?? '').toString(),
      cpf: (json['cpf'] ?? '').toString(),
      telefone: (json['telefone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      status: CooperadoStatusExtension.fromValue(
        json['status'] ?? json['situacao'] ?? json['statusCooperado'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'cpf': cpf,
      'telefone': telefone,
      'email': email,
      'status': status.name,
    };
  }

  Map<String, dynamic> toCreatePayload() {
    return {
      'nome': nome,
      'cpf': cpf,
      'telefone': telefone,
      'email': email,
      'status': status.name,
    };
  }
}
