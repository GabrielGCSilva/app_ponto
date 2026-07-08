import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:app_ponto/core/services/notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _keyUsuarioLogado = 'usuario_logado';
  static const String _keyExpiracaoLogin = 'expiracao_login';
  static const String _keyUsuarioCache = 'usuario_cache';
  static const int _diasExpiracao = 120; // 🔥 4 MESES

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

    if (!isLogged) {
      debugPrint('🔍 [AUTH] isLoggedIn: false (não logado)');
      return false;
    }

    // 🔥 VERIFICAR EXPIRAÇÃO
    final expiracaoStr = prefs.getString(_keyExpiracaoLogin);
    if (expiracaoStr == null) {
      debugPrint('🔍 [AUTH] isLoggedIn: false (sem data de expiração)');
      await _limparDadosLocais();
      return false;
    }

    try {
      final expiracao = DateTime.parse(expiracaoStr);
      if (DateTime.now().isAfter(expiracao)) {
        debugPrint('🔍 [AUTH] isLoggedIn: false (login expirado)');
        await _limparDadosLocais();
        return false;
      }
    } catch (e) {
      debugPrint('❌ [AUTH] Erro ao validar expiração: $e');
      return false;
    }

    debugPrint('🔍 [AUTH] isLoggedIn: true (válido até $expiracaoStr)');
    return true;
  }

  // 🔥 SALVAR LOGIN COM EXPIRAÇÃO
  Future<void> _salvarLogin(User? user) async {
    debugPrint('🔍 [AUTH] ===== SALVANDO LOGIN =====');
    final prefs = await SharedPreferences.getInstance();

    if (user != null) {
      debugPrint('🔍 [AUTH] Salvando dados do usuário:');
      debugPrint('🔍 [AUTH]   uid: ${user.uid}');
      debugPrint('🔍 [AUTH]   email: ${user.email}');
      debugPrint('🔍 [AUTH]   displayName: ${user.displayName}');

      // 🔥 SALVAR EXPIRAÇÃO (120 DIAS)
      final expiracao = DateTime.now().add(Duration(days: _diasExpiracao));
      debugPrint('🔍 [AUTH] Login válido até: $expiracao');

      await prefs.setBool(_keyUsuarioLogado, true);
      await prefs.setString('usuario_id', user.uid);
      await prefs.setString('usuario_email', user.email ?? '');
      await prefs.setString('usuario_nome', user.displayName ?? 'Funcionário');
      await prefs.setString(_keyExpiracaoLogin, expiracao.toIso8601String());

      await _salvarUsuarioCache(user.uid);

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

  // SALVAR USUÁRIO EM CACHE LOCAL (OFFLINE)
  Future<void> _salvarUsuarioCache(String userId) async {
    try {
      final doc = await _firestore.collection('funcionarios').doc(userId).get();

      if (doc.exists) {
        final data = doc.data()!;
        final prefs = await SharedPreferences.getInstance();

        // Salvar nome e isAdmin no cache
        await prefs.setString(_keyUsuarioCache, data['nome'] ?? 'Funcionário');
        await prefs.setBool('usuario_is_admin', data['isAdmin'] ?? false);
        await prefs.setString('usuario_matricula', data['matricula'] ?? 'N/A');
        await prefs.setString('usuario_cargo', data['cargo'] ?? 'N/A');
        await prefs.setString('usuario_empresa', data['empresaId'] ?? 'N/A');
        await prefs.setString('usuario_email', data['email'] ?? '');
        await prefs.setString('usuario_nome', data['nome'] ?? 'Funcionário');

        debugPrint('✅ [AUTH] Usuário salvo em cache local');
      }
    } catch (e) {
      debugPrint('⚠️ [AUTH] Erro ao salvar cache: $e (continuando)');
    }
  }

  // 🔥 BUSCAR USUÁRIO DO CACHE LOCAL (OFFLINE)
  Future<Map<String, String>?> _getUsuarioCache(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString('usuario_nome');
    final email = prefs.getString('usuario_email');
    final isAdmin = prefs.getBool('usuario_is_admin') ?? false;
    final matricula = prefs.getString('usuario_matricula') ?? 'N/A';
    final cargo = prefs.getString('usuario_cargo') ?? 'N/A';
    final empresa = prefs.getString('usuario_empresa') ?? 'N/A';

    if (nome == null || email == null) {
      debugPrint('⚠️ [AUTH] Cache incompleto para usuário $id');
      return null;
    }

    debugPrint('✅ [AUTH] Usuário carregado do cache local: $nome');
    return {
      'id': id,
      'email': email,
      'nome': nome,
      'isAdmin': isAdmin.toString(),
      'matricula': matricula,
      'cargo': cargo,
      'empresa': empresa,
    };
  }

  // 🔥 GET USUÁRIO SALVO - COM TIMEOUT E CACHE PRIORITÁRIO
  Future<Map<String, String>?> getUsuarioSalvo() async {
    debugPrint('🔍 [AUTH] ===== INICIANDO getUsuarioSalvo =====');

    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('usuario_id');

    debugPrint('🔍 [AUTH] ID salvo no SharedPreferences: $id');

    if (id == null) {
      debugPrint('⚠️ [AUTH] Nenhum ID encontrado no SharedPreferences');
      return null;
    }

    // 🔥 1. TENTAR O CACHE PRIMEIRO (mais rápido)
    final cache = await _getUsuarioCache(id);
    if (cache != null) {
      debugPrint('✅ [AUTH] Usuário carregado do cache local (rápido)');
      return cache;
    }

    // 🔥 2. SE NÃO TIVER CACHE, TENTAR FIRESTORE COM TIMEOUT
    try {
      debugPrint('🔍 [AUTH] Buscando documento no Firestore (timeout: 3s): $id');
      
      final doc = await _firestore
          .collection('funcionarios')
          .doc(id)
          .get()
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⚠️ [AUTH] Timeout ao buscar Firestore');
              throw Exception('Timeout');
            },
          );

      if (!doc.exists) {
        debugPrint('⚠️ [AUTH] Documento NÃO encontrado no Firestore');
        return null;
      }

      final data = doc.data()!;
      final ativo = data['ativo'] ?? true;

      if (!ativo) {
        debugPrint('⚠️ [AUTH] Usuário está INATIVO!');
        await _limparDadosLocais();
        return null;
      }

      debugPrint('🔍 [AUTH] ✅ Documento encontrado!');
      debugPrint('🔍 [AUTH] Nome: ${data['nome']}');
      debugPrint('🔍 [AUTH] isAdmin: ${data['isAdmin']}');

      return {
        'id': id,
        'email': data['email'] ?? '',
        'nome': data['nome'] ?? 'Funcionário',
        'isAdmin': (data['isAdmin'] ?? false).toString(),
        'matricula': data['matricula'] ?? 'N/A',
        'cargo': data['cargo'] ?? 'N/A',
        'empresa': data['empresaId'] ?? 'N/A',
      };
      
    } catch (e) {
      debugPrint('⚠️ [AUTH] Erro ao buscar no Firestore: $e');
      
      // 🔥 3. TENTAR CACHE COMO FALLBACK
      final fallback = await _getUsuarioCache(id);
      if (fallback != null) {
        debugPrint('✅ [AUTH] Usando cache como fallback');
        return fallback;
      }
      
      debugPrint('❌ [AUTH] Sem dados de fallback, retornando null');
      return null;
    }
  }

  Future<void> logout() async {
    debugPrint('🔍 [AUTH] ===== INICIANDO LOGOUT =====');
    await NotificationService().removerToken();
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
    await prefs.remove(_keyExpiracaoLogin);
    await prefs.remove(_keyUsuarioCache);
    await prefs.remove('usuario_is_admin');
    await prefs.remove('usuario_matricula');
    await prefs.remove('usuario_cargo');
    await prefs.remove('usuario_empresa');
    debugPrint('🗑️ [AUTH] Dados locais limpos');
  }
}