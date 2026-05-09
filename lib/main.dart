import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES');
  runApp(const SunflowerApp());
}

class SunflowerApp extends StatelessWidget {
  const SunflowerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SUNFLOWER ERP',
      theme: AppTheme.light,
      home: const MainShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}
