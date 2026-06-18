import 'package:app_ponto/features/funcionario/pages/cadastrar_funcionario_page.dart';
import 'package:app_ponto/features/funcionario/pages/funcionario_detalhes_page.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/pages/login_page.dart';
import '../features/dashboard/pages/dashboard_page.dart';
import '../features/ponto/pages/registro_ponto_page.dart';
import '../features/relatorios/pages/relatorios_page.dart';
import '../features/configuracoes/pages/configuracoes_page.dart';
import '../features/funcionario/pages/funcionarios_page.dart';


final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // LOGIN
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
    ),

    // DASHBOARD
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
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

    // DETALHES DO FUNCIONÁRIO - USANDO GoRoute com parâmetro
    GoRoute(
      path: '/funcionario-detalhes/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return FuncionarioDetalhesPage(funcionarioId: id);
      },
    ),

    // PONTO
    GoRoute(
      path: '/ponto',
      builder: (context, state) => const RegistroPontoPage(),
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