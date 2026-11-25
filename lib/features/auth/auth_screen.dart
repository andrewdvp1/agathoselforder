import 'package:flutter/material.dart';
import '../../core/config/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_buttons.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glass_scaffold.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  final ValueChanged<UserProfile> onAuthenticated;

  const AuthScreen({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  bool _isRegisterMode = false;
  UserRole _selectedRole = UserRole.user;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _errorMessage;

  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _regCodeCtrl = TextEditingController();

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _regCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final UserProfile profile;
      if (_isRegisterMode) {
        profile = await _authService.register(
          fullName: _fullNameCtrl.text,
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          role: _selectedRole,
          registrationCode: _selectedRole == UserRole.user
              ? null
              : _regCodeCtrl.text,
        );
      } else {
        profile = await _authService.signIn(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
      }
      if (!mounted) return;
      widget.onAuthenticated(profile);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassScaffold(
      showTertiaryOrb: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: GlassContainer(
                tier: GlassTier.level2,
                borderRadius: 20,
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Brand Header
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              color: AppColors.primaryTonal,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'GlassPOS QR',
                                  style: theme.textTheme.headlineMedium,
                                ),
                                Text(
                                  SupabaseConfig.isTestMode
                                      ? 'Self-Order & Kasir • Xendit Test Mode'
                                      : 'Self-Order & Kasir QRIS',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.secondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Login / Register Switch Pill
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceInput,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.borderGlassSubtle),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _ModeTab(
                                label: 'Masuk',
                                selected: !_isRegisterMode,
                                onTap: () => setState(() {
                                  _isRegisterMode = false;
                                  _errorMessage = null;
                                }),
                              ),
                            ),
                            Expanded(
                              child: _ModeTab(
                                label: 'Daftar Akun',
                                selected: _isRegisterMode,
                                onTap: () => setState(() {
                                  _isRegisterMode = true;
                                  _errorMessage = null;
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.statusRejectedBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.errorLight,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.errorTonal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_isRegisterMode) ...[
                        // Segmented Role Pill: User / Kasir / Admin
                        Text(
                          'Pilih Peran Akun',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: UserRole.values.map((role) {
                            final active = _selectedRole == role;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: role == UserRole.admin ? 0 : 8,
                                ),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      _selectedRole = role;
                                      _errorMessage = null;
                                    }),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 160),
                                      height: 44,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: active
                                            ? AppColors.primaryTonal
                                            : AppColors.surfaceInput,
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: active
                                              ? AppColors.primary
                                              : AppColors.borderGlassInput,
                                        ),
                                      ),
                                      child: Text(
                                        role == UserRole.user
                                            ? 'User'
                                            : role.label,
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                          color: active
                                              ? AppColors.primaryOnTonal
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Full Name
                        TextFormField(
                          controller: _fullNameCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap',
                            hintText: 'Masukkan nama lengkap Anda',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (v) {
                            if (!_isRegisterMode) return null;
                            if (v == null || v.trim().length < 2) {
                              return 'Nama lengkap wajib diisi (min. 2 karakter)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Email
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'nama@email.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                          if (!regex.hasMatch(value)) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Password
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        textInputAction: _isRegisterMode
                            ? TextInputAction.next
                            : TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!_isRegisterMode) _submit();
                        },
                        decoration: InputDecoration(
                          labelText: 'Kata Sandi',
                          hintText: 'Minimal 8 karakter',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.length < 8) {
                            return 'Kata sandi minimal 8 karakter';
                          }
                          return null;
                        },
                      ),

                      if (_isRegisterMode) ...[
                        const SizedBox(height: 14),
                        // Confirm Password
                        TextFormField(
                          controller: _confirmPasswordCtrl,
                          obscureText: _obscureConfirm,
                          textInputAction: _selectedRole == UserRole.user
                              ? TextInputAction.done
                              : TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Konfirmasi Kata Sandi',
                            hintText: 'Ulangi kata sandi',
                            prefixIcon: const Icon(Icons.lock_reset_rounded),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (!_isRegisterMode) return null;
                            if (v != _passwordCtrl.text) {
                              return 'Konfirmasi kata sandi tidak cocok';
                            }
                            return null;
                          },
                        ),

                        // Dynamic Registration Code field for Kasir / Admin
                        if (_selectedRole != UserRole.user) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _regCodeCtrl,
                            textInputAction: TextInputAction.done,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText:
                                  'Kode Registrasi ${_selectedRole.label}',
                              hintText: _selectedRole == UserRole.kasir
                                  ? 'Contoh: KASIR-DEV-2026'
                                  : 'Contoh: ADMIN-DEV-2026',
                              prefixIcon: const Icon(
                                Icons.vpn_key_outlined,
                                color: AppColors.tertiaryLight,
                              ),
                              helperText:
                                  'Divalidasi di sisi server untuk mencegah akses tidak sah.',
                            ),
                            validator: (v) {
                              if (!_isRegisterMode ||
                                  _selectedRole == UserRole.user) {
                                return null;
                              }
                              if (v == null || v.trim().isEmpty) {
                                return 'Kode registrasi ${_selectedRole.label} wajib diisi';
                              }
                              return null;
                            },
                          ),
                        ],
                      ],

                      const SizedBox(height: 22),

                      GlassPrimaryButton(
                        label: _isRegisterMode
                            ? 'Daftar sebagai ${_selectedRole.label}'
                            : 'Masuk Sekarang',
                        icon: _isRegisterMode
                            ? Icons.person_add_alt_1_rounded
                            : Icons.login_rounded,
                        loading: _loading,
                        onPressed: _submit,
                      ),

                      if (SupabaseConfig.isTestMode) ...[
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderGlassSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Akun Seeding Dev (Password: Password123!)',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.tertiaryLight,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _QuickFillChip(
                                    label: 'User 1',
                                    onTap: () => _fillDemo('user1@app.test'),
                                  ),
                                  _QuickFillChip(
                                    label: 'Kasir 1',
                                    onTap: () => _fillDemo('kasir1@app.test'),
                                  ),
                                  _QuickFillChip(
                                    label: 'Admin',
                                    onTap: () => _fillDemo('admin@app.test'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _fillDemo(String email) {
    setState(() {
      _isRegisterMode = false;
      _emailCtrl.text = email;
      _passwordCtrl.text = 'Password123!';
      _errorMessage = null;
    });
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
          ),
        ),
      ),
    );
  }
}

class _QuickFillChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickFillChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primaryTonal,
                  fontSize: 11,
                ),
          ),
        ),
      ),
    );
  }
}
