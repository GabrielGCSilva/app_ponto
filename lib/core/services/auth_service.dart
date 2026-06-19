import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
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

  // 🔥 Buscar dados do usuário salvo
  Future<Map<String, String>?> getUsuarioSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('usuario_id');
    if (id == null) return null;
    
    return {
      'id': id,
      'email': prefs.getString('usuario_email') ?? '',
      'nome': prefs.getString('usuario_nome') ?? 'Funcionário',
    };
  }

  // 🔥 Fazer logout
  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsuarioLogado);
    await prefs.remove('usuario_id');
    await prefs.remove('usuario_email');
    await prefs.remove('usuario_nome');
  }
}