import 'package:flutter/material.dart';
import '../theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onGoToFriends;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
    required this.onGoToFriends,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _ctrl = PageController();
  int _page = 0;
  static const _total = 6;

  void _next() {
    if (_page < _total - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    } else {
      widget.onGoToFriends();
    }
  }

  void _skipFriends() => widget.onComplete();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedOpacity(
                    opacity: _page < _total - 1 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: _page < _total - 1 ? widget.onComplete : null,
                      child: Text(
                        'Überspringen',
                        style: TextStyle(
                          color: t.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _ctrl,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _OPage(
                    illustration: _SocialIllustration(active: _page == 0),
                    headline: 'Hast du\nein Bier?',
                    body:
                        'Immer wenn du eins trinkst, zapf es in die App. Dein Kreis sieht sofort, was du gerade trinkst.',
                  ),
                  _OPage(
                    illustration: _CaptureIllustration(active: _page == 1),
                    headline: 'Zapf,\nknips, fertig.',
                    body:
                        'Wähl dein Bier, schieß ein Foto und schick es raus. In unter 30 Sekunden bist du im Feed.',
                  ),
                  _OPage(
                    illustration: _FeedIllustration(active: _page == 2),
                    headline: 'Sieh deinen\nKreis.',
                    body:
                        'Was trinken deine Freunde? Im Feed siehst du Biere in Echtzeit – reagiere, kommentiere, prosit.',
                  ),
                  _OPage(
                    illustration: _LeaderboardIllustration(active: _page == 3),
                    headline: 'Bleib\nan der Spitze.',
                    body:
                        'Wer zapft am meisten – diese Woche, diesen Monat, insgesamt? Messe dich mit Freunden oder der ganzen Welt.',
                  ),
                  _OPage(
                    illustration: _StatsIllustration(active: _page == 4),
                    headline: 'Alle\nZahlen im Blick.',
                    body:
                        'Sieh genau, was du trinkst, wie oft und wann – nach Woche, Monat oder insgesamt.',
                  ),
                  _OPage(
                    illustration: _FindFriendsIllustration(active: _page == 5),
                    headline: 'Hol dir\ndeinen Kreis.',
                    body:
                        'Die App macht erst richtig Spaß mit Freunden. Füge jetzt jemanden hinzu.',
                  ),
                ],
              ),
            ),
            _BottomBar(
              page: _page,
              total: _total,
              onNext: _next,
              onSkipFriends: _skipFriends,
            ),
          ],
            ),
          ),
          _HintOverlay(page: _page),
        ],
      ),
    );
  }
}

// ─── Page wrapper ─────────────────────────────────────────────────────────

class _OPage extends StatelessWidget {
  final Widget illustration;
  final String headline;
  final String body;

  const _OPage({
    required this.illustration,
    required this.headline,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Column(
        children: [
          Expanded(flex: 5, child: illustration),
          const SizedBox(height: 28),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: TextStyle(
                    color: t.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    letterSpacing: -1.0,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  body,
                  style: TextStyle(
                    color: t.textMuted,
                    fontSize: 15,
                    height: 1.5,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom bar ───────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int page;
  final int total;
  final VoidCallback onNext;
  final VoidCallback? onSkipFriends;

  const _BottomBar({
    required this.page,
    required this.total,
    required this.onNext,
    this.onSkipFriends,
  });

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final isLast = page == total - 1;

    String buttonLabel() {
      if (isLast) return 'Freunde hinzufügen';
      return 'Weiter';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              final active = i == page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 22 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? t.gold : t.surfaceWeak,
                  borderRadius: BorderRadius.circular(3),
                  border: active ? null : Border.all(color: t.border),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onNext,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: t.gold,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    buttonLabel(),
                    key: ValueKey(isLast),
                    style: TextStyle(
                      color: t.goldInk,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLast
                ? Padding(
                    key: const ValueKey('skip'),
                    padding: const EdgeInsets.only(top: 14),
                    child: GestureDetector(
                      onTap: onSkipFriends,
                      child: Text(
                        'Später überspringen',
                        style: TextStyle(
                          color: t.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('no-skip')),
          ),
        ],
      ),
    );
  }
}

// ─── Illustration 1: Social sharing ──────────────────────────────────────

class _SocialIllustration extends StatefulWidget {
  final bool active;
  const _SocialIllustration({required this.active});

  @override
  State<_SocialIllustration> createState() => _SocialIllustrationState();
}

class _SocialIllustrationState extends State<_SocialIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _beerCtrl;
  late final List<AnimationController> _avatarCtrls;

  late final Animation<double> _beerScale;
  late final Animation<double> _beerOpacity;

  // Avatar positions: top-left, top-right, bottom-center
  static const _avatars = [
    (initials: 'S', reaction: '🍺', dx: -1.0, dy: -0.9),
    (initials: 'M', reaction: '🔥', dx: 1.0, dy: -0.7),
    (initials: 'T', reaction: '👀', dx: -0.6, dy: 1.0),
  ];

  late final List<Animation<Offset>> _avatarSlides;
  late final List<Animation<double>> _avatarOpacities;
  late final List<Animation<double>> _avatarScales;

  @override
  void initState() {
    super.initState();
    _beerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _avatarCtrls = List.generate(
      _avatars.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 480),
      ),
    );

    _beerScale = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _beerCtrl, curve: Curves.elasticOut),
    );
    _beerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _beerCtrl, curve: const Interval(0.0, 0.3)),
    );

