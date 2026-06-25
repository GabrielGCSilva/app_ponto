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

  Widget _buildMobileLogin() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.access_time_filled,
                size: 60,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                const Text(
                  'App Ponto',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Registro de ponto eletrônico',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Email
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'E-mail',
              hintText: 'Digite seu e-mail',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
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
          const SizedBox(height: 16),

          // Senha
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Senha',
              hintText: 'Digite sua senha',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
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
          const SizedBox(height: 8),

          // Esqueceu a senha
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _recuperarSenha,
              child: const Text(
                'Esqueceu a senha?',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Botão Entrar
          SizedBox(
            width: double.infinity,
            height: 56,
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'ou',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(height: 16),

          Center(
            child: Text(
              'Versão 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ),
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

  // 🔥 MÉTODO DE LOGIN COM PRIMEIRO LOGIN + VERIFICAÇÃO DE USUÁRIO ATIVO
  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // 🔥 Guardar referências ANTES do async
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final funcionarioProvider = context.read<FuncionarioProvider>();

    try {
      final auth = FirebaseAuth.instance;
      final userCredential = await auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userId = userCredential.user!.uid;
      debugPrint('🔍 UID do usuário: $userId');

      // 🔥 FORÇAR RECARREGAMENTO DO FIRESTORE
      await funcionarioProvider.carregarFuncionarios();

      // 🔥 VERIFICAR SE O FUNCIONÁRIO FOI CARREGADO
      final funcionario = funcionarioProvider.buscarPorId(userId);
      debugPrint('🔍 Funcionário encontrado: ${funcionario?.nome}');
      debugPrint('🔍 isAdmin: ${funcionario?.isAdmin}');
      debugPrint('🔍 ativo: ${funcionario?.ativo}');

      // 🔥 SOLUÇÃO 2: VERIFICAR SE O USUÁRIO ESTÁ ATIVO
      if (funcionario == null) {
        // 🔥 USUÁRIO NÃO ENCONTRADO NO FIRESTORE
        await auth.signOut();
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
        // 🔥 USUÁRIO INATIVO - FORÇAR LOGOUT
        await auth.signOut();
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

      final isAdmin = funcionario.isAdmin;
      final isPrimeiroLogin = funcionario.primeiroLogin;

      debugPrint('🔍 isAdmin final: $isAdmin');
      debugPrint('🔍 primeiroLogin: $isPrimeiroLogin');

      if (mounted) {
        // 🔥 SE FOR PRIMEIRO LOGIN, PEDIR REDEFINIÇÃO DE SENHA
        if (isPrimeiroLogin) {
          _mostrarDialogRedefinirSenha(
            context,
            userCredential.user!,
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

        // 🔥 Redirecionar conforme permissão
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
              // 🔥 Guardar referências ANTES do async
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
                // 🔥 ATUALIZAR SENHA NO FIREBASE AUTH
                await user.updatePassword(novaSenha);

                // 🔥 ATUALIZAR FLAG DE PRIMEIRO LOGIN NO FIRESTORE
                await FirebaseFirestore.instance
                    .collection('funcionarios')
                    .doc(user.uid)
                    .update({'primeiroLogin': false});

                // 🔥 Fechar dialog
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                // 🔥 Mostrar feedback
                if (context.mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('✅ Senha alterada com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // 🔥 Redirecionar conforme permissão
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