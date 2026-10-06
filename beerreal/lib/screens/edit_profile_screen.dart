import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../core/app_cache_manager.dart';
import '../theme.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/profile/services/profile_service.dart';
import '../widgets/pint_loading.dart';

// ── Password strength ─────────────────────────────────────────────────────────

int _strength(String pw) {
  int s = 0;
  if (pw.length >= 8) s++;
  if (RegExp(r'[A-Z]').hasMatch(pw)) s++;
  if (RegExp(r'\d').hasMatch(pw)) s++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(pw)) s++;
  if (pw.length >= 14) s++;
  return s.clamp(0, 4);
}

const _strengthLabels = ['schwach', 'okay', 'gut', 'stark', 'unbreakbar'];

// ── Main Screen ───────────────────────────────────────────────────────────────

class EditProfileScreen extends StatefulWidget {
  final ProfileService profileService;
  const EditProfileScreen({super.key, required this.profileService});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late String _username;
  String _currentPw = '';
  String _newPw = '';
  String _confirmPw = '';
  bool _showCurrentPw = false;
  bool _showNewPw = false;
  bool _avatarRemoved = false;
  File? _pendingAvatar;
  bool _saving = false;
  bool _uploadingAvatar = false;
  bool _deletingAccount = false;
  String? _toast;

  final _usernameFocus = FocusNode();
  final _currentPwFocus = FocusNode();
  final _newPwFocus = FocusNode();
  final _confirmPwFocus = FocusNode();

  static const _taken = {'sam', 'theo', 'you', 'admin', 'pint', 'zapfen'};

  @override
  void initState() {
    super.initState();
    _username = context.read<AuthProvider>().user?.username ?? '';
  }

  @override
  void dispose() {
    _usernameFocus.dispose();
    _currentPwFocus.dispose();
    _newPwFocus.dispose();
    _confirmPwFocus.dispose();
    super.dispose();
  }

  // ── Derived state ──

  String get _original => context.read<AuthProvider>().user?.username ?? '';

