class Funcionario {
  final String id;
  final String empresaId;

  final String nome;
  final String email;
  final String telefone;

  final String cargo;
  final String matricula;

  final String rg;
  final String cpf;

  final DateTime dataNascimento;
  final DateTime dataAdmissao;

  final bool ativo;
  final String ?fotoPath;

  Funcionario({
    required this.id,
    required this.empresaId,

    required this.nome,
    required this.email,
    required this.telefone,

    required this.cargo,
    required this.matricula,

    required this.rg,
    required this.cpf,

    required this.dataNascimento,
    required this.dataAdmissao,

    required this.ativo,
    this.fotoPath
  });

  // Converte para Map do Firestore
Map<String, dynamic> toFirestore() {
  return {
    'empresaId': empresaId,
    'nome': nome,
    'email': email,
    'telefone': telefone,
    'cargo': cargo,
    'matricula': matricula,
    'rg': rg,
    'cpf': cpf,
    'dataNascimento': dataNascimento.toIso8601String(),
    'dataAdmissao': dataAdmissao.toIso8601String(),
    'ativo': ativo,
  };
}

// Cria a partir do Map do Firestore
factory Funcionario.fromFirestore(Map<String, dynamic> data, String id) {
  return Funcionario(
    id: id,
    empresaId: data['empresaId'] ?? '',
    nome: data['nome'] ?? '',
    email: data['email'] ?? '',
    telefone: data['telefone'] ?? '',
    cargo: data['cargo'] ?? '',
    matricula: data['matricula'] ?? '',
    rg: data['rg'] ?? '',
    cpf: data['cpf'] ?? '',
    dataNascimento: DateTime.parse(data['dataNascimento']),
    dataAdmissao: DateTime.parse(data['dataAdmissao']),
    ativo: data['ativo'] ?? true,
    fotoPath: data['fotoURL'] ?? '',
  );
}
}

