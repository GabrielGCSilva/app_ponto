import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _keyUsuarioLogado = 'usuario_logado';

  Future<User?> login(String email, String senha) async {
    try {
      debugPrint('🔍 [AUTH] ===== FAZENDO LOGIN =====');
      debugPrint('🔍 [AUTH] Email: $email');
      
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );
      
      debugPrint('✅ [AUTH] Login bem-sucedido!');
      debugPrint('🔍 [AUTH] UID: ${result.user?.uid}');
      
      await _salvarLogin(result.user);
      return result.user;
    } catch (e) {
      debugPrint('❌ [AUTH] Erro ao fazer login: $e');
      throw Exception('Erro ao fazer login: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLogged = prefs.getBool(_keyUsuarioLogado) ?? false;
    debugPrint('🔍 [AUTH] isLoggedIn: $isLogged');
    return isLogged;
  }

  // 🔥 Salvar login (CORRIGIDO)
  Future<void> _salvarLogin(User? user) async {
    debugPrint('🔍 [AUTH] ===== SALVANDO LOGIN =====');
    final prefs = await SharedPreferences.getInstance();
    
    if (user != null) {
      debugPrint('🔍 [AUTH] Salvando dados do usuário:');
      debugPrint('🔍 [AUTH]   uid: ${user.uid}');
      debugPrint('🔍 [AUTH]   email: ${user.email}');
      debugPrint('🔍 [AUTH]   displayName: ${user.displayName}');
      
      await prefs.setBool(_keyUsuarioLogado, true);
      await prefs.setString('usuario_id', user.uid);
      await prefs.setString('usuario_email', user.email ?? '');
      await prefs.setString('usuario_nome', user.displayName ?? 'Funcionário');
      
      // 🔥 VERIFICAR SE SALVOU
      final testId = prefs.getString('usuario_id');
      debugPrint('🔍 [AUTH] Verificando salvamento: usuario_id = $testId');
      
      if (testId == user.uid) {
        debugPrint('✅ [AUTH] Dados salvos com sucesso!');
      } else {
        debugPrint('❌ [AUTH] Falha ao salvar dados!');
      }
    } else {
      debugPrint('⚠️ [AUTH] User é null, não salvando dados');
      await prefs.setBool(_keyUsuarioLogado, false);
    }
  }

  Future<Map<String, String>?> getUsuarioSalvo() async {
    debugPrint('🔍 [AUTH] ===== INICIANDO getUsuarioSalvo =====');
    
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('usuario_id');
    
    debugPrint('🔍 [AUTH] ID salvo no SharedPreferences: $id');
    debugPrint('🔍 [AUTH] Todas as chaves salvas: ${prefs.getKeys()}');
    
    if (id == null) {
      debugPrint('⚠️ [AUTH] Nenhum ID encontrado no SharedPreferences');
      return null;
    }

    try {
      debugPrint('🔍 [AUTH] Buscando documento no Firestore: $id');
      final doc = await _firestore
          .collection('funcionarios')
          .doc(id)
          .get();

      if (!doc.exists) {
        debugPrint('⚠️ [AUTH] Documento NÃO encontrado no Firestore: $id');
        return null;
      }

      final data = doc.data()!;
      final ativo = data['ativo'] ?? true;

      debugPrint('🔍 [AUTH] ✅ Documento encontrado!');
      debugPrint('🔍 [AUTH] Nome: ${data['nome']}');
      debugPrint('🔍 [AUTH] Email: ${data['email']}');
      debugPrint('🔍 [AUTH] ativo: $ativo');
      debugPrint('🔍 [AUTH] isAdmin: ${data['isAdmin']}');

      if (!ativo) {
        debugPrint('⚠️ [AUTH] Usuário está INATIVO!');
        return null;
      }

      final emailSalvo = prefs.getString('usuario_email') ?? data['email'] ?? '';
      final nomeSalvo = prefs.getString('usuario_nome') ?? data['nome'] ?? 'Funcionário';
      
      debugPrint('🔍 [AUTH] Email salvo: $emailSalvo');
      debugPrint('🔍 [AUTH] Nome salvo: $nomeSalvo');

      return {
        'id': id,
        'email': emailSalvo,
        'nome': nomeSalvo,
      };
      
    } catch (e) {
      debugPrint('❌ [AUTH] ERRO ao verificar usuário: $e');
      
      final emailSalvo = prefs.getString('usuario_email') ?? '';
      final nomeSalvo = prefs.getString('usuario_nome') ?? 'Funcionário';
      
      if (emailSalvo.isNotEmpty) {
        debugPrint('⚠️ [AUTH] Retornando dados do SharedPreferences (fallback)');
        return {
          'id': id,
          'email': emailSalvo,
          'nome': nomeSalvo,
        };
      }
      
      debugPrint('❌ [AUTH] Sem dados de fallback, retornando null');
      return null;
    }
  }

  Future<void> logout() async {
    debugPrint('🔍 [AUTH] ===== INICIANDO LOGOUT =====');
    await _auth.signOut();
    await _limparDadosLocais();
    debugPrint('✅ [AUTH] Logout concluído!');
  }

  Future<void> _limparDadosLocais() async {
    debugPrint('🔍 [AUTH] Limpando dados locais...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsuarioLogado);
    await prefs.remove('usuario_id');
    await prefs.remove('usuario_email');
    await prefs.remove('usuario_nome');
    debugPrint('🗑️ [AUTH] Dados locais limpos');
  }
}