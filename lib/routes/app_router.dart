import 'package:go_router/go_router.dart';
import '../core/services/auth_service.dart'; // 🔥 ADICIONADO
import '../features/auth/pages/login_page.dart';
import '../features/dashboard/pages/dashboard_page.dart';
import '../features/funcionario_mobile/pages/home_page.dart';
import '../features/funcionario/pages/funcionarios_page.dart';
import '../features/funcionario/pages/cadastrar_funcionario_page.dart';
import '../features/funcionario/pages/funcionario_detalhes_page.dart';
import '../features/funcionario_mobile/pages/registro_ponto_mobile_page.dart';
import '../features/ponto/pages/registro_ponto_admin_page.dart';
import '../features/relatorios/pages/relatorios_page.dart';
import '../features/configuracoes/pages/configuracoes_page.dart';
import '../features/perfil/pages/perfil_page.dart';
import 'package:flutter/foundation.dart';

// 🔥 INSTANCIAR O AUTH SERVICE
final authService = AuthService();

final appRouter = GoRouter(
  initialLocation: '/login',
  
  // 🔥 ADICIONAR O REDIRECT (verificação offline)
  redirect: (context, state) async {
    // 🔥 VERIFICAR LOGIN (usa cache offline)
    final isLogged = await authService.isLoggedIn();
    final isLoginRoute = state.matchedLocation == '/login';
    
    debugPrint('🔍 [ROUTER] isLogged: $isLogged, path: ${state.matchedLocation}');
    
    // 🔥 Se não estiver logado e não estiver na tela de login → vai para login
    if (!isLogged && !isLoginRoute) {
      debugPrint('🔍 [ROUTER] Redirecionando para /login');
      return '/login';
    }
    
    // 🔥 Se estiver logado e estiver na tela de login → redireciona
    if (isLogged && isLoginRoute) {
      debugPrint('🔍 [ROUTER] Usuário logado, redirecionando...');
      final usuario = await authService.getUsuarioSalvo();
      final isAdmin = usuario?['isAdmin']?.toString().toLowerCase() == 'true';
      debugPrint('🔍 [ROUTER] isAdmin: $isAdmin');
      return isAdmin ? '/dashboard' : '/home';
    }
    
    return null;
  },
  
  routes: [
    // LOGIN
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),

    // DASHBOARD
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),

    // HOME (Mobile - Funcionário)
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),

    // FUNCIONÁRIOS
    GoRoute(
      path: '/funcionarios',
      builder: (context, state) => const FuncionariosPage(),
    ),

    // CADASTRO DE FUNCIONARIO  
    GoRoute(
      path: '/cadastrar-funcionario',
      builder: (context, state) => const CadastrarFuncionarioPage(),
    ),

    // DETALHES DO FUNCIONÁRIO
    GoRoute(
      path: '/funcionario-detalhes/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return FuncionarioDetalhesPage(funcionarioId: id);
      },
    ),

    // PERFIL
    GoRoute(
      path: '/perfil',
      builder: (context, state) => const PerfilPage(),
    ),

    // 🔥 PONTO ADMIN
    GoRoute(
      path: '/registro-ponto-admin',
      builder: (context, state) => const RegistroPontoAdminPage(),
    ),

    // PONTO MOBILE (Funcionário)
    GoRoute(
      path: '/ponto',
      builder: (context, state) => const RegistroPontoMobilePage(),
    ),

    // RELATÓRIOS
    GoRoute(
      path: '/relatorios',
      builder: (context, state) => const RelatoriosPage(),
    ),

    // CONFIGURAÇÕES
    GoRoute(
      path: '/configuracoes',
      builder: (context, state) => const ConfiguracoesPage(),
    ),
  ],
);