    _avatarSlides = List.generate(_avatars.length, (i) {
      return Tween<Offset>(
        begin: Offset(_avatars[i].dx * 0.6, _avatars[i].dy * 0.6),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _avatarCtrls[i],
          curve: Curves.easeOutBack,
        ),
      );
    });
    _avatarOpacities = _avatarCtrls
        .map(
          (c) => Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: c, curve: const Interval(0.0, 0.45)),
          ),
        )
        .toList();
    _avatarScales = _avatarCtrls
        .map(
          (c) => Tween<double>(begin: 0.5, end: 1.0).animate(
            CurvedAnimation(parent: c, curve: Curves.easeOutBack),
          ),
        )
        .toList();

    if (widget.active) _play();
  }

  @override
  void didUpdateWidget(covariant _SocialIllustration old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _play();
  }

  Future<void> _play() async {
    if (!mounted) return;
    _beerCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 350));
    for (int i = 0; i < _avatarCtrls.length; i++) {
      if (!mounted) return;
      _avatarCtrls[i].forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 110));
    }
  }

  @override
  void dispose() {
    _beerCtrl.dispose();
    for (final c in _avatarCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    // Layout: fixed positions relative to a 260×260 box
    const boxSize = 260.0;
    const beerSize = 90.0;
    const avatarSize = 60.0;

    // Avatar centers (x, y) within the box
    const positions = [
      Offset(30, 20),    // top-left
      Offset(175, 10),   // top-right
      Offset(50, 165),   // bottom-left
    ];

    return Center(
      child: SizedBox(
        width: boxSize,
        height: boxSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Beer emoji center
            Positioned(
              left: boxSize / 2 - beerSize / 2,
              top: boxSize / 2 - beerSize / 2 - 10,
              child: ScaleTransition(
                scale: _beerScale,
                child: FadeTransition(
                  opacity: _beerOpacity,
                  child: Container(
                    width: beerSize,
                    height: beerSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: t.goldFaint,
                      border: Border.all(color: t.goldBorder, width: 2),
                    ),
                    child: const Center(
                      child: Text('🍺', style: TextStyle(fontSize: 44)),
                    ),
                  ),
                ),
              ),
            ),
            // Friend avatars
            for (int i = 0; i < _avatars.length; i++)
              Positioned(
                left: positions[i].dx,
                top: positions[i].dy,
                child: SlideTransition(
                  position: _avatarSlides[i],
                  child: FadeTransition(
                    opacity: _avatarOpacities[i],
                    child: ScaleTransition(
                      scale: _avatarScales[i],
                      child: _AvatarBubble(
                        t: t,
                        initials: _avatars[i].initials,
                        reaction: _avatars[i].reaction,
                        size: avatarSize,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  final PintTheme t;
  final String initials;
  final String reaction;
  final double size;

  const _AvatarBubble({
    required this.t,
    required this.initials,
    required this.reaction,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 16,
      height: size + 16,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.surface,
              border: Border.all(color: t.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: t.isDark ? 0.35 : 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: t.text,
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.32,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.surface,
                border: Border.all(color: t.border, width: 1.5),
              ),
              child: Center(
                child: Text(reaction, style: const TextStyle(fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Illustration 2: Capture ──────────────────────────────────────────────

class _CaptureIllustration extends StatefulWidget {
  final bool active;
  const _CaptureIllustration({required this.active});

  @override
  State<_CaptureIllustration> createState() => _CaptureIllustrationState();
}

class _CaptureIllustrationState extends State<_CaptureIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _phoneCtrl;
  late final AnimationController _flashCtrl;
  late final AnimationController _labelCtrl;
  late final AnimationController _ringCtrl;

  late final Animation<double> _phoneScale;
  late final Animation<double> _phoneOpacity;
  late final Animation<double> _flashOpacity;
  late final Animation<Offset> _labelSlide;
  late final Animation<double> _labelOpacity;
  late final Animation<double> _ringOpacity;
  late final Animation<double> _ringScale;

  @override
  void initState() {
    super.initState();
    _phoneCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _labelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _phoneScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _phoneCtrl, curve: Curves.easeOutBack),
    );
    _phoneOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _phoneCtrl, curve: const Interval(0.0, 0.45)),
    );
    _ringOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1),
    ]).animate(_ringCtrl);
    _ringScale = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut),
    );
    _flashOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.85), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 0.0), weight: 2),
    ]).animate(_flashCtrl);
    _labelSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _labelCtrl, curve: Curves.easeOut));
    _labelOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _labelCtrl, curve: const Interval(0.0, 0.6)),
    );

    if (widget.active) _play();
  }

  @override
  void didUpdateWidget(covariant _CaptureIllustration old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _play();
  }

  Future<void> _play() async {
    if (!mounted) return;
    _phoneCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    _ringCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _flashCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 60));
    if (!mounted) return;
    _labelCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _ringCtrl.dispose();
    _flashCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Center(
      child: ScaleTransition(
        scale: _phoneScale,
        child: FadeTransition(
          opacity: _phoneOpacity,
          child: SizedBox(
            width: 190,
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Phone frame
                Container(
                  width: 190,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: t.goldBorderStrong, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: t.gold.withValues(alpha: 0.18),
                        blurRadius: 36,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Stack(
                      children: [
                        // Dark background + beer
                        Container(
                          color: const Color(0xFF1A120A),
                          child: const Center(
                            child: Text(
                              '🍺',
                              style: TextStyle(fontSize: 72),
                            ),
                          ),
                        ),
                        // Flash
                        FadeTransition(
                          opacity: _flashOpacity,
                          child: Container(color: Colors.white),
                        ),
                        // Beer type label
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: SlideTransition(
                            position: _labelSlide,
                            child: FadeTransition(
                              opacity: _labelOpacity,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(12, 20, 12, 14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.85),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: t.gold,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Hazy Pale',
                                        style: TextStyle(
                                          color: t.goldInk,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Focus ring
                ScaleTransition(
                  scale: _ringScale,
                  child: FadeTransition(
                    opacity: _ringOpacity,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: t.gold, width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Illustration 3: Feed ────────────────────────────────────────────────

class _FeedIllustration extends StatefulWidget {
  final bool active;
  const _FeedIllustration({required this.active});

  @override
  State<_FeedIllustration> createState() => _FeedIllustrationState();
}

class _FeedIllustrationState extends State<_FeedIllustration>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<Offset>> _slides;
  late final List<Animation<double>> _opacities;

  static const _cards = [
    (emoji: '🍺', initials: 'S', name: 'sam', drink: 'Weizen Bock', reactions: '4'),
    (emoji: '🍻', initials: 'M', name: 'maya', drink: 'Hazy IPA', reactions: '7'),
    (emoji: '🍺', initials: 'T', name: 'theo', drink: 'Stout', reactions: '2'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      _cards.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 420),
      ),
    );
    _slides = _ctrls
        .map(
          (c) => Tween<Offset>(
            begin: const Offset(0, 0.7),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic)),
        )
        .toList();
    _opacities = _ctrls
        .map(
          (c) => Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: c, curve: const Interval(0.0, 0.55)),
          ),
        )
        .toList();

    if (widget.active) _play();
  }

  @override
  void didUpdateWidget(covariant _FeedIllustration old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _play();
  }

  Future<void> _play() async {
    for (int i = 0; i < _ctrls.length; i++) {
      if (!mounted) return;
      _ctrls[i].forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 140));
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < _cards.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          SlideTransition(
            position: _slides[i],
            child: FadeTransition(
              opacity: _opacities[i],
              child: _MockPostCard(
                t: t,
                emoji: _cards[i].emoji,
                initials: _cards[i].initials,
                name: _cards[i].name,
                drink: _cards[i].drink,
                reactions: _cards[i].reactions,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MockPostCard extends StatelessWidget {
  final PintTheme t;
  final String emoji;
  final String initials;
  final String name;
  final String drink;
  final String reactions;

  const _MockPostCard({
    required this.t,
    required this.emoji,
    required this.initials,
    required this.name,
    required this.drink,
    required this.reactions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.goldFaint,
              border: Border.all(color: t.goldBorder),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: t.goldText,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@$name',
                  style: TextStyle(
                    color: t.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$emoji $drink',
                  style: TextStyle(
                    color: t.textMuted,
                    fontSize: 12,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: t.surfaceWeak,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: t.border),
            ),
            child: Text(
              '$reactions 🍺',
              style: TextStyle(
                color: t.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Illustration 4: Leaderboard ─────────────────────────────────────────

class _LeaderboardIllustration extends StatefulWidget {
  final bool active;
  const _LeaderboardIllustration({required this.active});

  @override
  State<_LeaderboardIllustration> createState() =>
      _LeaderboardIllustrationState();
}

class _LeaderboardIllustrationState extends State<_LeaderboardIllustration>
    with TickerProviderStateMixin {
  late final List<AnimationController> _rowCtrls;
  late final AnimationController _countCtrl;

  late final List<Animation<Offset>> _rowSlides;
  late final List<Animation<double>> _rowOpacities;
  late final Animation<double> _countAnim;

  static const _rows = [
    (rank: 1, name: 'du', count: 47, medal: '🥇', isMe: true),
    (rank: 2, name: 'sam', count: 34, medal: '🥈', isMe: false),
    (rank: 3, name: 'maya', count: 29, medal: '🥉', isMe: false),
  ];

  @override
  void initState() {
    super.initState();
    _rowCtrls = List.generate(
      _rows.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _countCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _rowSlides = _rowCtrls
        .map(
          (c) => Tween<Offset>(
            begin: const Offset(0.45, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic)),
        )
        .toList();
    _rowOpacities = _rowCtrls
        .map(
          (c) => Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: c, curve: const Interval(0.0, 0.5)),
          ),
        )
        .toList();
    _countAnim = Tween<double>(begin: 0, end: 47).animate(
      CurvedAnimation(parent: _countCtrl, curve: Curves.easeOutCubic),
    );

    if (widget.active) _play();
  }

  @override
  void didUpdateWidget(covariant _LeaderboardIllustration old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _play();
  }

  Future<void> _play() async {
    for (int i = 0; i < _rowCtrls.length; i++) {
      if (!mounted) return;
      _rowCtrls[i].forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 130));
    }
    if (!mounted) return;
    _countCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    for (final c in _rowCtrls) {
      c.dispose();
    }
    _countCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < _rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          SlideTransition(
            position: _rowSlides[i],
            child: FadeTransition(
              opacity: _rowOpacities[i],
              child: _LeaderboardRow(
                t: t,
                medal: _rows[i].medal,
                name: _rows[i].name,
                countAnim: _rows[i].isMe ? _countAnim : null,
                staticCount: _rows[i].isMe ? null : _rows[i].count,
                isMe: _rows[i].isMe,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final PintTheme t;
  final String medal;
  final String name;
  final Animation<double>? countAnim;
  final int? staticCount;
  final bool isMe;

  const _LeaderboardRow({
    required this.t,
    required this.medal,
    required this.name,
    this.countAnim,
    this.staticCount,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? t.goldFaint : t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isMe ? t.goldBorder : t.border),
      ),
      child: Row(
        children: [
          Text(medal, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMe ? t.gold : t.surfaceWeak,
              border: Border.all(
                color: isMe ? t.goldBorderStrong : t.border,
              ),
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: TextStyle(
                  color: isMe ? t.goldInk : t.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '@$name',
              style: TextStyle(
                color: t.text,
                fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14,
                letterSpacing: -0.1,
              ),
            ),
          ),
          if (countAnim != null)
            AnimatedBuilder(
              animation: countAnim!,
              builder: (_, __) => Text(
                '${countAnim!.value.toInt()} 🍺',
                style: TextStyle(
                  color: t.goldText,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: -0.2,
                ),
              ),
            )
          else
            Text(
              '$staticCount 🍺',
              style: TextStyle(
                color: t.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: -0.2,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Illustration 5: Stats ───────────────────────────────────────────────

class _StatsIllustration extends StatefulWidget {
  final bool active;
  const _StatsIllustration({required this.active});

  @override
  State<_StatsIllustration> createState() => _StatsIllustrationState();
}

class _StatsIllustrationState extends State<_StatsIllustration>
    with TickerProviderStateMixin {
  late final List<AnimationController> _barCtrls;
  late final AnimationController _summaryCtrl;
  late final List<Animation<double>> _barAnims;
  late final Animation<Offset> _summarySlide;
  late final Animation<double> _summaryOpacity;

  static const _values = [0.35, 0.6, 0.5, 1.0, 0.75, 0.85, 0.45];
  static const _days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  @override
  void initState() {
    super.initState();
    _barCtrls = List.generate(
      _values.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 420),
      ),
    );
    _summaryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _barAnims = List.generate(_values.length, (i) {
      return Tween<double>(begin: 0.0, end: _values[i]).animate(
        CurvedAnimation(parent: _barCtrls[i], curve: Curves.easeOutCubic),
      );
    });
    _summarySlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _summaryCtrl, curve: Curves.easeOutCubic),
    );
    _summaryOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _summaryCtrl, curve: const Interval(0.0, 0.6)),
    );

    if (widget.active) _play();
  }

  @override
  void didUpdateWidget(covariant _StatsIllustration old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _play();
  }

  Future<void> _play() async {
    for (int i = 0; i < _barCtrls.length; i++) {
      if (!mounted) return;
      _barCtrls[i].forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 65));
    }
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _summaryCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    for (final c in _barCtrls) {
      c.dispose();
    }
    _summaryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    const maxBarH = 130.0;
    const barW = 30.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: t.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: t.isDark ? 0.25 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Diese Woche',
                    style: TextStyle(
                      color: t.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: t.goldSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: t.goldBorder),
                    ),
                    child: Text(
                      'Freunde',
                      style: TextStyle(
                        color: t.goldText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: maxBarH + 22,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (int i = 0; i < _values.length; i++)
                      _StatsBar(
                        anim: _barAnims[i],
                        label: _days[i],
                        maxHeight: maxBarH,
                        width: barW,
                        highlight: i == 3,
                        t: t,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SlideTransition(
          position: _summarySlide,
          child: FadeTransition(
            opacity: _summaryOpacity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatsPill(t: t, value: '5 🍺', label: 'Diese Woche'),
                const SizedBox(width: 8),
                _StatsPill(t: t, value: '🔥 4', label: 'Streak'),
                const SizedBox(width: 8),
                _StatsPill(t: t, value: '47 🍺', label: 'Gesamt'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsBar extends StatelessWidget {
  final Animation<double> anim;
  final String label;
  final double maxHeight;
  final double width;
  final bool highlight;
  final PintTheme t;

  const _StatsBar({
    required this.anim,
    required this.label,
    required this.maxHeight,
    required this.width,
    required this.highlight,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: width,
            height: maxHeight * anim.value,
            decoration: BoxDecoration(
              color: highlight ? t.gold : t.goldFaint,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: highlight ? t.goldBorderStrong : t.goldBorder,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: highlight ? t.goldText : t.textFaint,
              fontSize: 10,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsPill extends StatelessWidget {
  final PintTheme t;
  final String value;
  final String label;

  const _StatsPill({
    required this.t,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: t.text,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: t.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Illustration 6: Find friends ────────────────────────────────────────

class _FindFriendsIllustration extends StatefulWidget {
  final bool active;
  const _FindFriendsIllustration({required this.active});

  @override
  State<_FindFriendsIllustration> createState() =>
      _FindFriendsIllustrationState();
}

class _FindFriendsIllustrationState extends State<_FindFriendsIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _searchCtrl;
  late final List<AnimationController> _rowCtrls;

  late final Animation<Offset> _searchSlide;
  late final Animation<double> _searchOpacity;
  late final List<Animation<Offset>> _rowSlides;
  late final List<Animation<double>> _rowOpacities;

  static const _people = [
    (initials: 'S', name: 'sam'),
    (initials: 'M', name: 'maya'),
    (initials: 'T', name: 'theo'),
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _rowCtrls = List.generate(
      _people.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );

    _searchSlide = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _searchCtrl, curve: Curves.easeOutBack));
    _searchOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _searchCtrl, curve: const Interval(0.0, 0.5)),
    );

    _rowSlides = _rowCtrls
        .map(
          (c) => Tween<Offset>(
            begin: const Offset(0, 0.6),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic)),
        )
        .toList();
    _rowOpacities = _rowCtrls
        .map(
          (c) => Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: c, curve: const Interval(0.0, 0.55)),
          ),
        )
        .toList();

    if (widget.active) _play();
  }

  @override
  void didUpdateWidget(covariant _FindFriendsIllustration old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _play();
  }

  Future<void> _play() async {
    if (!mounted) return;
    _searchCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 280));
    for (int i = 0; i < _rowCtrls.length; i++) {
      if (!mounted) return;
      _rowCtrls[i].forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 130));
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    for (final c in _rowCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SlideTransition(
          position: _searchSlide,
          child: FadeTransition(
            opacity: _searchOpacity,
            child: _MockSearchBar(t: t),
          ),
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < _people.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          SlideTransition(
            position: _rowSlides[i],
            child: FadeTransition(
              opacity: _rowOpacities[i],
              child: _FriendSuggestionRow(
                t: t,
                initials: _people[i].initials,
                name: _people[i].name,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MockSearchBar extends StatelessWidget {
  final PintTheme t;
  const _MockSearchBar({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.goldBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: t.textMuted),
          const SizedBox(width: 10),
          Text(
            'Freunde suchen…',
            style: TextStyle(
              color: t.textFaint,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendSuggestionRow extends StatelessWidget {
  final PintTheme t;
  final String initials;
  final String name;

  const _FriendSuggestionRow({
    required this.t,
    required this.initials,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.goldFaint,
              border: Border.all(color: t.goldBorder),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: t.goldText,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '@$name',
              style: TextStyle(
                color: t.text,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: -0.1,
              ),
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.gold,
            ),
            child: Icon(Icons.add, size: 18, color: t.goldInk),
          ),
        ],
      ),
    );
  }
}

// ─── UI hint overlay ──────────────────────────────────────────────────────

class _HintOverlay extends StatefulWidget {
  final int page;
  const _HintOverlay({required this.page});

  @override
  State<_HintOverlay> createState() => _HintOverlayState();
}

class _HintOverlayState extends State<_HintOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final padTop = mq.padding.top;
    final padBottom = mq.padding.bottom;

    Widget child;
    switch (widget.page) {
      case 1: // Capture → centre bottom-nav tab
        child = _BottomTabHint(
          key: const ValueKey(1),
          pulse: _pulse, t: t,
          icon: Icons.camera_alt_outlined, label: 'Zapfen',
          left: sw * 2 / 5, tabWidth: sw / 5, bottom: padBottom,
        );
      case 2: // Feed → first bottom-nav tab
        child = _BottomTabHint(
          key: const ValueKey(2),
          pulse: _pulse, t: t,
          icon: Icons.grid_view, label: 'Feed',
          left: 0, tabWidth: sw / 5, bottom: padBottom,
        );
      case 3: // Leaderboard → top-bar trophy button (3rd from right: bell+theme+stats+lb = right:150)
        child = _TopBtnHint(
          key: const ValueKey(3),
          pulse: _pulse, t: t,
          icon: Icons.emoji_events_rounded, iconColor: t.goldText,
          right: 150, top: padTop + 8,
        );
      case 4: // Stats → top-bar bar-chart button (2nd from right after bell+theme = right:106)
        child = _TopBtnHint(
          key: const ValueKey(4),
          pulse: _pulse, t: t,
          icon: Icons.bar_chart_rounded, iconColor: t.text,
          right: 106, top: padTop + 8,
        );
      case 5: // Friends → 4th bottom-nav tab
        child = _BottomTabHint(
          key: const ValueKey(5),
          pulse: _pulse, t: t,
          icon: Icons.people, label: 'Freunde',
          left: sw * 3 / 5, tabWidth: sw / 5, bottom: padBottom,
        );
      default:
        child = const SizedBox.shrink(key: ValueKey(-1));
    }

    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: child,
      ),
    );
  }
}

// ─── Top-bar button hint ──────────────────────────────────────────────────

class _TopBtnHint extends StatelessWidget {
  final AnimationController pulse;
  final PintTheme t;
  final IconData icon;
  final Color iconColor;
  final double right;
  final double top;

  const _TopBtnHint({
    super.key,
    required this.pulse,
    required this.t,
    required this.icon,
    required this.iconColor,
    required this.right,
    required this.top,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Pulse ring (centred on button: ring 48×48, button 36×36 → offset by -6)
        Positioned(
          right: right - 6,
          top: top - 6,
          child: AnimatedBuilder(
            animation: pulse,
            builder: (_, __) => Opacity(
              opacity: (1 - pulse.value).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 1.0 + 0.55 * pulse.value,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: t.gold, width: 2),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Button replica
        Positioned(
          right: right,
          top: top,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.surfaceWeak,
              border: Border.all(color: t.border),
              boxShadow: [
                BoxShadow(
                  color: t.gold.withValues(alpha: 0.4),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
        ),
      ],
    );
  }
}

// ─── Bottom-nav tab hint ──────────────────────────────────────────────────

class _BottomTabHint extends StatelessWidget {
  final AnimationController pulse;
  final PintTheme t;
  final IconData icon;
  final String label;
  final double left;
  final double tabWidth;
  final double bottom;

  const _BottomTabHint({
    super.key,
    required this.pulse,
    required this.t,
    required this.icon,
    required this.label,
    required this.left,
    required this.tabWidth,
    required this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    // Icon centre inside the 56px tab:
    // Column centred → content ~44px → top offset ~6px → icon at 6 + 5(pad) + 11(half icon) = 22px from top
    // From bottom: 56 - 22 = 34px
    const tabH = 56.0;
    const ringSize = 48.0;
    final ringLeft = left + tabWidth / 2 - ringSize / 2;

    return Stack(
      children: [
        // Tab replica
        Positioned(
          left: left,
          bottom: bottom,
          width: tabWidth,
          height: tabH,
          child: Container(
            decoration: BoxDecoration(
              color: t.bg,
              border: Border(top: BorderSide(color: t.border)),
              boxShadow: [
                BoxShadow(
                  color: t.gold.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: t.goldSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(icon, size: 22, color: t.goldText),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: t.goldText,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Pulse ring centred on the icon
        Positioned(
          left: ringLeft,
          bottom: bottom + tabH - 34 - ringSize / 2,
          child: AnimatedBuilder(
            animation: pulse,
            builder: (_, __) => Opacity(
              opacity: (1 - pulse.value).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 1.0 + 0.55 * pulse.value,
                child: Container(
                  width: ringSize,
                  height: ringSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: t.gold, width: 2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
