import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/application/auth_controller.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/auth/presentation/onboarding_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/shell/home_shell.dart';

/// Routeur global. Redirige selon l'état d'authentification :
///  - inconnu    → splash
///  - connecté   → /home
///  - déconnecté → /onboarding (avec /login, /register accessibles)
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier<AuthStatus>(AuthStatus.unknown);
  ref.onDispose(notifier.dispose);

  ref.listen<AuthState>(authControllerProvider, (_, next) {
    notifier.value = next.status;
  });

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, _) => const HomeShell()),
    ],
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final loc = state.matchedLocation;

      if (status == AuthStatus.unknown) {
        return loc == '/splash' ? null : '/splash';
      }
      if (status == AuthStatus.authenticated) {
        // Connecté : on quitte les écrans d'auth.
        const authScreens = {'/splash', '/onboarding', '/login', '/register'};
        return authScreens.contains(loc) ? '/home' : null;
      }
      // Déconnecté : accès aux écrans d'auth uniquement.
      const allowed = {'/onboarding', '/login', '/register'};
      return allowed.contains(loc) ? null : '/onboarding';
    },
  );
});