  String? get _usernameError {
    if (_username.isEmpty) return null;
    if (_username.length < 3) return 'Mindestens 3 Zeichen.';
    if (_username.length > 16) return 'Maximal 16 Zeichen.';
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(_username)) {
      return 'Nur Buchstaben, Zahlen und Unterstriche.';
    }
    if (_taken.contains(_username)) return '@$_username ist bereits vergeben.';
    return null;
  }

  String? get _usernameHint {
    if (_usernameError != null) return null;
    if (_username.isEmpty) return '3–16 Zeichen, Kleinbuchstaben.';
    if (_username == _original) return 'Dein aktueller Handle: @$_original';
    return 'zapfen.app/u/$_username';
  }

  bool get _usernameOk =>
      _usernameError == null && _username.isNotEmpty && _username != _original;

  bool get _wantingPwChange =>
      _currentPw.isNotEmpty || _newPw.isNotEmpty || _confirmPw.isNotEmpty;

  String? get _newPwError {
    if (_newPw.isEmpty) return null;
    if (_newPw.length < 8) return 'Bitte mindestens 8 Zeichen.';
    if (_currentPw.isNotEmpty && _newPw == _currentPw) {
      return 'Wähl etwas anderes als dein aktuelles Passwort.';
    }
    return null;
  }

  String? get _confirmError {
    if (_confirmPw.isEmpty) return null;
    if (_newPw != _confirmPw) return 'Diese stimmen nicht überein.';
    return null;
  }

  bool get _pwValid =>
      !_wantingPwChange ||
      (_currentPw.isNotEmpty &&
          _newPw.length >= 8 &&
          _newPw == _confirmPw &&
          _newPwError == null);

  bool get _canSave =>
      !_saving && _usernameError == null && _username.isNotEmpty && _pwValid;

  bool get _hasPhoto {
    if (_pendingAvatar != null) return true;
    if (_avatarRemoved) return false;
    return context.read<AuthProvider>().user?.avatarUrl != null;
  }

  String? get _avatarUrl {
    if (_avatarRemoved || _pendingAvatar != null) return null;
    return context.read<AuthProvider>().user?.avatarUrl;
  }

  // ── Actions ──

  Future<void> _evictAvatar(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      await AppCacheManager.instance.removeFile(url);
    } catch (_) {}
    PaintingBinding.instance.imageCache.evict(NetworkImage(url));
  }

  Future<ImageSource?> _chooseAvatarSource() {
    final t = PintThemeProvider.of(context);
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: t.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              _AvatarSourceTile(
                t: t,
                icon: Icons.photo_camera_rounded,
                title: 'Kamera',
                subtitle: 'Neues Profilbild aufnehmen',
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              const SizedBox(height: 8),
              _AvatarSourceTile(
                t: t,
                icon: Icons.photo_library_rounded,
                title: 'Galerie',
                subtitle: 'Bild aus deiner Galerie wählen',
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final source = await _chooseAvatarSource();
    if (source == null || !mounted) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _pendingAvatar = File(picked.path);
      _avatarRemoved = false;
      _uploadingAvatar = true;
    });
    try {
      final oldUrl = context.read<AuthProvider>().user?.avatarUrl;
      final user = await widget.profileService.uploadAvatar(_pendingAvatar!);
      if (!mounted) return;
      context.read<AuthProvider>().updateUser(user);
      setState(() {
        _pendingAvatar = null;
        _uploadingAvatar = false;
      });
      _showToast('Foto aktualisiert');
      _evictAvatar(oldUrl); // fire-and-forget cleanup of old cached file
    } on DioException {
      if (!mounted) return;
      setState(() {
        _pendingAvatar = null;
        _uploadingAvatar = false;
      });
      _showToast('Foto-Upload fehlgeschlagen');
    }
  }

  Future<void> _removeAvatar() async {
    setState(() {
      _avatarRemoved = true;
      _pendingAvatar = null;
    });
    try {
      final oldUrl = context.read<AuthProvider>().user?.avatarUrl;
      final user = await widget.profileService.removeAvatar();
      if (!mounted) return;
      await _evictAvatar(oldUrl);
      if (!mounted) return;
      context.read<AuthProvider>().updateUser(user);
      _showToast('Foto entfernt');
    } on DioException {
      if (!mounted) return;
      setState(() => _avatarRemoved = false);
      _showToast('Foto konnte nicht entfernt werden');
    }
  }

  Future<void> _save() async {
    if (!_canSave) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final messages = <String>[];
    try {
      if (_usernameOk) {
        final user = await widget.profileService.updateUsername(_username);
        if (!mounted) return;
        context.read<AuthProvider>().updateUser(user);
        messages.add('Du bist jetzt @$_username');
      }
      if (_wantingPwChange && _pwValid) {
        await widget.profileService.changePassword(
          currentPassword: _currentPw,
          newPassword: _newPw,
        );
        setState(() {
          _currentPw = '';
          _newPw = '';
          _confirmPw = '';
        });
        messages.add('Passwort aktualisiert');
      }
      if (messages.isEmpty) {
        _showToast('Nichts zu speichern');
      } else {
        _showToast('Gespeichert · ${messages.join(' & ')}');
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg =
          (data is Map ? data['message'] as String? : null) ??
          'Etwas ist schiefgelaufen.';
      _showToast(msg);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final t = PintThemeProvider.of(context);
    final pwController = TextEditingController();
    bool showPw = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: t.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: t.border),
          ),
          title: Text(
            'Konto wirklich löschen?',
            style: TextStyle(
              color: t.text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alle deine Posts, Freundschaften und Daten werden unwiderruflich gelöscht.',
                style: TextStyle(color: t.textMuted, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: t.surfaceWeak,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: t.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: pwController,
                        obscureText: !showPw,
                        autofocus: true,
                        style: TextStyle(
                          color: t.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          hintText: 'Passwort zur Bestätigung',
                          hintStyle: TextStyle(
                            color: t.textFaint,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setDialogState(() => showPw = !showPw),
                      child: Icon(
                        showPw
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 16,
                        color: t.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Abbrechen',
                style: TextStyle(
                  color: t.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Löschen',
                style: TextStyle(
                  color: Color(0xFFC2511E),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    final password = pwController.text;

    // Capture provider reference before any await — context may be gone after
    final authProvider = context.read<AuthProvider>();

    setState(() => _deletingAccount = true);
    try {
      await widget.profileService.deleteAccount(password);
      // forceLogout() is synchronous — it immediately swaps the root widget
      // to AuthScreen, which tears down the whole navigation stack cleanly.
      authProvider.forceLogout();
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      final msg =
          (data is Map ? data['message'] as String? : null) ??
          'Konto konnte nicht gelöscht werden.';
      _showToast(msg);
    } finally {
      if (mounted) setState(() => _deletingAccount = false);
    }
  }

  void _showToast(String msg) {
    setState(() => _toast = msg);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: t.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: t.bg,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _Header(t: t),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 18),
                          _AvatarBlock(
                            t: t,
                            hasPhoto: _hasPhoto,
                            avatarUrl: _avatarUrl,
                            pendingFile: _pendingAvatar,
                            uploading: _uploadingAvatar,
                            username: _username,
                            onUpload: _uploadingAvatar ? () {} : _pickAvatar,
                            onRemove: _removeAvatar,
                          ),
                          _SectionHeading(t: t, title: 'Benutzername'),
                          _Card(
                            t: t,
                            child: _FieldShell(
                              t: t,
                              label: 'Handle',
                              hint: _usernameHint,
                              error: _usernameError,
                              showOk: _usernameOk,
                              last: true,
                              child: Row(
                                children: [
                                  Text(
                                    '@',
                                    style: TextStyle(
                                      color: t.textMuted,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: TextField(
                                      focusNode: _usernameFocus,
                                      controller:
                                          TextEditingController.fromValue(
                                            TextEditingValue(
                                              text: _username,
                                              selection:
                                                  TextSelection.collapsed(
                                                    offset: _username.length,
                                                  ),
                                            ),
                                          ),
                                      onChanged: (v) {
                                        final clean = v
                                            .toLowerCase()
                                            .replaceAll(
                                              RegExp(r'[^a-z0-9_]'),
                                              '',
                                            )
                                            .substring(
                                              0,
                                              v
                                                          .toLowerCase()
                                                          .replaceAll(
                                                            RegExp(
                                                              r'[^a-z0-9_]',
                                                            ),
                                                            '',
                                                          )
                                                          .length >
                                                      16
                                                  ? 16
                                                  : v
                                                        .toLowerCase()
                                                        .replaceAll(
                                                          RegExp(r'[^a-z0-9_]'),
                                                          '',
                                                        )
                                                        .length,
                                            );
                                        setState(() => _username = clean);
                                      },
                                      keyboardType: TextInputType.text,
                                      textInputAction: TextInputAction.next,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[a-z0-9_]'),
                                        ),
                                        LengthLimitingTextInputFormatter(16),
                                      ],
                                      style: TextStyle(
                                        color: t.text,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.3,
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        border: InputBorder.none,
                                        hintText: 'handle',
                                        hintStyle: TextStyle(
                                          color: t.textFaint,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_usernameOk)
                                    Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: t.goldText,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          _SectionHeading(
                            t: t,
                            title: 'Passwort',
                            hint:
                                'Leer lassen, um das aktuelle Passwort beizubehalten.',
                          ),
                          _Card(
                            t: t,
                            child: Column(
                              children: [
                                _FieldShell(
                                  t: t,
                                  label: 'Aktuelles Passwort',
                                  child: _PwRow(
                                    t: t,
                                    focusNode: _currentPwFocus,
                                    value: _currentPw,
                                    show: _showCurrentPw,
                                    hint: '••••••••',
                                    textInputAction: TextInputAction.next,
                                    onChanged: (v) =>
                                        setState(() => _currentPw = v),
                                    onToggle: () => setState(
                                      () => _showCurrentPw = !_showCurrentPw,
                                    ),
                                  ),
                                ),
                                _FieldShell(
                                  t: t,
                                  label: 'Neues Passwort',
                                  error: _newPwError,
                                  hint: _newPw.isEmpty || _newPwError != null
                                      ? '8+ Zeichen.'
                                      : null,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _PwRow(
                                        t: t,
                                        focusNode: _newPwFocus,
                                        value: _newPw,
                                        show: _showNewPw,
                                        hint: 'Mindestens 8 Zeichen',
                                        textInputAction: TextInputAction.next,
                                        onChanged: (v) =>
                                            setState(() => _newPw = v),
                                        onToggle: () => setState(
                                          () => _showNewPw = !_showNewPw,
                                        ),
                                      ),
                                      if (_newPw.isNotEmpty &&
                                          _newPwError == null)
                                        _StrengthMeter(t: t, pw: _newPw),
                                    ],
                                  ),
                                ),
                                _FieldShell(
                                  t: t,
                                  label: 'Neues Passwort bestätigen',
                                  error: _confirmError,
                                  last: true,
                                  child: _PwRow(
                                    t: t,
                                    focusNode: _confirmPwFocus,
                                    value: _confirmPw,
                                    show: _showNewPw,
                                    hint: 'Erneut eingeben',
                                    textInputAction: TextInputAction.done,
                                    onChanged: (v) =>
                                        setState(() => _confirmPw = v),
                                    onToggle: null,
                                    trailing:
                                        _confirmPw.isNotEmpty &&
                                            _confirmError == null
                                        ? Icon(
                                            Icons.check_rounded,
                                            size: 16,
                                            color: t.goldText,
                                          )
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            child: _SaveButton(
                              t: t,
                              canSave: _canSave,
                              saving: _saving,
                              onSave: _save,
                            ),
                          ),
                          const SizedBox(height: 32),
                          _SectionHeading(t: t, title: 'Gefahrenzone'),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: GestureDetector(
                              onTap: _deletingAccount ? null : _deleteAccount,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDF2F0),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFC2511E,
                                    ).withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_deletingAccount)
                                      PintDots(
                                        color: const Color(0xFFC2511E),
                                        dotSize: 5,
                                        spacing: 4,
                                      )
                                    else ...[
                                      const Icon(
                                        Icons.delete_forever_rounded,
                                        size: 17,
                                        color: Color(0xFFC2511E),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Konto löschen',
                                        style: TextStyle(
                                          color: Color(0xFFC2511E),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_toast != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 36,
                  child: _Toast(t: t, msg: _toast!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final PintTheme t;

  const _Header({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Icon(Icons.chevron_left_rounded, size: 26, color: t.text),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Profil bearbeiten',
                style: TextStyle(
                  color: t.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          const SizedBox(width: 42),
        ],
      ),
    );
  }
}

// ── Avatar block ──────────────────────────────────────────────────────────────

class _AvatarSourceTile extends StatelessWidget {
  final PintTheme t;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AvatarSourceTile({
    required this.t,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.surfaceWeak,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: t.goldSoft,
                shape: BoxShape.circle,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: t.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: t.textMuted),
          ],
        ),
      ),
    );
  }
}

class _AvatarBlock extends StatelessWidget {
  final PintTheme t;
  final bool hasPhoto;
  final String? avatarUrl;
  final File? pendingFile;
  final bool uploading;
  final String username;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  const _AvatarBlock({
    required this.t,
    required this.hasPhoto,
    required this.avatarUrl,
    required this.pendingFile,
    required this.uploading,
    required this.username,
    required this.onUpload,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.goldFaint,
        border: Border.all(color: t.goldBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: t.gold, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x47000000),
                      blurRadius: 28,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: ClipOval(child: _avatarWidget()),
              ),
              if (uploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: -2,
                bottom: -2,
                child: GestureDetector(
                  onTap: uploading ? null : onUpload,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: t.gold,
                      shape: BoxShape.circle,
                      border: Border.all(color: t.bg, width: 2),
                    ),
                    child: Icon(
                      Icons.photo_camera_rounded,
                      size: 16,
                      color: t.goldInk,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profilbild',
                  style: TextStyle(
                    color: t.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Ein echtes Selfie kommt bei deinem Kreis besser an.',
                  style: TextStyle(
                    color: t.textMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    GestureDetector(
                      onTap: onUpload,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: t.gold,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.upload_rounded,
                              size: 12,
                              color: t.goldInk,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              hasPhoto ? 'Ersetzen' : 'Hochladen',
                              style: TextStyle(
                                color: t.goldInk,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (hasPhoto) ...[
                      GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: t.surfaceWeak,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: t.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 12,
                                color: t.textMuted,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Entfernen',
                                style: TextStyle(
                                  color: t.text,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarWidget() {
    if (pendingFile != null) {
      return Image.file(pendingFile!, fit: BoxFit.cover, width: 92, height: 92);
    }
    if (avatarUrl != null) {
      return CachedNetworkImage(
        imageUrl: avatarUrl!,
        cacheManager: AppCacheManager.instance,
        fit: BoxFit.cover,
        width: 92,
        height: 92,
        errorWidget: (_, __, ___) => _initials(),
      );
    }
    return _initials();
  }

  Widget _initials() {
    final letter = username.isNotEmpty ? username[0].toUpperCase() : '?';
    return Container(
      color: t.gold,
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: t.goldInk,
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.03,
          ),
        ),
      ),
    );
  }
}

// ── Section heading ───────────────────────────────────────────────────────────

class _SectionHeading extends StatelessWidget {
  final PintTheme t;
  final String title;
  final String? hint;

  const _SectionHeading({required this.t, required this.title, this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: t.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.2,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(hint!, style: TextStyle(color: t.textFaint, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

// ── Card container ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final PintTheme t;
  final Widget child;

  const _Card({required this.t, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: t.surfaceWeaker,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      child: child,
    );
  }
}

// ── Field shell ───────────────────────────────────────────────────────────────

class _FieldShell extends StatelessWidget {
  final PintTheme t;
  final String label;
  final String? hint;
  final String? error;
  final bool showOk;
  final bool last;
  final Widget child;

  const _FieldShell({
    required this.t,
    required this.label,
    this.hint,
    this.error,
    this.showOk = false,
    this.last = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: t.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: t.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
              const Spacer(),
              if (showOk)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, size: 12, color: t.goldText),
                    const SizedBox(width: 4),
                    Text(
                      'gespeichert',
                      style: TextStyle(
                        color: t.goldText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: t.surfaceWeak,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError ? const Color(0xFFC2511E) : t.border,
              ),
            ),
            child: child,
          ),
          const SizedBox(height: 4),
          if (error != null || hint != null)
            Row(
              children: [
                if (hasError) ...[
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 12,
                    color: Color(0xFFC2511E),
                  ),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    error ?? hint ?? '',
                    style: TextStyle(
                      color: hasError ? const Color(0xFFC2511E) : t.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Password row ──────────────────────────────────────────────────────────────

class _PwRow extends StatelessWidget {
  final PintTheme t;
  final FocusNode focusNode;
  final String value;
  final bool show;
  final String hint;
  final TextInputAction textInputAction;
  final ValueChanged<String> onChanged;
  final VoidCallback? onToggle;
  final Widget? trailing;

  const _PwRow({
    required this.t,
    required this.focusNode,
    required this.value,
    required this.show,
    required this.hint,
    required this.textInputAction,
    required this.onChanged,
    required this.onToggle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.lock_outline_rounded, size: 16, color: t.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            focusNode: focusNode,
            obscureText: !show,
            onChanged: onChanged,
            textInputAction: textInputAction,
            style: TextStyle(
              color: t.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(
                color: t.textFaint,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        if (trailing != null) trailing!,
        if (onToggle != null)
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                show
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 16,
                color: t.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Strength meter ────────────────────────────────────────────────────────────

class _StrengthMeter extends StatelessWidget {
  final PintTheme t;
  final String pw;

  const _StrengthMeter({required this.t, required this.pw});

  @override
  Widget build(BuildContext context) {
    final s = _strength(pw);
    final barColor = s < 2 ? const Color(0xFFC2511E) : t.goldText;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 4,
                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i < s ? barColor : t.surfaceWeak,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 5),
          Text.rich(
            TextSpan(
              text: 'Passwort-Stärke: ',
              style: TextStyle(
                color: t.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(
                  text: pw.isNotEmpty ? _strengthLabels[s] : '—',
                  style: TextStyle(color: barColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom save button ────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final PintTheme t;
  final bool canSave;
  final bool saving;
  final VoidCallback onSave;

  const _SaveButton({
    required this.t,
    required this.canSave,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canSave ? onSave : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: canSave ? t.gold : t.surfaceWeak,
          borderRadius: BorderRadius.circular(16),
          border: canSave ? null : Border.all(color: t.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (saving)
              PintDots(
                color: canSave ? t.goldInk : t.textFaint,
                dotSize: 5,
                spacing: 4,
              )
            else
              Icon(
                Icons.check_rounded,
                size: 17,
                color: canSave ? t.goldInk : t.textFaint,
              ),
            const SizedBox(width: 8),
            Text(
              'Änderungen speichern',
              style: TextStyle(
                color: canSave ? t.goldInk : t.textFaint,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Toast ─────────────────────────────────────────────────────────────────────

class _Toast extends StatelessWidget {
  final PintTheme t;
  final String msg;

  const _Toast({required this.t, required this.msg});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: t.gold,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x59000000),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded, size: 15, color: t.goldInk),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  msg,
                  style: TextStyle(
                    color: t.goldInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
