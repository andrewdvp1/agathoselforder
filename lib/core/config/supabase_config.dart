import 'package:supabase_flutter/supabase_flutter.dart';

/// ============================================================================
/// KONFIGURASI SUPABASE CLOUD (ISI DI SINI AGAR TINGGAL JALANKAN `flutter run`)
/// ============================================================================
/// Ambil nilai di bawah ini dari Supabase Cloud Dashboard:
///   Project Settings -> API -> Project URL & anon/publishable key
///
/// PENTING (Keamanan PRD Bagian 5.2 & 7):
///   - File ini HANYA boleh menyimpan SUPABASE_URL dan SUPABASE_ANON_KEY (publik).
///   - JANGAN PERNAH menaruh SUPABASE_SERVICE_ROLE_KEY, XENDIT_SECRET_KEY,
///     atau XENDIT_WEBHOOK_TOKEN di aplikasi Flutter (simpan di Supabase Cloud Secrets).
class SupabaseConfig {
  // --------------------------------------------------------------------------
  // 1. ISI KREDENSIAL SUPABASE CLOUD ANDA DI 2 BARIS INI:
  // --------------------------------------------------------------------------
  static const String _defaultSupabaseUrl =
      'https://vuybddtdysbvjeddjheg.supabase.co';
  static const String _defaultSupabaseAnonKey =
      'sb_publishable_T5HoUQounOSj6FH2aNNXuw_2wAvznYn';

  // Ubah ke 'production' saat rilis produksi (tetap 'test' untuk Xendit Test Mode)
  static const String _defaultPaymentEnvironment = 'test';

  // --------------------------------------------------------------------------
  // 2. OTOMATIS TERPAKAI SAAT `flutter run` (tetap mendukung override --dart-define)
  // --------------------------------------------------------------------------
  static const String _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String _envPaymentMode =
      String.fromEnvironment('PAYMENT_ENVIRONMENT');

  static String get url =>
      _envUrl.isNotEmpty ? _envUrl : _defaultSupabaseUrl;

  static String get anonKey =>
      _envAnonKey.isNotEmpty ? _envAnonKey : _defaultSupabaseAnonKey;

  static String get paymentEnvironment => _envPaymentMode.isNotEmpty
      ? _envPaymentMode
      : _defaultPaymentEnvironment;

  static const String menuImagesBucket = 'menu-images';

  /// Memastikan URL mengarah ke Supabase Cloud (HTTPS), bukan localhost & bukan placeholder.
  static bool get isCloudUrl {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return false;
    final host = uri.host.toLowerCase();
    if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') {
      return false;
    }
    if (host.contains('your_project_ref') || host.contains('<project_ref>')) {
      return false;
    }
    return true;
  }

  static bool get hasValidAnonKey {
    final key = anonKey.trim();
    if (key.isEmpty) return false;
    if (key.contains('YOUR_SUPABASE') || key.contains('<ANON_KEY>')) {
      return false;
    }
    return true;
  }

  static bool get isConfigured => isCloudUrl && hasValidAnonKey;
  static bool get isTestMode => paymentEnvironment.toLowerCase() == 'test';

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  /// Inisialisasi idempoten Supabase Cloud. Aman dipanggil di `main()` maupun
  /// fallback di `AuthGate` (termasuk setelah Hot Reload).
  static Future<void> ensureInitialized() async {
    if (_initialized || !isConfigured) return;
    await Supabase.initialize(
      url: url,
      publishableKey: anonKey,
    );
    _initialized = true;
  }
}
