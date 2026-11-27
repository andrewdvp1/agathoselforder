import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_buttons.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glass_scaffold.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../admin/admin_shell.dart';
import '../kasir/kasir_shell.dart';
import '../user/user_shell.dart';
import 'auth_screen.dart';

/// Role-based AuthGate: routes signed-in accounts automatically to User, Kasir, or Admin shell.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthService? _authService;
  StreamSubscription<AuthState>? _authSub;

  UserProfile? _profile;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (SupabaseConfig.isConfigured) {
      _bootstrapSupabaseAndSession();
    } else {
      _loading = false;
    }
  }

  Future<void> _bootstrapSupabaseAndSession() async {
    try {
      await SupabaseConfig.ensureInitialized();
      if (!mounted) return;
      _authService = AuthService();
      await _loadCurrentSession();
      _authSub = _authService!.onAuthStateChange.listen((state) {
        if (state.event == AuthChangeEvent.signedOut) {
          if (mounted) {
            setState(() {
              _profile = null;
              _loading = false;
              _loadError = null;
            });
          }
        } else if (state.event == AuthChangeEvent.signedIn ||
            state.event == AuthChangeEvent.tokenRefreshed) {
          _loadCurrentSession();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError =
            'Gagal menginisialisasi koneksi Supabase Cloud: ${e.toString().replaceFirst('Exception: ', '')}';
        _loading = false;
      });
    }
  }

  Future<void> _loadCurrentSession() async {
    final service = _authService;
    if (service == null) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final profile = await service.fetchCurrentProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured) {
      return const _SupabaseSetupNoticeScreen();
    }

    if (_loading) {
      return GlassScaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.accentTerracotta),
              const SizedBox(height: 16),
              Text(
                'Memuat sesi & peran pengguna...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_loadError != null && _profile == null) {
      return GlassScaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: GlassContainer(
                tier: GlassTier.level2,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.semanticErrorSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_off_rounded,
                        size: 32,
                        color: AppColors.semanticError,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Gagal Memuat Profil',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    GlassPrimaryButton(
                      label: 'Coba Lagi',
                      icon: Icons.refresh_rounded,
                      onPressed: _loadCurrentSession,
                    ),
                    const SizedBox(height: 10),
                    GlassOutlinedButton(
                      label: 'Keluar',
                      expand: true,
                      onPressed: () async {
                        await _authService?.signOut();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final profile = _profile;
    if (profile == null) {
      return AuthScreen(
        onAuthenticated: (loaded) {
          setState(() => _profile = loaded);
        },
      );
    }

    // Strict Role-Based Routing
    switch (profile.role) {
      case UserRole.user:
        return UserShell(
          profile: profile,
          onProfileUpdated: (p) => setState(() => _profile = p),
        );
      case UserRole.kasir:
        return KasirShell(
          profile: profile,
          onProfileUpdated: (p) => setState(() => _profile = p),
        );
      case UserRole.admin:
        return AdminShell(
          profile: profile,
          onProfileUpdated: (p) => setState(() => _profile = p),
        );
    }
  }
}

class _SupabaseSetupNoticeScreen extends StatelessWidget {
  const _SupabaseSetupNoticeScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassScaffold(
      showTertiaryOrb: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: GlassContainer(
                tier: GlassTier.level2,
                borderRadius: 20,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.semanticWarningSoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.settings_ethernet_rounded,
                            color: AppColors.statusPendingText,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Konfigurasi Supabase Cloud Diperlukan',
                            style: theme.textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Isi SUPABASE_URL dan SUPABASE_ANON_KEY dari Supabase Cloud Dashboard (Project Settings → API) langsung di file konfigurasi berikut agar Anda cukup menjalankan `flutter run` tanpa flag tambahan:',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bgCanvasDeep,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: const SelectableText(
                        'File: lib/core/config/supabase_config.dart\n\n'
                        'static const String _defaultSupabaseUrl =\n'
                        '    \'https://<PROJECT_REF>.supabase.co\';\n'
                        'static const String _defaultSupabaseAnonKey =\n'
                        '    \'<ANON_OR_PUBLISHABLE_KEY_ANDA>\';\n\n'
                        'Setelah diisi, cukup jalankan:\n'
                        'flutter run',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Catatan keamanan: XENDIT_SECRET_KEY dan XENDIT_WEBHOOK_TOKEN tidak disimpan di Flutter, melainkan di Supabase Cloud Secrets via skrip supabase/deploy_cloud.ps1.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
