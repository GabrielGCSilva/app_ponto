import 'package:flutter/material.dart';
import '../models/funcionario_model.dart';

class FuncionarioProvider extends ChangeNotifier {
  final List<Funcionario> _funcionarios = [];

  List<Funcionario> get funcionarios => _funcionarios;

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

  // MÉTODO ATUALIZADO: agora edita todos os campos
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
    
    if (index != -1) {
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
      );
      
      _funcionarios[index] = funcionarioAtualizado;
      notifyListeners();
    }
  }
}