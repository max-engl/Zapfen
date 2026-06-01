import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../widgets/brand_mark.dart';
import '../widgets/img_placeholder.dart';
import '../widgets/pint_loading.dart';
import '../features/auth/providers/auth_provider.dart';

enum _Step { welcome, credentials, handle, done }

// ─── Top-level controller ──────────────────────────────────────────────────

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _Step _step = _Step.welcome;
  bool _forward = true;
  bool _signIn = false;
  String _regEmail = '';
  String _regPw = '';

  static int _depth(_Step s) => switch (s) {
        _Step.welcome => 0,
        _Step.credentials => 1,
        _Step.handle => 2,
        _Step.done => 3,
      };

  void _go(_Step s) => setState(() {
        _forward = _depth(s) >= _depth(_step);
        _step = s;
      });

  Widget _buildStep() => switch (_step) {
        _Step.welcome => _WelcomeStep(
            onSignUp: () {
              _signIn = false;
              _go(_Step.credentials);
            },
            onSignIn: () {
              _signIn = true;
              _go(_Step.credentials);
            },
          ),
        _Step.credentials => _CredentialsStep(
            signIn: _signIn,
            onBack: () => _go(_Step.welcome),
            onNext: (email, pw) {
              _regEmail = email;
              _regPw = pw;
              _go(_Step.handle);
            },
          ),
        _Step.handle => _HandleStep(
            onBack: () => _go(_Step.credentials),
            regEmail: _regEmail,
            regPw: _regPw,
          ),
        _Step.done => _SuccessStep(onEnter: () {}),
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      transitionBuilder: (child, animation) {
        final entering =
            animation.status != AnimationStatus.reverse &&
            animation.status != AnimationStatus.dismissed;
        final slide = Tween<Offset>(
          begin: entering
              ? Offset(_forward ? 0.9 : -0.9, 0.0)
              : Offset(_forward ? -0.15 : 0.15, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuart));
        final fade = CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.7));
        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: fade, child: child),
        );
      },
      child: KeyedSubtree(key: ValueKey(_step), child: _buildStep()),
    );
  }
}

// ─── Common shell ──────────────────────────────────────────────────────────

class _AuthShell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onBack;
  final int step;
  final int totalSteps;

  const _AuthShell({
    required this.child,
    this.onBack,
    this.step = 0,
    this.totalSteps = 0,
  });

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Row(
                children: [
                  if (onBack != null)
                    _CircleIconBtn(
                      onTap: onBack!,
                      child: Icon(Icons.chevron_left, size: 20, color: t.text),
                    )
                  else
                    const SizedBox(width: 36),
                  const Spacer(),
                  if (totalSteps > 1)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(totalSteps, (i) {
                        final isActive = i + 1 == step;
                        final isDone = i + 1 < step;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isActive ? 22 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: (isActive || isDone) ? t.gold : t.surfaceWeak,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: (isActive || isDone)
                                  ? Colors.transparent
                                  : t.border,
                            ),
                          ),
                        );
                      }),
                    ),
                  const Spacer(),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared buttons ────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Widget? trailing;
  final bool disabled;
  final bool loading;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.label,
    this.trailing,
    this.disabled = false,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final isDisabled = disabled || loading;
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDisabled ? t.surfaceWeak : t.gold,
          borderRadius: BorderRadius.circular(16),
          border: isDisabled ? Border.all(color: t.border) : null,
        ),
        child: loading
            ? Center(child: PintDots(color: t.goldInk, dotSize: 5, spacing: 5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isDisabled ? t.textFaint : t.goldInk,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
      ),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _CircleIconBtn({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: t.surfaceWeak,
          border: Border.all(color: t.border),
        ),
        child: child,
      ),
    );
  }
}

// ─── Shared auth field ─────────────────────────────────────────────────────

class _AuthField extends StatelessWidget {
  final String label;
  final Widget? icon;
  final String value;
  final ValueChanged<String> onChange;
  final TextInputType keyboardType;
  final bool obscureText;
  final String placeholder;
  final bool autoFocus;
  final Widget? labelRight;
  final Widget? rightAdornment;
  final bool highlighted;

