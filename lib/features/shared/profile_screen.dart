import 'package:flutter/material.dart';
import '../../core/config/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_buttons.dart';
import '../../core/widgets/glass_container.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile profile;
  final ValueChanged<UserProfile> onProfileUpdated;

  const ProfileScreen({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  late final TextEditingController _nameCtrl;
  bool _saving = false;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.fullName);
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.fullName != widget.profile.fullName) {
      _nameCtrl.text = widget.profile.fullName;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    setState(() => _saving = true);
    try {
      final updated = await _authService.updateFullName(_nameCtrl.text);
      if (!mounted) return;
      widget.onProfileUpdated(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama profil berhasil diperbarui.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await _authService.signOut();
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppColors.tertiaryLight;
      case UserRole.kasir:
        return AppColors.secondaryLight;
      case UserRole.user:
        return AppColors.primaryTonal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleColor = _roleColor(widget.profile.role);

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Profil & Sesi Akun', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  'Kelola nama tampilan akun Anda. Hak akses peran dikunci oleh server.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                GlassContainer(
                  tier: GlassTier.level1,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: roleColor.withValues(alpha: 0.2),
                            child: Text(
                              widget.profile.fullName.isNotEmpty
                                  ? widget.profile.fullName[0].toUpperCase()
                                  : 'U',
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(color: roleColor),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.profile.fullName,
                                  style: theme.textTheme.titleLarge,
                                ),
                                if (widget.profile.email != null)
                                  Text(
                                    widget.profile.email!,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                              border:
                                  Border.all(color: roleColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              widget.profile.role.label.toUpperCase(),
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(color: roleColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      GlassPrimaryButton(
                        label: 'Simpan Nama',
                        icon: Icons.save_rounded,
                        loading: _saving,
                        onPressed: _saveName,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassContainer(
                  tier: GlassTier.level1,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'Terdaftar Sejak',
                        value: AppFormatters.dateTimeWib(widget.profile.createdAt),
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        label: 'Payment Gateway',
                        value: SupabaseConfig.isTestMode
                            ? 'Xendit (Test Mode / Sandbox)'
                            : 'Xendit (Production)',
                      ),
                      const SizedBox(height: 10),
                      const _InfoRow(
                        label: 'Zona Waktu Operasional',
                        value: 'Asia/Jakarta (WIB)',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GlassOutlinedButton(
                  label: _signingOut ? 'Keluar...' : 'Keluar dari Akun',
                  icon: Icons.logout_rounded,
                  isDestructive: true,
                  expand: true,
                  onPressed: _signingOut ? null : _signOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: AppFormatters.tabular(
            theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
