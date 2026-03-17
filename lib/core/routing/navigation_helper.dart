import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_routes.dart';

/// Navigation helper extension for easier navigation
extension NavigationExtension on BuildContext {
  // Push navigation
  void pushNamed(String route) => GoRouter.of(this).push(route);
  
  // Replace navigation
  void goNamed(String route) => GoRouter.of(this).go(route);
  
  // Pop navigation
  void pop() => GoRouter.of(this).pop();
  
  // Can pop check
  bool canPop() => GoRouter.of(this).canPop();
  
  // Specific route navigations
  void goToSplash() => go(AppRoutes.splash);
  void goToOnboarding() => go(AppRoutes.onboarding);
  void goToLogin() => go(AppRoutes.login);
  void goToRegister() => go(AppRoutes.register);
  void goToHome() => go(AppRoutes.home);
}

