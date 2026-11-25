import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  User? get currentAuthUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      if (response.user == null) {
        throw Exception('Gagal masuk. Periksa kembali email dan kata sandi.');
      }
      final profile = await fetchCurrentProfile();
      if (profile == null) {
        throw Exception('Profil pengguna tidak ditemukan di database.');
      }
      return profile;
    } on AuthException catch (e) {
      throw Exception(_friendlyAuthMessage(e.message));
    }
  }

  /// Multi-role registration (user, kasir, admin).
  /// Validates privileged role registration codes server-side via Edge Function
  /// `register-user` (and PostgreSQL trigger `handle_new_user`) with zero orphan records.
  Future<UserProfile> register({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    String? registrationCode,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = fullName.trim();
    final cleanCode = registrationCode?.trim() ?? '';

    try {
      final fnResp = await _client.functions.invoke(
        'register-user',
        body: {
          'full_name': cleanName,
          'email': cleanEmail,
          'password': password,
          'role': role.dbValue,
          'registration_code': cleanCode,
        },
      );

      final data = fnResp.data;
      if (fnResp.status >= 400) {
        final errMsg = data is Map && data['error'] != null
            ? data['error'].toString()
            : 'Registrasi gagal (HTTP ${fnResp.status}).';
        throw Exception(errMsg);
      }

      // Auto sign-in immediately after server-side registration succeeds
      return await signIn(email: cleanEmail, password: password);
    } on FunctionException catch (e) {
      // Extract clean server error message if returned by register-user
      final details = e.details;
      if (details is Map && details['error'] != null) {
        throw Exception(details['error'].toString());
      }
      // Fallback to Supabase Auth signUp if Edge Functions are not yet deployed;
      // PostgreSQL trigger `handle_new_user` STILL enforces registration_code validation.
      if (e.status == 404) {
        return _registerViaDirectSignUp(
          fullName: cleanName,
          email: cleanEmail,
          password: password,
          role: role,
          registrationCode: cleanCode,
        );
      }
      throw Exception(e.reasonPhrase ?? 'Gagal menghubungi layanan registrasi.');
    }
  }

  Future<UserProfile> _registerViaDirectSignUp({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    required String registrationCode,
  }) async {
    try {
      final resp = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role.dbValue,
          'registration_code': registrationCode,
        },
      );
      if (resp.user == null) {
        throw Exception('Registrasi tidak dapat diselesaikan.');
      }
      if (resp.session == null) {
        throw Exception(
          'Registrasi berhasil. Silakan verifikasi email Anda sebelum masuk.',
        );
      }
      final profile = await fetchCurrentProfile();
      if (profile == null) {
        throw Exception('Profil gagal dimuat setelah registrasi.');
      }
      return profile;
    } on AuthException catch (e) {
      throw Exception(_friendlyAuthMessage(e.message));
    }
  }

  Future<UserProfile?> fetchCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select('id, full_name, role, created_at')
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;
    return UserProfile.fromJson(data, email: user.email);
  }

  Future<UserProfile> updateFullName(String newFullName) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Sesi tidak aktif.');

    final cleaned = newFullName.trim();
    if (cleaned.length < 2) {
      throw Exception('Nama lengkap minimal 2 karakter.');
    }

    final updated = await _client
        .from('profiles')
        .update({'full_name': cleaned})
        .eq('id', user.id)
        .select('id, full_name, role, created_at')
        .single();

    return UserProfile.fromJson(updated, email: user.email);
  }

  /// Admin helper: fetch all cashiers to populate filter dropdown in daily reports
  Future<List<UserProfile>> fetchCashiers() async {
    final rows = await _client
        .from('profiles')
        .select('id, full_name, role, created_at')
        .eq('role', 'kasir')
        .order('full_name');

    return (rows as List<dynamic>)
        .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  String _friendlyAuthMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Email atau kata sandi salah.';
    }
    if (lower.contains('already registered') || lower.contains('already exists')) {
      return 'Email sudah terdaftar. Silakan masuk menggunakan akun tersebut.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Email belum terkonfirmasi.';
    }
    if (lower.contains('kode registrasi')) {
      return raw;
    }
    return raw;
  }
}
