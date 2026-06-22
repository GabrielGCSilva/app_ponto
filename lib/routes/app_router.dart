import 'package:go_router/go_router.dart';
import '../features/auth/pages/login_page.dart';
import '../features/dashboard/pages/dashboard_page.dart';
import '../features/ponto/pages/registro_ponto_page.dart';
import '../features/relatorios/pages/relatorios_page.dart';
import '../features/configuracoes/pages/configuracoes_page.dart';
import '../features/funcionario/pages/funcionarios_page.dart';
import '../features/funcionario/pages/cadastrar_funcionario_page.dart';
import '../features/funcionario/pages/funcionario_detalhes_page.dart';
import '../features/funcionario_mobile/pages/home_page.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    // 🔥 LOGIN
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),

    // 🔥 MOBILE - FUNCIONÁRIO
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),

    // 🔥 ADMIN - DASHBOARD
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),

    // 🔥 ADMIN - FUNCIONÁRIOS
    GoRoute(
      path: '/funcionarios',
      builder: (context, state) => const FuncionariosPage(),
    ),

    // 🔥 ADMIN - CADASTRAR FUNCIONÁRIO
    GoRoute(
      path: '/cadastrar-funcionario',
      builder: (context, state) => const CadastrarFuncionarioPage(),
    ),

    // 🔥 ADMIN - DETALHES DO FUNCIONÁRIO
    GoRoute(
      path: '/funcionario-detalhes/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return FuncionarioDetalhesPage(funcionarioId: id);
      },
    ),

    // 🔥 ADMIN - REGISTRO DE PONTO
    GoRoute(
      path: '/ponto',
      builder: (context, state) => const RegistroPontoPage(),
    ),

    // 🔥 ADMIN - RELATÓRIOS
    GoRoute(
      path: '/relatorios',
      builder: (context, state) {
        final funcionarioId = state.uri.queryParameters['funcionarioId'] ?? '';
        final mes = int.tryParse(state.uri.queryParameters['mes'] ?? '') ?? DateTime.now().month;
        final ano = int.tryParse(state.uri.queryParameters['ano'] ?? '') ?? DateTime.now().year;
        
        if (funcionarioId.isNotEmpty) {
          return RelatoriosPage(
            funcionarioId: funcionarioId,
            mes: mes,
            ano: ano,
          );
        }
        return const RelatoriosPage();
      },
    ),

    // 🔥 ADMIN - CONFIGURAÇÕES
    GoRoute(
      path: '/configuracoes',
      builder: (context, state) => const ConfiguracoesPage(),
    ),
  ],
);