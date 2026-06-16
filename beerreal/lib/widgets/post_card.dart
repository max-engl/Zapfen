import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_cache_manager.dart';
import '../core/geocoding_service.dart';
import '../theme.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/posts/models/feed_post.dart';
import '../features/posts/models/post_reaction.dart';
import '../features/posts/models/selfie_reaction.dart';
import 'avatar.dart';
import 'report_post_sheet.dart';

class PostCard extends StatelessWidget {
  final FeedPost post;
  final void Function(String emoji) onReact;
  final VoidCallback onSelfieReact;
  final Future<void> Function(String reactionId) onRemoveSelfieReaction;
  final VoidCallback? onProfileTap;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final String heroTagPrefix;
  final bool enableHero;

  const PostCard({
    super.key,
    required this.post,
    required this.onReact,
    required this.onSelfieReact,
    required this.onRemoveSelfieReaction,
    this.onProfileTap,
    this.onTap,
    this.onDelete,
    this.heroTagPrefix = '',
    this.enableHero = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            post: post,
            t: t,
            onProfileTap: onProfileTap,
            onDelete: onDelete,
          ),
          const SizedBox(height: 10),
          _Photo(
            post: post,
            t: t,
            onTap: onTap,
            onDoubleTap: () => onReact('🍺'),
            heroTagPrefix: heroTagPrefix,
            enableHero: enableHero,
          ),
          if (post.caption.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Caption(post: post, t: t),
          ],
          const SizedBox(height: 12),
          _Actions(
            post: post,
            onReact: onReact,
            onSelfieReact: onSelfieReact,
            onRemoveSelfieReaction: onRemoveSelfieReaction,
            onTap: onTap,
            t: t,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final FeedPost post;
  final PintTheme t;
  final VoidCallback? onProfileTap;
  final VoidCallback? onDelete;
  const _Header({
    required this.post,
    required this.t,
    this.onProfileTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onProfileTap,
          child: Row(
            children: [
              _LiveAvatar(post: post, size: 36, t: t),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.username,
                    style: TextStyle(
                      color: t.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.14,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        post.formattedDateTime,
                        style: TextStyle(color: t.textMuted, fontSize: 12),
                      ),
                      if (post.lat != null && post.lng != null)
                        FutureBuilder<String?>(
                          future: GeocodingService.cityName(
                            post.lat!,
                            post.lng!,
                          ),
                          builder: (_, snap) {
                            final city = snap.data;
                            if (city == null) return const SizedBox.shrink();
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ' · ',
                                  style: TextStyle(
                                    color: t.textFaint,
                                    fontSize: 12,
                                  ),
                                ),
                                Icon(
                                  Icons.place_outlined,
                                  size: 11,
                                  color: t.textFaint,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  city,
                                  style: TextStyle(
                                    color: t.textFaint,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                  if (post.drinkLabel.isNotEmpty || post.rating != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (post.drinkLabel.isNotEmpty)
                          Text(
                            post.drinkLabel,
                            style: TextStyle(
                              color: t.goldText,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.1,
                            ),
                          ),
                        if (post.drinkLabel.isNotEmpty &&
                            post.rating != null) ...[
                          Text(
                            ' · ',
                            style: TextStyle(color: t.textFaint, fontSize: 11),
                          ),
                        ],
                        if (post.rating != null)
                          _RatingStars(rating: post.rating!, size: 11),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _showOptionsSheet(context),
          child: Icon(Icons.more_horiz, color: t.textMuted, size: 20),
        ),
      ],
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showPostOptionsSheet(context, post: post, onDelete: onDelete);
  }
}

class _Photo extends StatefulWidget {
  final FeedPost post;
  final PintTheme t;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final String heroTagPrefix;
  final bool enableHero;
  const _Photo({
    required this.post,
    required this.t,
    this.onTap,
    this.onDoubleTap,
    this.heroTagPrefix = '',
    this.enableHero = true,
  });

  @override
  State<_Photo> createState() => _PhotoState();
}

class _LiveAvatar extends StatelessWidget {
  final FeedPost post;
  final double size;
  final PintTheme t;

  const _LiveAvatar({required this.post, required this.size, required this.t});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PintAvatar(
          size: size,
          imageUrl: post.avatarUrl,
          avatarColor: post.avatarColor,
          initials: post.avatarInitial,
        ),
        if (post.drinkingNow)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: t.bg, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _PhotoState extends State<_Photo> with SingleTickerProviderStateMixin {
  bool _swapped = false;
  bool _cheersBurst = false;
  late final AnimationController _cheersCtrl;
  late final Animation<double> _cheersScale;
  late final Animation<double> _cheersOpacity;

  @override
  void initState() {
    super.initState();
    _cheersCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _cheersScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.3,
          end: 2.2,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 45,
      ),
      TweenSequenceItem(tween: ConstantTween(2.2), weight: 20),
      TweenSequenceItem(
        tween: Tween(
          begin: 2.2,
          end: 1.6,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 35,
      ),
    ]).animate(_cheersCtrl);
    _cheersOpacity = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _cheersCtrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    _cheersCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _cheersBurst = false);
        _cheersCtrl.reset();
      }
    });
  }

  @override
  void dispose() {
    _cheersCtrl.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    widget.onDoubleTap?.call();
    setState(() => _cheersBurst = true);
    _cheersCtrl.forward(from: 0);
    HapticFeedback.heavyImpact();
  }

  static const _overlayW = 80.0;
  static const _overlayH = 107.0;
  static const _pad = 12.0;

  Offset? _selfiePos;
  bool _dragging = false;

  Offset _snapToCorner(Offset pos, Size size) {
    final cx = pos.dx + _overlayW / 2;
    final cy = pos.dy + _overlayH / 2;
    return Offset(
      cx < size.width / 2 ? _pad : size.width - _overlayW - _pad,
      cy < size.height / 2 ? _pad : size.height - _overlayH - _pad,
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final t = widget.t;
    final hasSelfie = post.selfieUrl.isNotEmpty;
    final myUserId = context.watch<AuthProvider>().user?.id;

    final mainUrl = _swapped ? post.selfieUrl : post.imageUrl;
    final mainKey = _swapped
        ? (post.selfiePath ?? '${post.id}_selfie')
        : (post.imagePath ?? post.id);
    final overlayUrl = _swapped ? post.imageUrl : post.selfieUrl;
    final overlayKey = _swapped
        ? (post.imagePath ?? post.id)
        : (post.selfiePath ?? '${post.id}_selfie');

    final image = mainUrl.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: mainUrl,
            cacheKey: mainKey,
            cacheManager: AppCacheManager.instance,
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            errorWidget: (_, __, ___) => Container(color: t.surfaceWeak),
          )
        : Container(color: t.surfaceWeak);

    final mainImage = widget.enableHero
        ? Hero(
            tag: '${widget.heroTagPrefix}post_image_${post.id}',
            child: image,
          )
        : image;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            _selfiePos ??= const Offset(_pad, _pad);

            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: widget.onTap,
                    onDoubleTap: widget.onDoubleTap != null
                        ? _onDoubleTap
                        : null,
                    child: mainImage,
                  ),
                ),
                if (_cheersBurst)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: FadeTransition(
                          opacity: _cheersOpacity,
                          child: ScaleTransition(
                            scale: _cheersScale,
                            child: Opacity(
                              opacity: 0.85,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Image.asset(
                                  'assets/icons/app_icon.png',
                                  width: 80,
                                  height: 80,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (hasSelfie)
                  AnimatedPositioned(
                    duration: _dragging
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    left: _selfiePos!.dx,
                    top: _selfiePos!.dy,
                    child: RawGestureDetector(
                      behavior: HitTestBehavior.opaque,
                      gestures: {
                        ImmediateMultiDragGestureRecognizer:
                            GestureRecognizerFactoryWithHandlers<
                              ImmediateMultiDragGestureRecognizer
                            >(
                              () => ImmediateMultiDragGestureRecognizer(
                                debugOwner: this,
                              ),
                              (instance) {
                                instance.onStart = (Offset _) {
                                  setState(() => _dragging = true);
                                  return _SelfieDrag(
                                    onMove: (delta) => setState(() {
                                      _selfiePos = Offset(
                                        (_selfiePos!.dx + delta.dx).clamp(
                                          0.0,
                                          size.width - _overlayW,
                                        ),
                                        (_selfiePos!.dy + delta.dy).clamp(
                                          0.0,
                                          size.height - _overlayH,
                                        ),
                                      );
                                    }),
                                    onEnd: (_) => setState(() {
                                      _dragging = false;
                                      _selfiePos = _snapToCorner(
                                        _selfiePos!,
                                        size,
                                      );
                                    }),
                                    onCancel: () => setState(() {
                                      _dragging = false;
                                      _selfiePos = _snapToCorner(
                                        _selfiePos!,
                                        size,
                                      );
                                    }),
                                  );
                                };
                              },
                            ),
                      },
                      child: GestureDetector(
                        onTap: () => setState(() => _swapped = !_swapped),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.7),
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x40000000),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: _overlayW,
                              height: _overlayH,
                              child: overlayUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: overlayUrl,
                                      cacheKey: overlayKey,
                                      cacheManager: AppCacheManager.instance,
                                      fit: BoxFit.cover,
                                      fadeInDuration: Duration.zero,
                                      errorWidget: (_, __, ___) =>
                                          Container(color: t.surfaceWeak),
                                    )
                                  : Container(color: t.surfaceWeak),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (post.selfieReactions.isNotEmpty)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: SelfieAvatarStack(
                      reactions: post.selfieReactions,
                      myUserId: myUserId,
                      t: t,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  final FeedPost post;
  final PintTheme t;
  const _Caption({required this.post, required this.t});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '@${post.username} ',
            style: TextStyle(
              color: t.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
          TextSpan(
            text: post.caption,
            style: TextStyle(
              color: t.text.withValues(alpha: 0.9),
              fontSize: 14,
              letterSpacing: -0.1,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  final int rating;
  final double size;

  const _RatingStars({required this.rating, this.size = 12});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: filled ? const Color(0xFFF6B733) : const Color(0x4DFFFFFF),
        );
      }),
    );
  }
}

class _Actions extends StatelessWidget {
  final FeedPost post;
  final void Function(String emoji) onReact;
  final VoidCallback onSelfieReact;
  final Future<void> Function(String reactionId) onRemoveSelfieReaction;
  final VoidCallback? onTap;
  final PintTheme t;

  const _Actions({
    required this.post,
    required this.onReact,
    required this.onSelfieReact,
    required this.onRemoveSelfieReaction,
    required this.t,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final myUserId = context.watch<AuthProvider>().user?.id;
    final mySelfie = post.mySelfieReaction(myUserId);
    final cheersCount = post.reactions
        .firstWhere(
          (r) => r.emoji == '🍺',
          orElse: () => const PostReaction(emoji: '🍺', count: 0),
        )
        .count;

    return Row(
      children: [
        CheersButton(
          count: cheersCount,
          isSelected: post.myReaction == '🍺',
          onTap: () {
            HapticFeedback.selectionClick();
            onReact('🍺');
          },
          t: t,
        ),
        const SizedBox(width: 10),
        SelfieReactButton(
          mySelfie: mySelfie,
          onOpenCapture: onSelfieReact,
          onRemove: onRemoveSelfieReaction,
          t: t,
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 34),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: t.surfaceWeak,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: t.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline, size: 14, color: t.text),
                const SizedBox(width: 6),
                Text(
                  '${post.comments}',
                  style: TextStyle(
                    color: t.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

// ── Selfie reaction button ──────────────────────────────────────────────────

class SelfieReactButton extends StatefulWidget {
  final SelfieReaction? mySelfie;
  final VoidCallback onOpenCapture;
  final Future<void> Function(String reactionId) onRemove;
  final PintTheme t;

  const SelfieReactButton({
    super.key,
    required this.mySelfie,
    required this.onOpenCapture,
    required this.onRemove,
    required this.t,
  });

  @override
  State<SelfieReactButton> createState() => _SelfieReactButtonState();
}

class _SelfieReactButtonState extends State<SelfieReactButton> {
  bool _busy = false;

  Future<void> _handleTap() async {
    if (_busy) return;
    HapticFeedback.selectionClick();
    final mySelfie = widget.mySelfie;
    if (mySelfie == null) {
      widget.onOpenCapture();
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onRemove(mySelfie.id);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final isActive = widget.mySelfie != null;
    return BounceTap(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 34),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? t.goldSoft : t.surfaceWeak,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isActive ? t.goldBorderStrong : t.border),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: Row(
            key: ValueKey(isActive),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.face_retouching_natural_outlined,
                size: 15,
                color: isActive ? t.goldText : t.text,
              ),
              const SizedBox(width: 6),
              Text(
                isActive ? 'Reagiert' : 'Selfie',
                style: TextStyle(
                  color: isActive ? t.goldText : t.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Selfie reaction avatar stack ────────────────────────────────────────────

class _SelfieStackEntrance extends StatelessWidget {
  final int index;
  final Widget child;

  const _SelfieStackEntrance({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(index),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + index * 70),
      curve: Curves.easeOutBack,
      builder: (_, value, child) {
        final opacity = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - opacity)),
            child: Transform.scale(scale: 0.72 + (0.28 * value), child: child),
          ),
        );
      },
      child: child,
    );
  }
}

class SelfieAvatarStack extends StatelessWidget {
  final List<SelfieReaction> reactions;
  final String? myUserId;
  final PintTheme t;
  final int maxVisible;

  const SelfieAvatarStack({
    super.key,
    required this.reactions,
    required this.myUserId,
    required this.t,
    this.maxVisible = 3,
  });

  static const _circleSize = 46.0;
  static const _overlap = 28.0;

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();
    final visibleCount = maxVisible.clamp(1, reactions.length);
    final overflow = reactions.length > visibleCount
        ? reactions.length - visibleCount
        : 0;
    final display = overflow > 0
        ? reactions.sublist(reactions.length - visibleCount)
        : reactions;
    final slots = display.length + (overflow > 0 ? 1 : 0);
    final width = _circleSize + (slots - 1) * _overlap;

    final children = <Widget>[];
    if (overflow > 0) {
      children.add(
        Positioned(
          right: display.length * _overlap,
          bottom: 0,
          child: _SelfieStackEntrance(
            index: 0,
            child: _OverflowBadge(count: overflow),
          ),
        ),
      );
    }
    for (var i = 0; i < display.length; i++) {
      final s = display[i];
      final isMine = myUserId != null && s.userId == myUserId;
      children.add(
        Positioned(
          right: (display.length - 1 - i) * _overlap,
          bottom: 0,
          child: _SelfieStackEntrance(
            index: i + (overflow > 0 ? 1 : 0),
            child: _SelfieAvatarCircle(
              reaction: s,
              isMine: isMine,
              t: t,
              onTap: () {
                final index = reactions.indexWhere((r) => r.id == s.id);
                _showSelfieReactionPreview(
                  context,
                  reactions,
                  index < 0 ? 0 : index,
                  t,
                );
              },
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: _circleSize,
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }
}

class _SelfieAvatarCircle extends StatelessWidget {
  final SelfieReaction reaction;
  final bool isMine;
  final PintTheme t;
  final VoidCallback onTap;

  const _SelfieAvatarCircle({
    required this.reaction,
    required this.isMine,
    required this.t,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BounceTap(
      onTap: onTap,
      child: Container(
        width: SelfieAvatarStack._circleSize,
        height: SelfieAvatarStack._circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: t.surfaceWeak,
          border: Border.all(
            color: isMine ? t.gold : Colors.black,
            width: isMine ? 3 : 2,
          ),
        ),
        child: ClipOval(
          child: reaction.imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: reaction.imageUrl,
                  cacheKey: reaction.cacheKey,
                  cacheManager: AppCacheManager.instance,
                  fit: BoxFit.cover,
                  fadeInDuration: Duration.zero,
                  errorWidget: (_, __, ___) => Container(color: t.surfaceWeak),
                )
              : Container(color: t.surfaceWeak),
        ),
      ),
    );
  }
}

void _showSelfieReactionPreview(
  BuildContext context,
  List<SelfieReaction> reactions,
  int initialIndex,
  PintTheme t,
) {
  if (reactions.isEmpty) return;
  HapticFeedback.selectionClick();
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.82),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (dialogContext, _, __) => _SelfieReactionPreviewGallery(
      reactions: reactions,
      initialIndex: initialIndex.clamp(0, reactions.length - 1),
      t: t,
      onClose: () => Navigator.of(dialogContext).pop(),
    ),
    transitionBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _SelfieReactionPreviewGallery extends StatefulWidget {
  final List<SelfieReaction> reactions;
  final int initialIndex;
  final PintTheme t;
  final VoidCallback onClose;

  const _SelfieReactionPreviewGallery({
    required this.reactions,
    required this.initialIndex,
    required this.t,
    required this.onClose,
  });

  @override
  State<_SelfieReactionPreviewGallery> createState() =>
      _SelfieReactionPreviewGalleryState();
}

class _SelfieReactionPreviewGalleryState
    extends State<_SelfieReactionPreviewGallery> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reactions = widget.reactions;
    final t = widget.t;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onClose,
      child: SafeArea(
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: LayoutBuilder(
              builder: (context, constraints) {
                final avatarSize = constraints.maxWidth < 396
                    ? constraints.maxWidth - 56
                    : 340.0;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: avatarSize,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: reactions.length,
                        onPageChanged: (value) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _index = value;
                          });
                        },
                        itemBuilder: (_, index) => Center(
                          child: SizedBox(
                            width: avatarSize,
                            height: avatarSize,
                            child: _LargeSelfieReaction(
                              reaction: reactions[index],
                              t: t,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child: Text(
                        reactions[_index].username.isEmpty
                            ? ''
                            : '@${reactions[_index].username}',
                        key: ValueKey(reactions[_index].id),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    if (reactions.length > 1) ...[
                      const SizedBox(height: 10),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 160),
                        child: Text(
                          '${_index + 1} / ${reactions.length}',
                          key: ValueKey(_index),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.62),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LargeSelfieReaction extends StatelessWidget {
  final SelfieReaction reaction;
  final PintTheme t;

  const _LargeSelfieReaction({required this.reaction, required this.t});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surfaceWeak,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: ClipOval(
        child: reaction.imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: reaction.imageUrl,
                cacheKey: reaction.cacheKey,
                cacheManager: AppCacheManager.instance,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                errorWidget: (_, __, ___) => Container(color: t.surfaceWeak),
              )
            : Container(color: t.surfaceWeak),
      ),
    );
  }
}

class _OverflowBadge extends StatelessWidget {
  final int count;
  const _OverflowBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: SelfieAvatarStack._circleSize,
      height: SelfieAvatarStack._circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xC7000000),
        border: Border.all(color: Colors.black, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '+$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Cheers button ─────────────────────────────────────────────────────────────

class CheersButton extends StatelessWidget {
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final PintTheme t;

  const CheersButton({
    super.key,
    required this.count,
    required this.isSelected,
    required this.onTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return BounceTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 34),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? t.goldSoft : t.surfaceWeak,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isSelected ? t.goldBorderStrong : t.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍺', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: TextStyle(
                color: isSelected ? t.goldText : t.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bounce-tap wrapper ────────────────────────────────────────────────────────

class BounceTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const BounceTap({super.key, required this.child, required this.onTap});

  @override
  State<BounceTap> createState() => _BounceTapState();
}

class _BounceTapState extends State<BounceTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.28,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.28,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _ctrl.forward(from: 0);
        widget.onTap();
      },
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

class _SelfieDrag extends Drag {
  _SelfieDrag({
    required this.onMove,
    required this.onEnd,
    required this.onCancel,
  });

  final void Function(Offset delta) onMove;
  final void Function(DragEndDetails details) onEnd;
  final VoidCallback onCancel;

  @override
  void update(DragUpdateDetails details) => onMove(details.delta);

  @override
  void end(DragEndDetails details) => onEnd(details);

  @override
  void cancel() => onCancel();
}
