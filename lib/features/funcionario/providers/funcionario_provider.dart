import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/funcionario_model.dart';

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
    // Evitar múltiplas chamadas simultâneas
    if (_carregando) return;
    
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      debugPrint('📝 [PROVIDER] Buscando funcionários no Firestore...');
      final snapshot = await _firestore.collection('funcionarios').get();
      debugPrint('✅ [PROVIDER] Documentos encontrados: ${snapshot.docs.length}');
      
      _funcionarios = snapshot.docs.map((doc) {
        debugPrint('📝 [PROVIDER] Processando documento: ${doc.id}');
        return Funcionario.fromFirestore(doc.data(), doc.id);
      }).toList();
      
      _carregando = false;
      notifyListeners();
      debugPrint('✅ [PROVIDER] Funcionários carregados: ${_funcionarios.length}');
    } catch (e, stackTrace) {
      _carregando = false;
      _erro = e.toString();
      notifyListeners();
      debugPrint('❌ [PROVIDER] Erro ao carregar: $e');
      debugPrint('📚 [PROVIDER] StackTrace: $stackTrace');
    }
  }

  // 🔥 Buscar funcionário por ID
  Funcionario? buscarPorId(String id) {
    try {
      return _funcionarios.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  // 🔥 Adicionar funcionário (COM MAIS LOGS E TRATAMENTO)
  Future<void> adicionar(Funcionario funcionario) async {
    debugPrint('📝 [PROVIDER] ===== INICIANDO CADASTRO =====');
    debugPrint('📝 [PROVIDER] Nome: ${funcionario.nome}');
    debugPrint('📝 [PROVIDER] ID: ${funcionario.id}');
    debugPrint('📝 [PROVIDER] FotoPath: ${funcionario.fotoPath}');
    
    try {
      // 1. Upload da foto se existir
      String? fotoURL;
      if (funcionario.fotoPath != null && funcionario.fotoPath!.isNotEmpty) {
        debugPrint('📸 [PROVIDER] Iniciando upload da foto...');
        try {
          final ref = _storage.ref().child('funcionarios/${funcionario.id}.jpg');
          final file = File(funcionario.fotoPath!);
          await ref.putFile(file);
          fotoURL = await ref.getDownloadURL();
          debugPrint('✅ [PROVIDER] Foto enviada com sucesso! URL: $fotoURL');
        } catch (e) {
          debugPrint('⚠️ [PROVIDER] Erro no upload da foto (continuando): $e');
        }
      } else {
        debugPrint('📸 [PROVIDER] Nenhuma foto para upload');
      }

      // 2. Salvar no Firestore
      debugPrint('📝 [PROVIDER] Preparando dados para o Firestore...');
      final dados = funcionario.toFirestore();
      debugPrint('📝 [PROVIDER] Dados: $dados');
      
      if (fotoURL != null) {
        dados['fotoURL'] = fotoURL;
        debugPrint('📝 [PROVIDER] Adicionando fotoURL ao Firestore');
      }
      
      debugPrint('📝 [PROVIDER] Chamando Firestore.set()...');
      try {
        await _firestore
            .collection('funcionarios')
            .doc(funcionario.id)
            .set(dados)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw Exception('Timeout ao salvar no Firestore');
              },
            );
        debugPrint('✅ [PROVIDER] Firestore salvou com sucesso!');
      } catch (firestoreError) {
        debugPrint('❌ [PROVIDER] Erro específico do Firestore: $firestoreError');
        rethrow;
      }

      // 3. Adicionar à lista local
      debugPrint('📝 [PROVIDER] Atualizando lista local...');
      final funcionarioCompleto = Funcionario(
        id: funcionario.id,
        empresaId: funcionario.empresaId,
        nome: funcionario.nome,
        email: funcionario.email,
        telefone: funcionario.telefone,
        cargo: funcionario.cargo,
        matricula: funcionario.matricula,
        rg: funcionario.rg,
        cpf: funcionario.cpf,
        dataNascimento: funcionario.dataNascimento,
        dataAdmissao: funcionario.dataAdmissao,
        ativo: funcionario.ativo,
        fotoPath: fotoURL ?? funcionario.fotoPath,
      );
      
      _funcionarios.add(funcionarioCompleto);
      notifyListeners();
      debugPrint('✅ [PROVIDER] Lista local atualizada! Total: ${_funcionarios.length}');
      debugPrint('📝 [PROVIDER] ===== CADASTRO CONCLUÍDO COM SUCESSO =====');
      
    } catch (e, stackTrace) {
      debugPrint('❌ [PROVIDER] ===== ERRO NO CADASTRO =====');
      debugPrint('❌ [PROVIDER] Erro: $e');
      debugPrint('📚 [PROVIDER] StackTrace: $stackTrace');
      rethrow;
    }
  }

  // 🔥 Atualizar funcionário
  Future<void> atualizar(Funcionario funcionario) async {
    try {
      debugPrint('📝 [PROVIDER] Atualizando: ${funcionario.nome}');
      
      // 1. Verificar se precisa fazer upload de nova foto
      String? fotoURL;
      if (funcionario.fotoPath != null && 
          funcionario.fotoPath!.isNotEmpty && 
          funcionario.fotoPath!.startsWith('/')) {
        try {
          final ref = _storage.ref().child('funcionarios/${funcionario.id}.jpg');
          final file = File(funcionario.fotoPath!);
          await ref.putFile(file);
          fotoURL = await ref.getDownloadURL();
          debugPrint('✅ [PROVIDER] Foto atualizada com sucesso!');
        } catch (e) {
          debugPrint('⚠️ [PROVIDER] Erro no upload da foto (continuando): $e');
        }
      }

      // 2. Preparar dados para atualização
      final dados = funcionario.toFirestore();
      if (fotoURL != null) {
        dados['fotoURL'] = fotoURL;
      } else if (funcionario.fotoPath != null && 
                 funcionario.fotoPath!.isNotEmpty && 
                 funcionario.fotoPath!.startsWith('http')) {
        dados['fotoURL'] = funcionario.fotoPath;
      }
      
      // 3. Atualizar no Firestore
      await _firestore.collection('funcionarios').doc(funcionario.id).update(dados);
      debugPrint('✅ [PROVIDER] Funcionário atualizado no Firestore: ${funcionario.nome}');

      // 4. Atualizar lista local
      final index = _funcionarios.indexWhere((f) => f.id == funcionario.id);
      if (index != -1) {
        _funcionarios[index] = funcionario;
        notifyListeners();
        debugPrint('✅ [PROVIDER] Lista local atualizada!');
      }
      
    } catch (e) {
      debugPrint('❌ [PROVIDER] Erro ao atualizar: $e');
      rethrow;
    }
  }

  // 🔥 Remover funcionário
  Future<void> remover(String id) async {
    try {
      debugPrint('📝 [PROVIDER] Removendo funcionário ID: $id');
      
      await _firestore.collection('funcionarios').doc(id).delete();
      debugPrint('✅ [PROVIDER] Funcionário removido do Firestore');

      _funcionarios.removeWhere((f) => f.id == id);
      notifyListeners();
      debugPrint('✅ [PROVIDER] Lista local atualizada! Total: ${_funcionarios.length}');
      
    } catch (e) {
      debugPrint('❌ [PROVIDER] Erro ao remover: $e');
      rethrow;
    }
  }
}