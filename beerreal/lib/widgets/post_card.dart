import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_cache_manager.dart';
import 'pint_loading.dart';
import '../core/geocoding_service.dart';
import '../theme.dart';
import '../features/posts/models/feed_post.dart';
import '../features/posts/models/post_reaction.dart';
import '../features/posts/services/post_service.dart';
import 'avatar.dart';
import 'report_post_sheet.dart';

class PostCard extends StatelessWidget {
  final FeedPost post;
  final void Function(String emoji) onReact;
  final VoidCallback? onProfileTap;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final String heroTagPrefix;
  final bool enableHero;

  const PostCard({
    super.key,
    required this.post,
    required this.onReact,
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
          _Actions(post: post, onReact: onReact, onTap: onTap, t: t),
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
                        post.timeAgo,
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
        tween: Tween(begin: 0.3, end: 2.2)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 45,
      ),
      TweenSequenceItem(tween: ConstantTween(2.2), weight: 20),
      TweenSequenceItem(
        tween: Tween(begin: 2.2, end: 1.6)
            .chain(CurveTween(curve: Curves.easeIn)),
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
            _selfiePos ??= Offset(
              size.width - _overlayW - _pad,
              size.height - _overlayH - _pad,
            );

            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: widget.onTap,
                    onDoubleTap:
                        widget.onDoubleTap != null ? _onDoubleTap : null,
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
  final VoidCallback? onTap;
  final PintTheme t;

  const _Actions({
    required this.post,
    required this.onReact,
    required this.t,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: _QuickReactions(post: post, onReact: onReact, t: t),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onTap,
          child: Container(
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
        Text(post.timeAgo, style: TextStyle(color: t.textFaint, fontSize: 11)),
      ],
    );
  }
}

class _QuickReactions extends StatelessWidget {
  final FeedPost post;
  final void Function(String emoji) onReact;
  final PintTheme t;

  const _QuickReactions({
    required this.post,
    required this.onReact,
    required this.t,
  });

  void _showReactors(BuildContext context) {
    final svc = context.read<PostService>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ReactorsSheet(
        postId: post.id,
        reactions: post.reactions,
        postService: svc,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cheersCount = post.reactions
        .firstWhere(
          (r) => r.emoji == '🍺',
          orElse: () => const PostReaction(emoji: '🍺', count: 0),
        )
        .count;

    final activePills = <Widget>[];
    for (final emoji in kReactionEmojis.skip(1)) {
      final r = post.reactions.firstWhere(
        (r) => r.emoji == emoji,
        orElse: () => PostReaction(emoji: emoji, count: 0),
      );
      if (r.count == 0) continue;
      final isMine = post.myReaction == emoji;
      activePills
        ..add(const SizedBox(width: 6))
        ..add(
          BounceTap(
            onTap: () {
              HapticFeedback.selectionClick();
              onReact(emoji);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              constraints: const BoxConstraints(minHeight: 34),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: isMine ? t.goldSoft : t.surfaceWeak,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isMine ? t.goldBorderStrong : t.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    '${r.count}',
                    style: TextStyle(
                      color: isMine ? t.goldText : t.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
        ...activePills,
        if (post.myReaction == null) ...[
          const SizedBox(width: 6),
          ReactButton(
            emojis: kReactionEmojis.skip(1).toList(),
            myReaction: post.myReaction,
            onReact: onReact,
            t: t,
          ),
        ],
        if (post.totalReactions > 0) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _showReactors(context),
            child: Container(
              constraints: const BoxConstraints(minHeight: 34),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: t.surfaceWeak,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: t.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 14, color: t.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${post.totalReactions}',
                    style: TextStyle(
                      color: t.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
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
            if (count > 0) ...[
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
          ],
        ),
      ),
    );
  }
}

// ── React button with Apple-style emoji overlay ────────────────────────────────

class ReactButton extends StatefulWidget {
  final List<String> emojis;
  final String? myReaction;
  final void Function(String) onReact;
  final PintTheme t;

  const ReactButton({
    super.key,
    required this.emojis,
    required this.myReaction,
    required this.onReact,
    required this.t,
  });

  @override
  State<ReactButton> createState() => _ReactButtonState();
}

class _ReactButtonState extends State<ReactButton>
    with SingleTickerProviderStateMixin {
  final _key = GlobalKey();
  OverlayEntry? _entry;
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceScale;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _bounceScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.22)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.22, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_bounceCtrl);
  }

  void _show() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    _entry = OverlayEntry(
      builder: (_) => _EmojiPopup(
        buttonPos: pos,
        buttonSize: box.size,
        emojis: widget.emojis,
        myReaction: widget.myReaction,
        t: widget.t,
        onSelect: (emoji) {
          _hide();
          HapticFeedback.selectionClick();
          widget.onReact(emoji);
        },
        onDismiss: _hide,
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  void _hide() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasOtherReaction =
        widget.myReaction != null && widget.emojis.contains(widget.myReaction);
    return GestureDetector(
      key: _key,
      onTap: () {
        HapticFeedback.selectionClick();
        _bounceCtrl.forward(from: 0);
        _show();
      },
      child: ScaleTransition(
        scale: _bounceScale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 34),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: hasOtherReaction ? widget.t.goldSoft : widget.t.surfaceWeak,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: hasOtherReaction
                  ? widget.t.goldBorderStrong
                  : widget.t.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_reaction_outlined,
                size: 14,
                color:
                    hasOtherReaction ? widget.t.goldText : widget.t.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                'React',
                style: TextStyle(
                  color: hasOtherReaction ? widget.t.goldText : widget.t.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Apple-style emoji popup overlay ───────────────────────────────────────────

class _EmojiPopup extends StatefulWidget {
  final Offset buttonPos;
  final Size buttonSize;
  final List<String> emojis;
  final String? myReaction;
  final PintTheme t;
  final void Function(String) onSelect;
  final VoidCallback onDismiss;

  const _EmojiPopup({
    required this.buttonPos,
    required this.buttonSize,
    required this.emojis,
    required this.myReaction,
    required this.t,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  State<_EmojiPopup> createState() => _EmojiPopupState();
}

class _EmojiPopupState extends State<_EmojiPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const circleSize = 44.0;
    final n = widget.emojis.length;
    final popupW = n * circleSize + (n - 1) * 8.0 + 24.0;
    const popupH = circleSize + 20.0;
    const gap = 8.0;

    final screenW = MediaQuery.of(context).size.width;
    double left =
        widget.buttonPos.dx + widget.buttonSize.width / 2 - popupW / 2;
    left = left.clamp(12.0, screenW - popupW - 12.0);
    final top = widget.buttonPos.dy - popupH - gap;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onDismiss,
          ),
        ),
        Positioned(
          left: left,
          top: top,
          child: FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              alignment: Alignment.bottomCenter,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: widget.t.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: widget.t.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: widget.t.isDark ? 0.45 : 0.15,
                        ),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.emojis.asMap().entries.map((entry) {
                      final emoji = entry.value;
                      final isActive = widget.myReaction == emoji;
                      return Padding(
                        padding: EdgeInsets.only(
                          right: entry.key < widget.emojis.length - 1 ? 8 : 0,
                        ),
                        child: BounceTap(
                          onTap: () => widget.onSelect(emoji),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            width: circleSize,
                            height: circleSize,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? widget.t.goldSoft
                                  : widget.t.surfaceWeak,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isActive
                                    ? widget.t.goldBorderStrong
                                    : widget.t.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
        tween: Tween(begin: 1.0, end: 1.28)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.28, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
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

// ── Who reacted sheet ─────────────────────────────────────────────────────────

class ReactorsSheet extends StatefulWidget {
  final String postId;
  final List<PostReaction> reactions;
  final PostService postService;

  const ReactorsSheet({
    super.key,
    required this.postId,
    required this.reactions,
    required this.postService,
  });

  @override
  State<ReactorsSheet> createState() => ReactorsSheetState();
}

class ReactorsSheetState extends State<ReactorsSheet> {
  List<ReactionActor>? _actors;
  // null = "Alle" (show everyone), non-null = filter by that emoji
  String? _selectedEmoji;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final actors = await widget.postService.getPostReactions(widget.postId);
      if (mounted) setState(() => _actors = actors);
    } catch (_) {
      if (mounted) setState(() => _actors = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);

    final activeEmojis = kReactionEmojis
        .where((e) => widget.reactions.any((r) => r.emoji == e && r.count > 0))
        .toList();

    final filtered = _selectedEmoji == null
        ? _actors
        : _actors?.where((a) => a.emoji == _selectedEmoji).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: t.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            decoration: BoxDecoration(
              color: t.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
            child: Row(
              children: [
                Text(
                  'Reaktionen',
                  style: TextStyle(
                    color: t.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_actors != null && _actors!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: t.goldSoft,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: t.goldBorder),
                    ),
                    child: Text(
                      '${_actors!.length}',
                      style: TextStyle(
                        color: t.goldText,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Emoji filter tabs — only when multiple emoji types have reactions
          if (activeEmojis.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // "Alle" tab
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedEmoji = null),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedEmoji == null
                                ? t.goldSoft
                                : t.surfaceWeak,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: _selectedEmoji == null
                                  ? t.goldBorderStrong
                                  : t.border,
                            ),
                          ),
                          child: Text(
                            'Alle',
                            style: TextStyle(
                              color: _selectedEmoji == null
                                  ? t.goldText
                                  : t.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Individual emoji tabs
                    ...activeEmojis.map((emoji) {
                      final sel = emoji == _selectedEmoji;
                      final count = widget.reactions
                          .firstWhere((r) => r.emoji == emoji)
                          .count;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedEmoji = emoji),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: sel ? t.goldSoft : t.surfaceWeak,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: sel ? t.goldBorderStrong : t.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 15),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '$count',
                                  style: TextStyle(
                                    color: sel ? t.goldText : t.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

          Divider(height: 1, color: t.border),

          // User list
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: _actors == null
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: SpinningAppLogo(size: 24),
                  )
                : (filtered?.isEmpty ?? true)
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Text(
                      'Noch keine Reaktionen.',
                      style: TextStyle(color: t.textMuted, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered!.length,
                    itemBuilder: (_, i) {
                      final a = filtered[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            PintAvatar(
                              size: 38,
                              imageUrl: a.avatarUrl,
                              avatarColor: a.avatarColor,
                              initials: a.avatarInitial,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '@${a.username}',
                                style: TextStyle(
                                  color: t.text,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(a.emoji, style: const TextStyle(fontSize: 18)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
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
