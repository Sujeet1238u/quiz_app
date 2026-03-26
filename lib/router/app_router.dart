// lib/router/app_router.dart
import '../screens/bookmarks_screen.dart';
import '../screens/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/results_screen.dart';
import '../screens/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      // Wait for Firebase session check to complete before redirecting
      if (authState.isInitializing) return null;

      final isAuthenticated = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      // 1. If not logged in, always force login
      if (!isAuthenticated && !isLoginRoute) return '/login';

      // 2. If logged in and trying to go to login, go to dashboard
      if (isAuthenticated && isLoginRoute) return '/dashboard';

      // 3. Otherwise, allow the navigation
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DashboardScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/quiz/:categoryId',
        name: 'quiz',
        pageBuilder: (context, state) {
          final categoryId = state.pathParameters['categoryId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: QuizScreen(categoryId: categoryId),
            transitionsBuilder: _slideTransition,
          );
        },
      ),
      GoRoute(
        path: '/results',
        name: 'results',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ResultsScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ProfileScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HistoryScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/bookmarks',
        name: 'bookmarks',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BookmarksScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
    ],
  );
});


Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic)),
    child: child,
  );
}
