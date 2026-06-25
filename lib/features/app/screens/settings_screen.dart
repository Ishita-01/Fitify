import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/theme_provider.dart';
import '../providers/units_controller.dart';
import '../widgets/app_widgets.dart';
import 'info_screens.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../onboarding/screens/welcome_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;

  void _go(BuildContext context, Widget screen) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final units = context.watch<UnitsController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                ),
                const SizedBox(width: 16),
                Text('Settings', style: AppTextStyles.heading),
              ],
            ),
            const SizedBox(height: 24),
            _group('Account', [
              _Row(icon: Icons.person_outline_rounded, label: 'My Profile & Goal'),
              _Row(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Subscription',
                  trailing: 'Free',
                  last: true,
                  onTap: () => _go(context, const SubscriptionScreen())),
            ]),
            const SizedBox(height: 18),
            _group('Preferences', [
              _Row(
                  icon: Icons.straighten_rounded,
                  label: 'Units',
                  trailing: units.label,
                  onTap: () => context.read<UnitsController>().toggle()),
              _SwitchRow(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                value: _notifications,
                onChanged: (v) => setState(() => _notifications = v),
              ),
              _SwitchRow(
                icon: theme.isDark
                    ? Icons.dark_mode_rounded
                    : Icons.dark_mode_outlined,
                label: 'Dark Mode',
                subtitle: theme.isDark ? 'Premium dark' : 'Currently Light',
                value: theme.isDark,
                last: true,
                onChanged: (v) => context.read<ThemeController>().setDark(v),
              ),
            ]),
            const SizedBox(height: 18),
            _group('Support', [
              _Row(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & FAQ',
                  onTap: () => _go(context, const HelpFaqScreen())),
              _Row(
                  icon: Icons.lock_outline_rounded,
                  label: 'Privacy Policy',
                  onTap: () => _go(context, const PrivacyPolicyScreen())),
              _Row(
                  icon: Icons.info_outline_rounded,
                  label: 'About',
                  trailing: 'v1.0.0',
                  last: true),
            ]),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () {
                  context.read<OnboardingProvider>().clearProfile();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                },
                child: Text('Sign Out',
                    style: AppTextStyles.label.copyWith(color: AppColors.danger)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _group(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              )),
        ),
        DarkCard(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(children: rows),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(
      {required this.icon,
      required this.label,
      this.trailing,
      this.onTap,
      this.last = false});
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(color: AppColors.border, width: 0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.textPrimary),
          const SizedBox(width: 14),
          Expanded(
              child: Text(label, style: AppTextStyles.title.copyWith(fontSize: 15.5))),
          if (trailing != null) ...[
            Text(trailing!,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary)),
            const SizedBox(width: 6),
          ],
          Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
        ],
      ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.last = false,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(color: AppColors.border, width: 0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.textPrimary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.title.copyWith(fontSize: 15.5)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textTertiary, fontSize: 12)),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}
