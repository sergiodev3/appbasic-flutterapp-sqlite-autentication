import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/views/auth/login_screen.dart';
import '../../presentation/views/auth/register_screen.dart';
import '../../presentation/views/checklist/checklist_detail_screen.dart';
import '../../presentation/views/home/home_screen.dart';
import '../../presentation/views/start/start_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authViewModelProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const StartScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'checklist/:groupId',
            builder: (context, state) {
              final groupId = int.parse(state.pathParameters['groupId']!);
              return ChecklistDetailScreen(groupId: groupId);
            },
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isLoading = authState.status == AuthStatus.initial || authState.status == AuthStatus.loading;
      final isProtected = state.matchedLocation.startsWith('/home');
      final isAuthScreen = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (isLoading) {
        return null;
      }

      // The router enforces the auth boundary so the UI can stay focused on rendering state.
      if (!isAuthenticated && isProtected) {
        return '/';
      }

      if (isAuthenticated && (state.matchedLocation == '/' || isAuthScreen)) {
        return '/home';
      }

      return null;
    },
  );
});