  const _AuthField({
    required this.label,
    required this.value,
    required this.onChange,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.placeholder = '',
    this.autoFocus = false,
    this.labelRight,
    this.rightAdornment,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final borderColor = highlighted ? t.goldBorder : t.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: t.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              if (labelRight != null) labelRight!,
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: t.surfaceWeak,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                const SizedBox(width: 14),
                icon!,
                const SizedBox(width: 10),
              ] else
                const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  autofocus: autoFocus,
                  onChanged: onChange,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  style: TextStyle(
                    color: t.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.16,
                  ),
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: TextStyle(
                      color: t.textFaint,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    isDense: true,
                  ),
                ),
              ),
              if (rightAdornment != null) rightAdornment!,
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Step label ────────────────────────────────────────────────────────────

class _StepLabel extends StatelessWidget {
  final String text;

  const _StepLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bolt, size: 10, color: t.goldText),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: t.goldText,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

// ─── Welcome ───────────────────────────────────────────────────────────────

class _WelcomeStep extends StatelessWidget {
  final VoidCallback onSignUp;
  final VoidCallback onSignIn;

  const _WelcomeStep({required this.onSignUp, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return _AuthShell(
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        top: 24,
                        child: _PhotoCard(ImgTone.beer, 'Hazy Pale', t.bg, -10),
                      ),
                      Positioned(
                        left: 80,
                        top: 8,
                        child: _PhotoCard(ImgTone.bar, 'Triple', t.bg, 10),
                      ),
                      Positioned(
                        left: 40,
                        top: 56,
                        child: _PhotoCard(ImgTone.night, 'Stout', t.bg, -2),
                      ),
                      Positioned(
                        right: -8,
                        bottom: -8,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: t.bg,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const BrandMark(size: 56),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      color: t.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 32,
                      letterSpacing: -1.0,
                      height: 1.05,
                    ),
                    children: [
                      const TextSpan(text: 'Ein Bier.\n'),
                      TextSpan(
                        text: 'Ein Moment.',
                        style: TextStyle(color: t.goldText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Jeden Tag erscheint zu einer zufälligen Zeit ein Prompt.\nZapf, knips und sieh, was dein Kreis trinkt.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.textMuted, fontSize: 14, height: 1.45),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PrimaryButton(
                label: 'Dein erstes Bier zapfen',
                trailing: Icon(Icons.arrow_forward, size: 16, color: t.goldInk),
                onTap: onSignUp,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Schon dabei? ',
                    style: TextStyle(color: t.textMuted, fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: onSignIn,
                    child: Text(
                      'Anmelden',
                      style: TextStyle(
                        color: t.goldText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: t.goldText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Mit dem Fortfahren stimmst du unseren Bedingungen zu. Nur ab 18 Jahren.',
                textAlign: TextAlign.center,
                style: TextStyle(color: t.textFaint, fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final ImgTone tone;
  final String label;
  final Color borderColor;
  final double degrees;

  const _PhotoCard(this.tone, this.label, this.borderColor, this.degrees);

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: degrees * (3.14159265 / 180),
      child: Container(
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x59000000),
              blurRadius: 40,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ImgPlaceholder(tone: tone, label: label),
        ),
      ),
    );
  }
}

// ─── Credentials (sign-in + register unified) ──────────────────────────────

class _CredentialsStep extends StatefulWidget {
  final bool signIn;
  final VoidCallback onBack;
  final void Function(String email, String password) onNext;

  const _CredentialsStep({
    required this.signIn,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<_CredentialsStep> createState() => _CredentialsStepState();
}

class _CredentialsStepState extends State<_CredentialsStep> {
  String _email = '';
  String _pw = '';
  bool _showPw = false;
  String _error = '';
  bool _loading = false;

  bool get _emailOk => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email.trim());
  bool get _pwOk => _pw.length >= 8;
  bool get _valid => _emailOk && _pwOk;

  String _pwHint() {
    if (_pw.isEmpty) return 'Mindestens 8 Zeichen.';
    if (_pwOk) return 'Stark genug zum Zapfen.';
    final rem = 8 - _pw.length;
    return 'Noch $rem Zeichen.';
  }

  Future<void> _submit() async {
    if (!_valid) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    final ok = await context.read<AuthProvider>().login(
      emailOrUsername: _email.trim(),
      password: _pw,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _error = context.read<AuthProvider>().errorMessage ??
            'E-Mail oder Passwort falsch. Der Barkeeper kennt dich nicht.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    return _AuthShell(
      step: widget.signIn ? 0 : 1,
      totalSteps: widget.signIn ? 0 : 2,
      onBack: widget.onBack,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _StepLabel(widget.signIn ? 'ANMELDEN' : 'SCHRITT 1 VON 2'),
                  const SizedBox(height: 8),
                  Text(
                    widget.signIn ? 'Willkommen\nzurück.' : 'Erstelle dein\nKonto.',
                    style: TextStyle(
                      color: t.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      letterSpacing: -0.84,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.signIn
                        ? 'Melde dich mit der E-Mail und dem Passwort an, mit dem du dein erstes Bier gezapft hast.'
                        : 'Nutze deine E-Mail und ein Passwort. Deine Adresse bleibt privat – nur dein Handle wird angezeigt.',
                    style: TextStyle(color: t.textMuted, fontSize: 14, height: 1.45),
                  ),
                  const SizedBox(height: 24),
                  _AuthField(
                    label: 'E-Mail',
                    icon: Icon(Icons.mail_outline, size: 18, color: t.textMuted),
                    value: _email,
                    onChange: (v) => setState(() {
                      _email = v;
                      _error = '';
                    }),
                    keyboardType: TextInputType.emailAddress,
                    placeholder: 'you@example.com',
                    highlighted: _emailOk,
                    autoFocus: true,
                  ),
                  const SizedBox(height: 14),
                  _AuthField(
                    label: 'Passwort',
                    icon: Icon(Icons.lock_outline, size: 18, color: t.textMuted),
                    value: _pw,
                    onChange: (v) => setState(() {
                      _pw = v;
                      _error = '';
                    }),
                    obscureText: !_showPw,
                    placeholder: widget.signIn ? 'Dein Passwort' : 'Mindestens 8 Zeichen',
                    highlighted: _pwOk,
                    labelRight: widget.signIn
                        ? GestureDetector(
                            onTap: () {},
                            child: Text(
                              'Vergessen?',
                              style: TextStyle(
                                color: t.goldText,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          )
                        : null,
                    rightAdornment: GestureDetector(
                      onTap: () => setState(() => _showPw = !_showPw),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          _showPw
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: t.textMuted,
                        ),
                      ),
                    ),
                  ),
                  if (!widget.signIn) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        _pwHint(),
                        style: TextStyle(
                          color: _pwOk ? t.goldText : t.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              size: 12, color: Color(0xFFC2511E)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _error,
                              style: const TextStyle(
                                color: Color(0xFFC2511E),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.fromLTRB(0, 12, 0, keyboardHeight > 0 ? 12 : 0),
            child: _PrimaryButton(
              label: widget.signIn ? 'Anmelden' : 'Weiter',
              disabled: !_valid,
              loading: _loading,
              trailing: _loading
                  ? null
                  : Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: _valid ? t.goldInk : t.textFaint,
                    ),
              onTap: widget.signIn
                  ? _submit
                  : (_valid ? () => widget.onNext(_email.trim(), _pw) : null),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Handle ────────────────────────────────────────────────────────────────

class _HandleStep extends StatefulWidget {
  final VoidCallback onBack;
  final String regEmail;
  final String regPw;

  const _HandleStep({
    required this.onBack,
    required this.regEmail,
    required this.regPw,
  });

  @override
  State<_HandleStep> createState() => _HandleStepState();
}

class _HandleStepState extends State<_HandleStep> {
  String _name = '';
  String _handle = '';
  bool _loading = false;

  Future<void> _submit() async {
    if (!_valid) return;
    setState(() => _loading = true);
    final ok = await context.read<AuthProvider>().register(
      username: _handle,
      email: widget.regEmail,
      password: widget.regPw,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<AuthProvider>().errorMessage ?? 'Registrierung fehlgeschlagen.',
          ),
        ),
      );
    }
  }

  static const _taken = {'sam', 'maya', 'theo', 'you'};
  bool get _isTaken => _taken.contains(_handle.toLowerCase());
  bool get _isTooLong => _handle.length > 16;
  bool get _isTooShort => _handle.length < 3 && _handle.isNotEmpty;
  bool get _hasInvalidChars =>
      _handle.isNotEmpty && !RegExp(r'^[a-z0-9_]+$').hasMatch(_handle);

  String? get _handleStatus {
    if (_handle.isEmpty) return null;
    if (_isTaken) return 'taken';
    if (_isTooLong) return 'long';
    if (_isTooShort) return 'short';
    if (_hasInvalidChars) return 'chars';
    return 'ok';
  }

  bool get _valid =>
      _name.trim().isNotEmpty && _handle.isNotEmpty && _handleStatus == 'ok';

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final status = _handleStatus;

    Color statusColor() {
      if (status == 'ok') return t.goldText;
      if (status != null) return const Color(0xFFC2511E);
      return t.textMuted;
    }

    String statusText() {
      if (status == 'ok') return '@$_handle gehört dir.';
      if (status == 'taken') return '@$_handle ist vergeben. Versuch ${_handle}_42';
      if (status == 'short') return 'Mindestens 3 Zeichen.';
      if (status == 'long') return 'Maximal 16 Zeichen.';
      if (status == 'chars') return 'Nur Buchstaben, Zahlen und Unterstriche.';
      return '3–16 Zeichen.';
    }

    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    return _AuthShell(
      step: 2,
      totalSteps: 2,
      onBack: widget.onBack,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _StepLabel('SCHRITT 2 VON 2'),
                  const SizedBox(height: 8),
                  Text(
                    'Wähl deinen\nZapfnamen.',
                    style: TextStyle(
                      color: t.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      letterSpacing: -0.84,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dein Handle ist, wie Freunde dich finden und in Bieren markieren. Kleinbuchstaben, Zahlen, Unterstriche.',
                    style: TextStyle(color: t.textMuted, fontSize: 14, height: 1.45),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: t.goldFaint,
                          border: Border.all(color: t.goldBorderStrong, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            (_name.isNotEmpty
                                    ? _name[0]
                                    : _handle.isNotEmpty
                                    ? _handle[0]
                                    : '?')
                                .toUpperCase(),
                            style: TextStyle(
                              color: t.goldText,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: t.surfaceWeak,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: t.border),
                        ),
                        child: Text(
                          'Selfie hochladen',
                          style: TextStyle(
                            color: t.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'ANZEIGENAME',
                    style: TextStyle(
                      color: t.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    onChanged: (v) => setState(() => _name = v),
                    style: TextStyle(
                      color: t.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Dein Name',
                      hintStyle: TextStyle(color: t.textFaint, fontWeight: FontWeight.w400),
                      filled: true,
                      fillColor: t.surfaceWeak,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: t.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: t.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: t.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'HANDLE',
                    style: TextStyle(
                      color: t.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: t.surfaceWeak,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: status == 'ok'
                            ? t.goldBorderStrong
                            : (status != null && status != 'ok')
                            ? const Color(0xFFC2511E)
                            : t.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: Text(
                            '@',
                            style: TextStyle(
                              color: t.textMuted,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(
                              () => _handle = v.toLowerCase().replaceAll(' ', ''),
                            ),
                            style: TextStyle(
                              color: t.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                            decoration: InputDecoration(
                              hintText: 'yourhandle',
                              hintStyle: TextStyle(
                                color: t.textFaint,
                                fontWeight: FontWeight.w400,
                              ),
                              filled: false,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              suffixIcon: status == 'ok'
                                  ? Icon(Icons.check, size: 18, color: t.goldText)
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    statusText(),
                    style: TextStyle(
                      color: statusColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: t.goldFaint,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.goldBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: t.gold,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Icon(Icons.check, size: 14, color: t.goldInk),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: t.text, fontSize: 12, height: 1.45),
                              children: [
                                const TextSpan(
                                  text: 'Schick mir den täglichen Prompt. ',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(
                                  text: 'Eine Push-Nachricht pro Tag. Zufällige Zeit. Verpasst du sie, wird dein Bier trotzdem angezeigt.',
                                  style: TextStyle(color: t.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.fromLTRB(0, 8, 0, keyboardHeight > 0 ? 12 : 0),
            child: _PrimaryButton(
              label: 'Das erste Bier zapfen 🍻',
              disabled: !_valid,
              loading: _loading,
              onTap: _submit,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Success ───────────────────────────────────────────────────────────────

class _SuccessStep extends StatelessWidget {
  final VoidCallback onEnter;

  const _SuccessStep({required this.onEnter});

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return _AuthShell(
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.goldSoft,
                    border: Border.all(color: t.goldBorderStrong, width: 2),
                  ),
                  child: Icon(Icons.check, size: 46, color: t.goldText),
                ),
                const SizedBox(height: 22),
                Text(
                  'Du bist dabei,\n@du.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: t.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    letterSpacing: -0.84,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Der nächste Prompt kommt irgendwann morgen.\nWir geben Bescheid, wenn es Zeit ist zu zapfen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.textMuted, fontSize: 14, height: 1.45),
                ),
              ],
            ),
          ),
          _PrimaryButton(label: 'Zapfen öffnen.', onTap: onEnter),
        ],
      ),
    );
  }
}
