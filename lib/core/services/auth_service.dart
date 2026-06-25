import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; 

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; 
  static const String _keyUsuarioLogado = 'usuario_logado';

  // 🔥 Fazer login
  Future<User?> login(String email, String senha) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );
      
      await _salvarLogin(result.user);
      return result.user;
    } catch (e) {
      throw Exception('Erro ao fazer login: $e');
    }
  }

  // 🔥 Verificar se está logado
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUsuarioLogado) ?? false;
  }

  // 🔥 Salvar login
  Future<void> _salvarLogin(User? user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUsuarioLogado, user != null);
    if (user != null) {
      await prefs.setString('usuario_id', user.uid);
      await prefs.setString('usuario_email', user.email ?? '');
      await prefs.setString('usuario_nome', user.displayName ?? 'Funcionário');
    }
  }

  // 🔥 Buscar dados do usuário salvo COM VERIFICAÇÃO DE STATUS
  Future<Map<String, String>?> getUsuarioSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('usuario_id');
    if (id == null) return null;
    
    try {
      // 🔥 SOLUÇÃO 3: VERIFICAR NO FIRESTORE SE O USUÁRIO ESTÁ ATIVO
      final doc = await _firestore
          .collection('funcionarios')
          .doc(id)
          .get();

      if (!doc.exists) {
        // 🔥 USUÁRIO NÃO ENCONTRADO - LIMPAR DADOS LOCAIS
        debugPrint('⚠️ [AUTH] Usuário não encontrado no Firestore');
        await _limparDadosLocais();
        return null;
      }

      final data = doc.data()!;
      final ativo = data['ativo'] ?? true;

      if (!ativo) {
        // 🔥 USUÁRIO INATIVO - FORÇAR LOGOUT
        debugPrint('⚠️ [AUTH] Usuário inativo: ${data['nome']}');
        await logout();
        return null;
      }

      debugPrint('✅ [AUTH] Usuário ativo: ${data['nome']}');

      return {
        'id': id,
        'email': prefs.getString('usuario_email') ?? data['email'] ?? '',
        'nome': prefs.getString('usuario_nome') ?? data['nome'] ?? 'Funcionário',
      };
    } catch (e) {
      debugPrint('❌ [AUTH] Erro ao verificar usuário: $e');
      // 🔥 EM CASO DE ERRO, RETORNAR OS DADOS SALVOS (FALLBACK)
      return {
        'id': id,
        'email': prefs.getString('usuario_email') ?? '',
        'nome': prefs.getString('usuario_nome') ?? 'Funcionário',
      };
    }
  }

  // 🔥 Fazer logout
  Future<void> logout() async {
    await _auth.signOut();
    await _limparDadosLocais();
  }

  // 🔥 Limpar dados locais (extraído para reutilização)
  Future<void> _limparDadosLocais() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsuarioLogado);
    await prefs.remove('usuario_id');
    await prefs.remove('usuario_email');
    await prefs.remove('usuario_nome');
    debugPrint('🗑️ [AUTH] Dados locais limpos');
  }
}