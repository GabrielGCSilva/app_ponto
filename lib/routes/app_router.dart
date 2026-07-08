import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import '../core/services/auth_service.dart';
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

final authService = AuthService();

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    try {
      final isLogged = await authService.isLoggedIn();
      final isLoginRoute = state.matchedLocation == '/login';
      
      debugPrint('🔍 [ROUTER] isLogged: $isLogged, path: ${state.matchedLocation}');
      
      if (!isLogged && !isLoginRoute) {
        debugPrint('🔍 [ROUTER] Redirecionando para /login');
        return '/login';
      }
      
      if (isLogged && isLoginRoute) {
        debugPrint('🔍 [ROUTER] Usuário logado, redirecionando...');
        final usuario = await authService.getUsuarioSalvo();
        final isAdmin = usuario?['isAdmin']?.toString().toLowerCase() == 'true';
        debugPrint('🔍 [ROUTER] isAdmin: $isAdmin');
        return isAdmin ? '/dashboard' : '/home';
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ [ROUTER] Erro no redirect: $e');
      // 🔥 Se der erro, redireciona para login (segurança)
      return '/login';
    }
  },
  
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/funcionarios',
      builder: (context, state) => const FuncionariosPage(),
    ),
    GoRoute(
      path: '/cadastrar-funcionario',
      builder: (context, state) => const CadastrarFuncionarioPage(),
    ),
    GoRoute(
      path: '/funcionario-detalhes/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return FuncionarioDetalhesPage(funcionarioId: id);
      },
    ),
    GoRoute(
      path: '/perfil',
      builder: (context, state) => const PerfilPage(),
    ),
    GoRoute(
      path: '/registro-ponto-admin',
      builder: (context, state) => const RegistroPontoAdminPage(),
    ),
    GoRoute(
      path: '/ponto',
      builder: (context, state) => const RegistroPontoMobilePage(),
    ),
    GoRoute(
      path: '/relatorios',
      builder: (context, state) => const RelatoriosPage(),
    ),
    GoRoute(
      path: '/configuracoes',
      builder: (context, state) => const ConfiguracoesPage(),
    ),
  ],
);