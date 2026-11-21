
import 'package:flutter/material.dart';
import 'core/app_colors.dart';
import 'features/auth/login_screen.dart';

class AgriMindApp extends StatelessWidget {
  const AgriMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriMind AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.green,
          primary: AppColors.green,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.darkGreen,
          elevation: 0,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
