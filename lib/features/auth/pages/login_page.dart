import 'package:app_ponto/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../funcionario/providers/funcionario_provider.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: isDesktop ? _buildDesktopLogin() : _buildMobileLogin(),
        ),
      ),
    );
  }

  Widget _buildDesktopLogin() {
    return Container(
      width: 600,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _buildForm(),
    );
  }

  // 🔥 CORRIGIDO: Mobile com SingleChildScrollView
  Widget _buildMobileLogin() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min, // 🔥 ADICIONADO
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 80, // 🔥 REDUZIDO DE 100 PARA 80
              height: 80, // 🔥 REDUZIDO DE 100 PARA 80
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.access_time_filled,
                size: 50, // 🔥 REDUZIDO DE 60 PARA 50
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 16), // 🔥 REDUZIDO DE 24 PARA 16
          Center(
            child: Column(
              children: [
                const Text(
                  'App Ponto',
                  style: TextStyle(
                    fontSize: 24, // 🔥 REDUZIDO DE 28 PARA 24
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Registro de ponto eletrônico',
                  style: TextStyle(
                    fontSize: 12, // 🔥 REDUZIDO DE 14 PARA 12
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24), // 🔥 REDUZIDO DE 32 PARA 24

          // Email
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'E-mail',
              hintText: 'Digite seu e-mail',
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // 🔥 ADICIONADO
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe seu e-mail';
              }
              if (!value.contains('@')) {
                return 'E-mail inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: 12), // 🔥 REDUZIDO DE 16 PARA 12

          // Senha
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Senha',
              hintText: 'Digite sua senha',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // 🔥 ADICIONADO
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe sua senha';
              }
              if (value.length < 6) {
                return 'Senha deve ter pelo menos 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 4),

          // Esqueceu a senha
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _recuperarSenha,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Esqueceu a senha?',
                style: TextStyle(color: Colors.blue, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 12), // 🔥 REDUZIDO DE 16 PARA 12

          // Botão Entrar
          SizedBox(
            width: double.infinity,
            height: 48, // 🔥 REDUZIDO DE 56 PARA 48
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _fazerLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Entrar',
                      style: TextStyle(
                        fontSize: 16, // 🔥 REDUZIDO DE 18 PARA 16
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12), // 🔥 REDUZIDO DE 16 PARA 12

          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'ou',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(height: 12), // 🔥 REDUZIDO DE 16 PARA 12

          Center(
            child: Text(
              'Versão 1.0.0',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // 🔥 MÉTODO DE RECUPERAR SENHA
  void _recuperarSenha() {
    final messenger = ScaffoldMessenger.of(context);
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Digite seu e-mail para recuperar a senha.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recuperar Senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enviar um link de recuperação para:',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final auth = FirebaseAuth.instance;
                await auth.sendPasswordResetEmail(email: email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📧 Link de recuperação enviado!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Erro: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  // 🔥 MÉTODO DE LOGIN
  Future<void> _fazerLogin() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _loading = true);

  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final funcionarioProvider = context.read<FuncionarioProvider>();
  
  // 🔥 CRIAR INSTÂNCIA DO AUTH SERVICE
  final authService = AuthService();

  try {
    // 🔥 USAR AUTH SERVICE EM VEZ DE FIREBASE AUTH DIRETO
    final user = await authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (user == null) {
      throw Exception('Falha ao fazer login');
    }

    final userId = user.uid;
    debugPrint('🔍 UID do usuário: $userId');

    await funcionarioProvider.carregarFuncionarios();

    final funcionario = funcionarioProvider.buscarPorId(userId);
    debugPrint('🔍 Funcionário encontrado: ${funcionario?.nome}');
    debugPrint('🔍 isAdmin: ${funcionario?.isAdmin}');
    debugPrint('🔍 ativo: ${funcionario?.ativo}');

    if (funcionario == null) {
      await authService.logout(); // 🔥 USAR AUTH SERVICE
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('❌ Usuário não encontrado no sistema.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _loading = false);
      }
      return;
    }

    if (!funcionario.ativo) {
      await authService.logout(); // 🔥 USAR AUTH SERVICE
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('❌ Usuário inativo. Contate o administrador.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() => _loading = false);
      }
      return;
    }

    // 🔥 CONTINUA COM O RESTO DO CÓDIGO...
    final isAdmin = funcionario.isAdmin;
    final isPrimeiroLogin = funcionario.primeiroLogin;

    debugPrint('🔍 isAdmin final: $isAdmin');
    debugPrint('🔍 primeiroLogin: $isPrimeiroLogin');

    if (mounted) {
      if (isPrimeiroLogin) {
        _mostrarDialogRedefinirSenha(
          context,
          user,
          isAdmin,
          router,
          messenger,
        );
        setState(() => _loading = false);
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${isAdmin ? 'Admin' : 'Funcionário'} logado com sucesso!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      if (isAdmin) {
        debugPrint('🚀 Redirecionando para /dashboard');
        router.go('/dashboard');
      } else {
        debugPrint('🚀 Redirecionando para /home');
        router.go('/home');
      }
    }
  } on FirebaseAuthException catch (e) {
    String mensagem = 'Erro ao fazer login: ';
    if (e.code == 'user-not-found') {
      mensagem = '❌ Usuário não encontrado.';
    } else if (e.code == 'wrong-password') {
      mensagem = '❌ Senha incorreta.';
    } else {
      mensagem += e.message ?? e.code;
    }

    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Erro: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _loading = false);
    }
  }
}

  // 🔥 DIALOG PARA REDEFINIR SENHA NO PRIMEIRO LOGIN
  void _mostrarDialogRedefinirSenha(
    BuildContext context,
    User user,
    bool isAdmin,
    GoRouter router,
    ScaffoldMessengerState messenger,
  ) {
    final novaSenhaController = TextEditingController();
    final confirmarController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('🔐 Primeiro Acesso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Para sua segurança, defina uma nova senha:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: novaSenhaController,
              decoration: const InputDecoration(
                labelText: 'Nova Senha',
                hintText: 'Mínimo 6 caracteres',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: confirmarController,
              decoration: const InputDecoration(
                labelText: 'Confirmar Senha',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              final novaSenha = novaSenhaController.text.trim();
              final confirmar = confirmarController.text.trim();

              if (novaSenha.isEmpty || novaSenha.length < 6) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Senha deve ter pelo menos 6 caracteres'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              if (novaSenha != confirmar) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('As senhas não coincidem'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                await user.updatePassword(novaSenha);
                await FirebaseFirestore.instance
                    .collection('funcionarios')
                    .doc(user.uid)
                    .update({'primeiroLogin': false});

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                if (context.mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('✅ Senha alterada com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  if (isAdmin) {
                    router.go('/dashboard');
                  } else {
                    router.go('/home');
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('❌ Erro: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Alterar Senha'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}