import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/injection.dart';
import '../../core/network/transaction_realtime_service.dart';
import '../../core/widgets/adaptive_scaffold.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/bloc/dashboard_bloc.dart';
import '../../features/dashboard/bloc/dashboard_event.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/reports/bloc/reports_bloc.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/settings/bloc/settings_bloc.dart';
import '../../features/settings/bloc/settings_event.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/transactions/bloc/transaction_bloc.dart';
import '../../features/transactions/bloc/transaction_event.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import '../../features/users/bloc/user_bloc.dart';
import '../../features/users/bloc/user_event.dart';
import '../../features/users/presentation/users_screen.dart';

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    refreshListenable: _GoRouterAuthNotifier(authBloc),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuthenticated = authState is AuthAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoginRoute) return '/login';
      if (isAuthenticated && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) {
          return _ShellScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => BlocProvider(
              create: (_) => DashboardBloc(
                getIt<UserRepository>(),
                getIt<TransactionRepository>(),
              )..add(const LoadDashboard()),
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => BlocProvider(
              create: (_) =>
                  UserBloc(getIt<UserRepository>())..add(const LoadUsers()),
              child: const UsersScreen(),
            ),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => BlocProvider(
              create: (_) => TransactionBloc(
                getIt<TransactionRepository>(),
                getIt<UserRepository>(),
                getIt<TransactionRealtimeService>(),
              )..add(const LoadTransactions()),
              child: const TransactionsScreen(),
            ),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => BlocProvider(
              create: (_) => ReportsBloc(
                getIt<TransactionRepository>(),
                getIt<UserRepository>(),
              ),
              child: const ReportsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => BlocProvider(
              create: (_) => SettingsBloc(
                getIt<SettingsRepository>(),
                getIt<AuthRepository>(),
              )..add(const LoadSettings()),
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}

class _ShellScaffold extends StatefulWidget {
  final Widget child;

  const _ShellScaffold({required this.child});

  @override
  State<_ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<_ShellScaffold> {
  int _currentIndex = 0;

  static const _routes = [
    '/dashboard',
    '/users',
    '/transactions',
    '/reports',
    '/settings',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).matchedLocation;
    final index = _routes.indexOf(location);
    if (index != -1 && index != _currentIndex) {
      _currentIndex = index;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      currentIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() => _currentIndex = index);
        context.go(_routes[index]);
      },
      body: widget.child,
    );
  }
}

// Notifier that converts AuthBloc stream to a Listenable for GoRouter
class _GoRouterAuthNotifier extends ChangeNotifier {
  _GoRouterAuthNotifier(AuthBloc authBloc) {
    authBloc.stream.listen((_) => notifyListeners());
  }
}
