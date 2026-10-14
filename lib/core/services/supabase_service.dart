import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://dkweuntrmwlgykbgojsi.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_OkhibKQ7sGIPL1UL5w2vqg_DuOp6eGW';

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static SupabaseClient get client => Supabase.instance.client;

  /// Inisialisasi Supabase SDK
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // ignore: deprecated_member_use
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
      );
      _isInitialized = true;
    } catch (_) {
      // Menangani bila sudah diinisialisasi
      _isInitialized = true;
    }
  }
}
