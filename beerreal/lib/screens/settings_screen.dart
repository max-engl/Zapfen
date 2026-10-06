import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api/api_client.dart';
import '../core/app_version.dart';
import '../core/notification_service.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/profile/services/profile_service.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import 'edit_profile_screen.dart';
import 'legal_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _notificationsEnabled;
  bool _updatingNotifications = false;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = NotificationService.enabled;
    _refreshNotificationStatus();
  }

  Future<void> _refreshNotificationStatus() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    final systemAllowsNotifications =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!mounted) return;
    setState(() {
      _notificationsEnabled =
          NotificationService.enabled && systemAllowsNotifications;
    });
  }

  Future<void> _setNotificationsEnabled(bool value) async {
    if (_updatingNotifications) return;
    setState(() => _updatingNotifications = true);

    bool enabled = false;
    try {
      enabled = await NotificationService.setEnabled(
        context.read<ApiClient>(),
        value,
      );
    } catch (_) {
      if (mounted) {
        _showMessage('Benachrichtigungen konnten nicht geändert werden.');
      }
    }

    if (!mounted) return;
    setState(() {
      _notificationsEnabled = value && enabled;
      _updatingNotifications = false;
    });
    if (value && !enabled) {
      _showMessage(
        'Bitte erlaube Benachrichtigungen in den iPhone-Einstellungen.',
      );
    }
  }

  void _showMessage(String message) {
    final t = PintThemeProvider.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(color: t.text, fontWeight: FontWeight.w600),
          ),
          backgroundColor: t.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: t.border),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(
          children: [
            _SettingsHeader(t: t),
            Divider(height: 1, color: t.divider),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
                children: [
                  _ProfileSummary(
                    t: t,
                    username: user?.username ?? '',
                    email: user?.email ?? '',
                    avatarUrl: user?.avatarUrl,
                    avatarColor: user?.avatarColor,
                    avatarInitial: user?.avatarInitial,
                  ),
                  const SizedBox(height: 26),
                  _SectionLabel(t: t, label: 'KONTO'),
                  _SettingsCard(
                    t: t,
                    children: [
                      _SettingsRow(
                        t: t,
                        icon: Icons.person_outline_rounded,
                        title: 'Profil bearbeiten',
                        subtitle: 'Foto, Benutzername und Passwort',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => EditProfileScreen(
                              profileService: ctx.read<ProfileService>(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(t: t, label: 'BENACHRICHTIGUNGEN'),
                  _SettingsCard(
                    t: t,
                    children: [
                      _SettingsRow(
                        t: t,
                        icon: Icons.notifications_none_rounded,
                        title: 'Push-Benachrichtigungen',
                        subtitle: _notificationsEnabled
                            ? 'Aktivitäten aus deinem Kreis erhalten'
                            : 'Keine Push-Mitteilungen erhalten',
                        trailing: _updatingNotifications
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: t.gold,
                                ),
                              )
                            : Switch.adaptive(
                                value: _notificationsEnabled,
                                activeTrackColor: t.gold,
                                inactiveTrackColor: t.border,
                                onChanged: _setNotificationsEnabled,
                              ),
                        onTap: _updatingNotifications
                            ? null
                            : () => _setNotificationsEnabled(
                                !_notificationsEnabled,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(t: t, label: 'APP'),
                  _SettingsCard(
                    t: t,
                    children: [
                      _SettingsRow(
                        t: t,
                        icon: Icons.shield_outlined,
                        title: 'Datenschutz & Rechtliches',
                        subtitle: 'Regeln, Bedingungen und Impressum',
                        onTap: () => showLegalSheet(context),
                      ),
                      _SettingsDivider(t: t),
                      _SettingsRow(
                        t: t,
                        icon: Icons.info_outline_rounded,
                        title: 'Über Zapfen',
                        subtitle: 'Version $kAppVersion',
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _LogoutButton(
                    t: t,
                    onTap: () => context.read<AuthProvider>().logout(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final PintTheme t;
  const _SettingsHeader({required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.surfaceWeak,
                border: Border.all(color: t.border),
              ),
              child: Icon(Icons.chevron_left_rounded, size: 22, color: t.text),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Einstellungen',
                style: TextStyle(
                  color: t.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  final PintTheme t;
  final String username;
  final String email;
  final String? avatarUrl;
  final String? avatarColor;
  final String? avatarInitial;

  const _ProfileSummary({
    required this.t,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.avatarColor,
    this.avatarInitial,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.goldFaint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.goldBorder),
      ),
      child: Row(
        children: [
          PintAvatar(
            size: 54,
            ring: true,
            imageUrl: avatarUrl,
            avatarColor: avatarColor,
            initials: avatarInitial,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@$username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.settings_rounded, color: t.goldText, size: 22),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final PintTheme t;
  final String label;

  const _SectionLabel({required this.t, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 9),
      child: Text(
        label,
        style: TextStyle(
          color: t.textFaint,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.3,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final PintTheme t;
  final List<Widget> children;

  const _SettingsCard({required this.t, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  final PintTheme t;

  const _SettingsDivider({required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 62),
      child: Divider(height: 1, color: t.divider),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final PintTheme t;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.t,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: t.goldFaint,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: t.goldBorder),
                ),
                child: Icon(icon, size: 18, color: t.goldText),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: t.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: t.textMuted,
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing ??
                  (onTap == null
                      ? const SizedBox.shrink()
                      : Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: t.textFaint,
                        )),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final PintTheme t;
  final VoidCallback onTap;

  const _LogoutButton({required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE05454);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: red.withValues(alpha: t.isDark ? 0.1 : 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: red.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, size: 17, color: red),
              const SizedBox(width: 8),
              const Text(
                'Abmelden',
                style: TextStyle(
                  color: red,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
