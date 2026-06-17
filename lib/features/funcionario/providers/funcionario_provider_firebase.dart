import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/funcionario_model.dart';
import 'dart:io';

class FuncionarioProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  List<Funcionario> _funcionarios = [];
  bool _carregando = false;
  String? _erro;

  List<Funcionario> get funcionarios => _funcionarios;
  bool get carregando => _carregando;
  String? get erro => _erro;

  // 🔥 Carregar funcionários do Firestore
  Future<void> carregarFuncionarios() async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('funcionarios').get();
      _funcionarios = snapshot.docs.map((doc) {
        return Funcionario.fromFirestore(doc.data(), doc.id);
      }).toList();
      
      _carregando = false;
      notifyListeners();
    } catch (e) {
      _carregando = false;
      _erro = e.toString();
      notifyListeners();
      debugPrint('❌ Erro ao carregar funcionários: $e');
    }
  }

  // 🔥 Adicionar funcionário
  Future<void> adicionar(Funcionario funcionario) async {
    try {
      // 1. Upload da foto se existir
      String? fotoURL;
      if (funcionario.fotoPath != null && funcionario.fotoPath!.isNotEmpty) {
        try {
          final ref = _storage.ref().child('funcionarios/${funcionario.id}.jpg');
          final file = File(funcionario.fotoPath!);
          await ref.putFile(file);
          fotoURL = await ref.getDownloadURL();
        } catch (e) {
          debugPrint('❌ Erro no upload da foto: $e');
          // Continua mesmo sem foto
        }
      }

      // 2. Salvar no Firestore
      final dados = funcionario.toFirestore();
      if (fotoURL != null) {
        dados['fotoURL'] = fotoURL;
      }
      
      await _firestore.collection('funcionarios').doc(funcionario.id).set(dados);
      
      // 3. Atualizar lista local
      _funcionarios.add(funcionario);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erro ao adicionar funcionário: $e');
      rethrow;
    }
  }

  // 🔥 Atualizar funcionário
  Future<void> atualizar(Funcionario funcionario) async {
    try {
      final dados = funcionario.toFirestore();
      await _firestore.collection('funcionarios').doc(funcionario.id).update(dados);
      
      final index = _funcionarios.indexWhere((f) => f.id == funcionario.id);
      if (index != -1) {
        _funcionarios[index] = funcionario;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Erro ao atualizar funcionário: $e');
      rethrow;
    }
  }

  // 🔥 Remover funcionário
  Future<void> remover(String id) async {
    try {
      await _firestore.collection('funcionarios').doc(id).delete();
      _funcionarios.removeWhere((f) => f.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erro ao remover funcionário: $e');
      rethrow;
    }
  }

  // 🔥 Buscar por ID
  Funcionario? buscarPorId(String id) {
    try {
      return _funcionarios.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }
}