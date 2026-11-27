import 'package:flutter/material.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseConfig.ensureInitialized();
  } catch (e) {
    debugPrint('Supabase init warning (will retry in AuthGate): $e');
  }

  runApp(const GlassPosQrApp());
}

class GlassPosQrApp extends StatelessWidget {
  const GlassPosQrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlassPOS QR — Self Order & Kasir QRIS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const AuthGate(),
    );
  }
}
