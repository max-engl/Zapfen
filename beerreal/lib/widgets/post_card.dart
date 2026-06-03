import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_cache_manager.dart';
import '../core/geocoding_service.dart';
import '../theme.dart';
import '../features/posts/models/feed_post.dart';
import '../features/posts/models/post_reaction.dart';
import 'avatar.dart';
import 'report_post_sheet.dart';
import 'shimmer_box.dart';

// Keys of images that have been rendered at least once this session.
// Used to skip the shimmer placeholder on scroll-back.
final _renderedImageKeys = <String>{};

class PostCard extends StatelessWidget {
  final FeedPost post;
  final void Function(String emoji) onReact;
  final VoidCallback? onProfileTap;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final String heroTagPrefix;

  const PostCard({
    super.key,
    required this.post,
    required this.onReact,
    this.onProfileTap,
    this.onTap,
    this.onDelete,
    this.heroTagPrefix = '',
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
          _Photo(post: post, t: t, onTap: onTap, heroTagPrefix: heroTagPrefix),
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
  final String heroTagPrefix;
  const _Photo({
    required this.post,
    required this.t,
    this.onTap,
    this.heroTagPrefix = '',
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

class _PhotoState extends State<_Photo> {
  bool _swapped = false;

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
                    child: Hero(
                      tag: '${widget.heroTagPrefix}post_image_${post.id}',
                      child: mainUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: mainUrl,
                              cacheKey: mainKey,
                              cacheManager: AppCacheManager.instance,
                              fit: BoxFit.cover,
                              fadeInDuration:
                                  _renderedImageKeys.contains(mainKey)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 200),
                              placeholder: _renderedImageKeys.contains(mainKey)
                                  ? null
                                  : (_, __) => const ShimmerBox(),
                              imageBuilder: (_, imageProvider) {
                                _renderedImageKeys.add(mainKey);
                                return Image(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                );
                              },
                              errorWidget: (_, __, ___) =>
                                  Container(color: t.surfaceWeak),
                            )
                          : Container(color: t.surfaceWeak),
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
                                      progressIndicatorBuilder: (_, __, ___) =>
                                          ShimmerBox(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
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
        _QuickReactions(post: post, onReact: onReact, t: t),
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

  @override
  Widget build(BuildContext context) {
    final counts = {for (final r in post.reactions) r.emoji: r.count};
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: kReactionEmojis.map((emoji) {
        final selected = post.myReaction == emoji;
        final count = counts[emoji] ?? 0;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onReact(emoji);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              constraints: const BoxConstraints(minWidth: 38, minHeight: 34),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? t.goldSoft : t.surfaceWeak,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? t.goldBorderStrong : t.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  if (count > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '$count',
                      style: TextStyle(
                        color: selected ? t.goldText : t.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
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
