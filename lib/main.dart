import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/main_shell.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES');
  final token = await AuthService.getToken();
  runApp(SunflowerApp(isAuthenticated: token != null));
}

class SunflowerApp extends StatelessWidget {
  final bool isAuthenticated;
  const SunflowerApp({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SUNFLOWER ERP',
      theme: AppTheme.light,
      home: isAuthenticated ? const MainShell() : const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
