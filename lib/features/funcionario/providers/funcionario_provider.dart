import 'package:flutter/material.dart';

import '../models/funcionario_model.dart';

class FuncionarioProvider extends ChangeNotifier {

  final List<Funcionario> _funcionarios = [];

  List<Funcionario> get funcionarios => _funcionarios;

  void adicionar(Funcionario funcionario) {

    _funcionarios.add(funcionario);

    notifyListeners();
  }
}