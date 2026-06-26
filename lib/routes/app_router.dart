import 'package:go_router/go_router.dart';
import '../features/auth/pages/login_page.dart';
import '../features/dashboard/pages/dashboard_page.dart';
import '../features/funcionario_mobile/pages/home_page.dart';
import '../features/funcionario/pages/funcionarios_page.dart';
import '../features/funcionario/pages/cadastrar_funcionario_page.dart';
import '../features/funcionario/pages/funcionario_detalhes_page.dart';
import '../features/funcionario_mobile/pages/registro_ponto_mobile_page.dart'; // ✅ CORRETO
import '../features/relatorios/pages/relatorios_page.dart';
import '../features/configuracoes/pages/configuracoes_page.dart';
import '../features/perfil/pages/perfil_page.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
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

    // HOME (Mobile)
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

    // PONTO
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