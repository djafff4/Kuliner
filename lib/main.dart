import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/main_layout.dart';
import 'features/settings/providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase Backend
  // ignore: deprecated_member_use
  await Supabase.initialize(
    url: SupabaseService.supabaseUrl,
    // ignore: deprecated_member_use
    anonKey: SupabaseService.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: PosKulinerApp(),
    ),
  );
}

class PosKulinerApp extends ConsumerWidget {
  const PosKulinerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'POS Kuliner - Aplikasi Kasir UMKM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const MainLayout(),
    );
  }
}
