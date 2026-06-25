import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/funcionario_model.dart';

class FuncionarioProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Funcionario> _funcionarios = [];

  List<Funcionario> get funcionarios => _funcionarios;
  List<Funcionario> get funcionariosAtivos =>
      _funcionarios.where((f) => f.ativo).toList();
  List<Funcionario> get funcionariosInativos =>
      _funcionarios.where((f) => !f.ativo).toList();

  // 🔥 NOVO: Verificar se matrícula já existe
  bool matriculaExiste(String matricula, {String? idIgnorar}) {
    return _funcionarios.any((f) =>
        f.matricula == matricula && (idIgnorar == null || f.id != idIgnorar));
  }

  List<Funcionario> buscarTodos({bool? ativo}) {
    if (ativo == null) return _funcionarios;
    return _funcionarios.where((f) => f.ativo == ativo).toList();
  }

  Future<void> carregarFuncionarios() async {
    try {
      debugPrint('📝 [PROVIDER] Buscando funcionários no Firestore...');
      final snapshot = await _firestore.collection('funcionarios').get();
      _funcionarios.clear();
      for (var doc in snapshot.docs) {
        debugPrint('📝 [PROVIDER] Processando documento: ${doc.id}');
        final funcionario = Funcionario.fromFirestore(doc.data(), doc.id);
        _funcionarios.add(funcionario);
      }
      debugPrint('✅ [PROVIDER] Funcionários carregados: ${_funcionarios.length}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [PROVIDER] Erro ao carregar funcionários: $e');
    }
  }

  void adicionar(Funcionario funcionario) {
    _funcionarios.add(funcionario);
    notifyListeners();
  }

  void remover(String id) {
    _funcionarios.removeWhere((f) => f.id == id);
    notifyListeners();
  }

  Funcionario? buscarPorId(String id) {
    try {
      return _funcionarios.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  // 🔥 DESATIVAR
  Future<void> desativar(String id) async {
    final index = _funcionarios.indexWhere((f) => f.id == id);
    if (index == -1) return;

    final f = _funcionarios[index];
    final funcionarioAtualizado = Funcionario(
      id: f.id,
      empresaId: f.empresaId,
      nome: f.nome,
      email: f.email,
      telefone: f.telefone,
      cargo: f.cargo,
      matricula: f.matricula,
      rg: f.rg,
      cpf: f.cpf,
      dataNascimento: f.dataNascimento,
      dataAdmissao: f.dataAdmissao,
      ativo: false,
      fotoPath: f.fotoPath,
      dataExclusao: DateTime.now(),
      isAdmin: f.isAdmin,
    );

    await _firestore.collection('funcionarios').doc(id).update({
      'ativo': false,
      'dataExclusao': DateTime.now().toIso8601String(),
    });

    _funcionarios[index] = funcionarioAtualizado;
    notifyListeners();
  }

  // 🔥 REATIVAR
  Future<void> reativar(String id) async {
    final index = _funcionarios.indexWhere((f) => f.id == id);
    if (index == -1) return;

    final f = _funcionarios[index];
    final funcionarioAtualizado = Funcionario(
      id: f.id,
      empresaId: f.empresaId,
      nome: f.nome,
      email: f.email,
      telefone: f.telefone,
      cargo: f.cargo,
      matricula: f.matricula,
      rg: f.rg,
      cpf: f.cpf,
      dataNascimento: f.dataNascimento,
      dataAdmissao: f.dataAdmissao,
      ativo: true,
      fotoPath: f.fotoPath,
      dataExclusao: null,
      isAdmin: f.isAdmin,
    );

    await _firestore.collection('funcionarios').doc(id).update({
      'ativo': true,
      'dataExclusao': null,
    });

    _funcionarios[index] = funcionarioAtualizado;
    notifyListeners();
  }

  // 🔥 EXCLUIR TOTAL
  Future<void> excluirTotal(String id) async {
    final registros = await _firestore
        .collection('registros_ponto')
        .where('funcionarioId', isEqualTo: id)
        .get();

    final batch = _firestore.batch();
    for (var doc in registros.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection('funcionarios').doc(id));
    await batch.commit();

    _funcionarios.removeWhere((f) => f.id == id);
    notifyListeners();
  }

  // 🔥 VERIFICAR SE PODE BATER PONTO
  bool podeBaterPonto(String id) {
    final funcionario = buscarPorId(id);
    if (funcionario == null) return false;
    return funcionario.ativo;
  }

  void atualizar(
    String id, {
    String? nome,
    String? email,
    String? telefone,
    String? cargo,
    String? matricula,
    String? rg,
    String? cpf,
    DateTime? dataNascimento,
    DateTime? dataAdmissao,
    bool? ativo,
    String? fotoPath,
  }) {
    final index = _funcionarios.indexWhere((f) => f.id == id);
    if (index == -1) return;

    final f = _funcionarios[index];
    final funcionarioAtualizado = Funcionario(
      id: f.id,
      empresaId: f.empresaId,
      nome: nome ?? f.nome,
      email: email ?? f.email,
      telefone: telefone ?? f.telefone,
      cargo: cargo ?? f.cargo,
      matricula: matricula ?? f.matricula,
      rg: rg ?? f.rg,
      cpf: cpf ?? f.cpf,
      dataNascimento: dataNascimento ?? f.dataNascimento,
      dataAdmissao: dataAdmissao ?? f.dataAdmissao,
      ativo: ativo ?? f.ativo,
      fotoPath: fotoPath ?? f.fotoPath,
      dataExclusao: f.dataExclusao,
      isAdmin: f.isAdmin,
    );

    _funcionarios[index] = funcionarioAtualizado;
    notifyListeners();
  }
}