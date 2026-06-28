// app_routes.dart
import 'package:home_security/screens/HomeScreen/home_screen.dart';
import 'package:home_security/screens/SettingsScreen/settings_screen.dart';
import 'package:home_security/screens/login_screen.dart';
import 'package:home_security/screens/reset_password_screen.dart';
import 'package:home_security/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:home_security/screens/splash_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const SplashScreen(),
  '/home': (context) => const HomeScreen(),
  '/signup': (context) => const SignUpScreen(),
  '/login': (context) => const LoginScreen(),
  '/settings': (context) => const SettingsScreen(),
  '/reset_password': (context) => const ResetPasswordScreen(),
};

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String signup = '/signup';
  static const String login = '/login';
  static const String settings = '/settings';
  static const String resetPassword = '/reset_password';
}
