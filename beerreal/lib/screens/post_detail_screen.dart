import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fullscreen_image_viewer/fullscreen_image_viewer.dart'
    show FullscreenImageViewer;
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';
import '../core/app_cache_manager.dart';
import '../core/geocoding_service.dart';
import '../theme.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/posts/models/comment.dart';
import '../features/posts/models/feed_post.dart';
import '../features/posts/models/post_reaction.dart';
import '../features/posts/models/selfie_reaction.dart';
import '../features/posts/providers/comment_provider.dart';
import '../features/posts/providers/feed_provider.dart';
import '../features/posts/providers/profile_posts_provider.dart';
import '../features/posts/services/comment_service.dart';
import '../features/posts/services/post_service.dart';
import '../widgets/avatar.dart';
import '../widgets/pint_dialogs.dart';
import '../widgets/post_card.dart'
    show BounceTap, CheersButton, SelfieReactButton, SelfieAvatarStack;
import '../widgets/report_post_sheet.dart';
import '../widgets/shimmer_box.dart';
import 'selfie_react_capture_screen.dart';

// ── Main screen ───────────────────────────────────────────────────────────────

class PostDetailScreen extends StatelessWidget {
  final FeedPost post;
  final String heroTagPrefix;

  const PostDetailScreen({
    super.key,
    required this.post,
    this.heroTagPrefix = '',
  });

  @override
  Widget build(BuildContext context) {
    final commentService = context.read<CommentService>();
    return ChangeNotifierProvider(
      create: (_) => CommentProvider(commentService, postId: post.id)..load(),
      child: _PostDetailBody(post: post, heroTagPrefix: heroTagPrefix),
    );
  }
}

class _PostDetailBody extends StatefulWidget {
  final FeedPost post;
  final String heroTagPrefix;
  const _PostDetailBody({required this.post, this.heroTagPrefix = ''});

  @override
  State<_PostDetailBody> createState() => _PostDetailBodyState();
}

class _PostDetailBodyState extends State<_PostDetailBody> {
  late FeedPost _post;
  final _commentController = TextEditingController();
  final _commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _recordView();
    _refreshReactions();
  }

  Future<void> _recordView() async {
    try {
      final postService = context.read<PostService>();
      final views = await postService.recordView(_post.id);
      if (mounted) setState(() => _post = _post.copyWith(views: views));
    } catch (_) {}
  }

  // Silently fetch fresh reaction data so stale cache never shows wrong state.
  Future<void> _refreshReactions() async {
    try {
      final postService = context.read<PostService>();
      final fresh = await postService.getPostById(_post.id);
      if (mounted) {
        setState(() => _post = _post.copyWith(
          myReaction: fresh.myReaction,
          clearMyReaction: fresh.myReaction == null,
          reactions: fresh.reactions,
          totalReactions: fresh.totalReactions,
          likes: fresh.likes,
          likedByMe: fresh.likedByMe,
        ));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _onReact(String emoji) async {
    final feedProvider = context.read<FeedProvider>();
    await feedProvider.toggleReaction(_post.id, emoji);
    final updated = feedProvider.posts.firstWhere(
      (p) => p.id == _post.id,
      orElse: () => _post,
    );
    if (mounted) setState(() => _post = updated);
  }

  Future<void> _onSelfieReact() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SelfieReactCaptureScreen(
          onSend: (bytes) async {
            final reaction = await context.read<FeedProvider>().sendSelfieReaction(
              _post.id,
              imageBytes: bytes,
              filename: 'selfie_reaction.jpg',
            );
            if (!mounted) return;
            final withoutMine = _post.selfieReactions
                .where((r) => r.userId != reaction.userId)
                .toList();
            setState(() {
              _post = _post.copyWith(
                selfieReactions: [...withoutMine, reaction],
              );
            });
          },
        ),
      ),
    );
  }

  Future<void> _onRemoveSelfieReaction(String reactionId) async {
    final original = _post.selfieReactions;
    setState(() {
      _post = _post.copyWith(
        selfieReactions: original.where((r) => r.id != reactionId).toList(),
      );
    });
    try {
      await context.read<FeedProvider>().removeSelfieReaction(
        _post.id,
        reactionId,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _post = _post.copyWith(selfieReactions: original));
      }
    }
  }

  void _focusComposer() {
    _commentFocusNode.requestFocus();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    _commentController.clear();

    final commentProvider = context.read<CommentProvider>();
    final feedProvider = context.read<FeedProvider>();

    try {
      final isReply = commentProvider.replyingToId != null;
      if (isReply) {
        await commentProvider.addReply(text);
      } else {
        await commentProvider.addComment(text);
      }
      feedProvider.updateCommentCount(_post.id, 1);
      setState(() => _post = _post.copyWith(comments: _post.comments + 1));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final currentUserId = context.read<AuthProvider>().user?.id;
    final isOwner = _post.userId == currentUserId;

    void onDelete() {
      context.read<FeedProvider>().deletePost(_post.id);
      context.read<ProfilePostsProvider>().deletePost(_post.id);
      Navigator.of(context).pop();
    }

    return Scaffold(
      backgroundColor: t.bg,
      resizeToAvoidBottomInset: true,
      appBar: _PostAppBar(
        post: _post,
        t: t,
        onDelete: isOwner ? onDelete : null,
        onReport: isOwner
            ? null
            : () => showReportPostReasonSheet(context, post: _post),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 460,
                    child: _ZoomablePhoto(
                      post: _post,
                      heroTagPrefix: widget.heroTagPrefix,
                      onDoubleTap: () => _onReact('🍺'),
                    ),
                  ),
                ),

                // Caption + meta
                SliverToBoxAdapter(
                  child: Container(
                    color: t.bg,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Consumer<CommentProvider>(
                      builder: (_, cp, __) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: t.goldSoft,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: t.goldBorder),
                                ),
                                child: Text(
                                  _post.drinkLabel.isNotEmpty
                                      ? _post.drinkLabel
                                      : _post.caption,
                                  style: TextStyle(
                                    color: t.goldText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (_post.lat != null && _post.lng != null) ...[
                                const SizedBox(width: 8),
                                FutureBuilder<String?>(
                                  future: GeocodingService.cityName(
                                    _post.lat!,
                                    _post.lng!,
                                  ),
                                  builder: (_, snap) {
                                    final city = snap.data;
                                    if (city == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.place_outlined,
                                          size: 12,
                                          color: t.textMuted,
                                        ),
                                        const SizedBox(width: 2),
                                        Flexible(
                                          child: Text(
                                            city,
                                            style: TextStyle(
                                              color: t.textMuted,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                              if (_post.rating != null) ...[
                                const SizedBox(width: 8),
                                _DetailRating(rating: _post.rating!, t: t),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '@${_post.username} ',
                                  style: TextStyle(
                                    color: t.text,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.14,
                                  ),
                                ),
                                TextSpan(
                                  text: _post.caption,
                                  style: TextStyle(
                                    color: t.text,
                                    fontSize: 14,
                                    height: 1.45,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.visibility_outlined,
                                size: 12,
                                color: t.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_post.views} Aufrufe',
                                style: TextStyle(
                                  color: t.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                '${_post.totalReactions} Reaktionen',
                                style: TextStyle(
                                  color: t.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                '${cp.totalCount} Kommentare',
                                style: TextStyle(
                                  color: t.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(child: Divider(height: 1, color: t.divider)),

                // Reactions bar
                SliverToBoxAdapter(
                  child: _ReactionBar(
                    postId: _post.id,
                    reactions: _post.reactions,
                    myReaction: _post.myReaction,
                    onReact: _onReact,
                  ),
                ),

                SliverToBoxAdapter(child: Divider(height: 1, color: t.divider)),

                // Comments
                MultiSliver(
                  children: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                        child: Text(
                          'KOMMENTARE',
                          style: TextStyle(
                            color: t.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.4,
                          ),
                        ),
                      ),
                    ),
                    Consumer<CommentProvider>(
                      builder: (_, cp, __) {
                        if (cp.loading) {
                          return SliverList.builder(
                            itemCount: 3,
                            itemBuilder: (_, __) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    width: 34,
                                    height: 34,
                                    child: ShimmerBox.circle(),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: 11,
                                          child: ShimmerBox(
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        SizedBox(
                                          height: 11,
                                          child: ShimmerBox(
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        FractionallySizedBox(
                                          widthFactor: 0.6,
                                          child: SizedBox(
                                            height: 11,
                                            child: ShimmerBox(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        if (cp.error != null) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                cp.error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: t.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }
                        if (cp.comments.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Noch keine Kommentare. Sei der Erste!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: t.textFaint,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }
                        return SliverList.builder(
                          itemCount: cp.comments.length,
                          itemBuilder: (_, i) {
                            final c = cp.comments[i];
                            return _CommentThread(
                              comment: c,
                              currentUserId: currentUserId,
                              t: t,
                              onReply: () => cp.startReply(c.id, c.username),
                              onReact: (emoji) =>
                                  cp.reactToComment(c.id, emoji),
                              onDelete: c.userId == currentUserId
                                  ? () => cp.deleteComment(c.id)
                                  : null,
                              onReactToReply: (replyId, emoji) =>
                                  cp.reactToComment(replyId, emoji),
                              onDeleteReply: (replyId, uid) =>
                                  uid == currentUserId
                                  ? () => cp.deleteComment(replyId)
                                  : null,
                            );
                          },
                        );
                      },
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Ende des Beitrags',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: t.textFaint, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Consumer<CommentProvider>(
            builder: (_, cp, __) => _Composer(
              controller: _commentController,
              replyingToUsername: cp.replyingToUsername,
              onCancelReply: cp.cancelReply,
              onSend: _sendComment,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRating extends StatelessWidget {
  final int rating;
  final PintTheme t;

  const _DetailRating({required this.rating, required this.t});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 13,
          color: filled ? const Color(0xFFF6B733) : t.textFaint,
        );
      }),
    );
  }
}

// ── AppBar ────────────────────────────────────────────────────────────────────

class _PostAppBar extends StatelessWidget implements PreferredSizeWidget {
  final FeedPost post;
  final PintTheme t;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;

  const _PostAppBar({
    required this.post,
    required this.t,
    this.onDelete,
    this.onReport,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: t.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: t.surfaceWeak,
            shape: BoxShape.circle,
            border: Border.all(color: t.border),
          ),
          child: Icon(Icons.close, color: t.text, size: 18),
        ),
      ),
      title: Row(
        children: [
          PintAvatar(
            size: 34,
            imageUrl: post.avatarUrl,
            avatarColor: post.avatarColor,
            initials: post.avatarInitial,
            ring: true,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.username,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.14,
                  ),
                ),
                Text(
                  post.formattedDateTime,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: () => _showOptionsSheet(context),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: t.surfaceWeak,
              shape: BoxShape.circle,
              border: Border.all(color: t.border),
            ),
            child: Icon(Icons.more_horiz, color: t.text, size: 20),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: t.divider),
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showPostOptionsSheet(
      context,
      post: post,
      onDelete: onDelete,
      onReport: onReport,
    );
  }
}

// ── Zoomable photo ────────────────────────────────────────────────────────────

class _ZoomablePhoto extends StatefulWidget {
  final FeedPost post;
  final String heroTagPrefix;
  final VoidCallback? onDoubleTap;
  const _ZoomablePhoto({
    required this.post,
    this.heroTagPrefix = '',
    this.onDoubleTap,
  });

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto>
    with SingleTickerProviderStateMixin {
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

  static const _overlayW = 88.0;
  static const _overlayH = 116.0;
  static const _pad = 14.0;

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

  void _openFullscreen(BuildContext context, String imageUrl, String cacheKey) {
    FullscreenImageViewer.open(
      context: context,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        cacheKey: cacheKey,
        cacheManager: AppCacheManager.instance,
        fit: BoxFit.contain,
        errorWidget: (_, __, ___) => Container(color: Colors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final hasSelfie = post.selfieUrl.isNotEmpty;
    final mainUrl = _swapped ? post.selfieUrl : post.imageUrl;
    final mainKey = _swapped
        ? (post.selfiePath ?? '${post.id}_selfie')
        : (post.imagePath ?? post.id);
    final overlayUrl = _swapped ? post.imageUrl : post.selfieUrl;
    final overlayKey = _swapped
        ? (post.imagePath ?? post.id)
        : (post.selfiePath ?? '${post.id}_selfie');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (mainUrl.isNotEmpty) _openFullscreen(context, mainUrl, mainKey);
      },
      onDoubleTap: widget.onDoubleTap != null ? _onDoubleTap : null,
      child: Container(
        color: Colors.black,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            _selfiePos ??= Offset(size.width - _overlayW - _pad, _pad);

            return Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: '${widget.heroTagPrefix}post_image_${post.id}',
                  child: mainUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: mainUrl,
                          cacheKey: mainKey,
                          cacheManager: AppCacheManager.instance,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Container(color: Colors.black),
                        )
                      : Container(color: const Color(0xFF1A1A1A)),
                ),

                Positioned(
                  bottom: 14,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        color: Colors.black.withValues(alpha: 0.55),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.open_in_full_rounded,
                              size: 12,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Tippen zum Vollbild',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
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
                                  return _DetailSelfieDrag(
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
                        child: Container(
                          width: _overlayW,
                          height: _overlayH,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.85),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: overlayUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: overlayUrl,
                                    cacheKey: overlayKey,
                                    cacheManager: AppCacheManager.instance,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      color: const Color(0xFF1E3A2F),
                                    ),
                                  )
                                : Container(color: const Color(0xFF1E3A2F)),
                          ),
                        ),
                      ),
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
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Reaction bar ──────────────────────────────────────────────────────────────

class _ReactionBar extends StatelessWidget {
  final String postId;
  final List<PostReaction> reactions;
  final String? myReaction;
  final void Function(String emoji) onReact;

  const _ReactionBar({
    required this.postId,
    required this.reactions,
    required this.myReaction,
    required this.onReact,
  });

  void _showReactors(BuildContext context) {
    final svc = context.read<PostService>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ReactorsSheet(
        postId: postId,
        reactions: reactions,
        postService: svc,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final totalReactions = reactions.fold(0, (sum, r) => sum + r.count);
    final cheersCount = reactions
        .firstWhere(
          (r) => r.emoji == '🍺',
          orElse: () => const PostReaction(emoji: '🍺', count: 0),
        )
        .count;

    final activePills = <Widget>[];
    for (final emoji in kReactionEmojis.skip(1)) {
      final r = reactions.firstWhere(
        (r) => r.emoji == emoji,
        orElse: () => PostReaction(emoji: emoji, count: 0),
      );
      if (r.count == 0) continue;
      final isMine = myReaction == emoji;
      activePills
        ..add(const SizedBox(width: 8))
        ..add(
          BounceTap(
            onTap: () {
              HapticFeedback.selectionClick();
              onReact(emoji);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
                  Text(emoji, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 5),
                  Text(
                    '${r.count}',
                    style: TextStyle(
                      color: isMine ? t.goldText : t.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CheersButton(
            count: cheersCount,
            isSelected: myReaction == '🍺',
            onTap: () {
              HapticFeedback.selectionClick();
              onReact('🍺');
            },
            t: t,
          ),
          ...activePills,
          if (myReaction == null) ...[
            const SizedBox(width: 8),
            ReactButton(
              emojis: kReactionEmojis.skip(1).toList(),
              myReaction: myReaction,
              onReact: onReact,
              t: t,
            ),
          ],
          if (totalReactions > 0) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showReactors(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: t.surfaceWeak,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: t.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline, size: 15, color: t.textMuted),
                    const SizedBox(width: 5),
                    Text(
                      '$totalReactions',
                      style: TextStyle(
                        color: t.textMuted,
                        fontSize: 13,
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

// ── Emoji picker sheet (shared) ───────────────────────────────────────────────

void showEmojiPickerSheet(
  BuildContext context, {
  required void Function(String) onSelect,
}) {
  final t = PintThemeProvider.of(context);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: t.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reagieren',
              style: TextStyle(
                color: t.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: kReactionEmojis.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(ctx).pop();
                    onSelect(emoji);
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: t.surfaceWeak,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.border),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Comment thread (comment + its replies) ────────────────────────────────────

class _CommentThread extends StatelessWidget {
  final Comment comment;
  final String? currentUserId;
  final PintTheme t;
  final VoidCallback onReply;
  final void Function(String emoji) onReact;
  final VoidCallback? onDelete;
  final void Function(String replyId, String emoji) onReactToReply;
  final VoidCallback? Function(String replyId, String uid) onDeleteReply;

  const _CommentThread({
    required this.comment,
    required this.currentUserId,
    required this.t,
    required this.onReply,
    required this.onReact,
    this.onDelete,
    required this.onReactToReply,
    required this.onDeleteReply,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CommentRow(
          comment: comment,
          t: t,
          isOwner: comment.userId == currentUserId,
          onReply: onReply,
          onReact: onReact,
          onDelete: onDelete,
          indentLevel: 0,
        ),
        ...comment.replies.map(
          (reply) => _CommentRow(
            comment: reply,
            t: t,
            isOwner: reply.userId == currentUserId,
            onReply: onReply,
            onReact: (emoji) => onReactToReply(reply.id, emoji),
            onDelete: onDeleteReply(reply.id, reply.userId),
            indentLevel: 1,
          ),
        ),
      ],
    );
  }
}

// ── Comment row ───────────────────────────────────────────────────────────────

class _CommentRow extends StatelessWidget {
  final Comment comment;
  final PintTheme t;
  final bool isOwner;
  final VoidCallback onReply;
  final void Function(String emoji) onReact;
  final VoidCallback? onDelete;
  final int indentLevel;

  const _CommentRow({
    required this.comment,
    required this.t,
    required this.isOwner,
    required this.onReply,
    required this.onReact,
    this.onDelete,
    this.indentLevel = 0,
  });

  @override
  Widget build(BuildContext context) {
    final leftPad = 16.0 + indentLevel * 40.0;
    return Container(
      padding: EdgeInsets.fromLTRB(leftPad, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (indentLevel > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 2),
              child: Icon(
                Icons.subdirectory_arrow_right,
                size: 14,
                color: t.textFaint,
              ),
            ),
          PintAvatar(
            size: 32,
            imageUrl: comment.avatarUrl,
            avatarColor: comment.avatarColor,
            initials: comment.avatarInitial,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      comment.username,
                      style: TextStyle(
                        color: t.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '· ${comment.timeAgo}',
                      style: TextStyle(color: t.textFaint, fontSize: 11),
                    ),
                    const Spacer(),
                    if (onDelete != null)
                      GestureDetector(
                        onTap: () async {
                          final confirmed = await showPintConfirmDialog(
                            context,
                            title: 'Kommentar löschen?',
                            message: 'Dieser Kommentar wird dauerhaft entfernt.',
                            confirmLabel: 'Löschen',
                            destructive: true,
                          );
                          if (!confirmed || !context.mounted) return;
                          onDelete!();
                          showPintSnackBar(context, 'Kommentar gelöscht.');
                        },
                        child: Icon(Icons.close, size: 14, color: t.textFaint),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  comment.text,
                  style: TextStyle(
                    color: t.text,
                    fontSize: 14,
                    height: 1.45,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 6),

                // Reaction summary + action row
                Row(
                  children: [
                    // Existing reaction pills (compact)
                    ...comment.reactions
                        .where((r) => r.count > 0)
                        .take(3)
                        .map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () => onReact(r.emoji),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: r.reactedByMe
                                      ? t.goldSoft
                                      : t.surfaceWeak,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: r.reactedByMe
                                        ? t.goldBorderStrong
                                        : t.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      r.emoji,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${r.count}',
                                      style: TextStyle(
                                        color: r.reactedByMe
                                            ? t.goldText
                                            : t.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    // React button
                    GestureDetector(
                      onTap: () =>
                          showEmojiPickerSheet(context, onSelect: onReact),
                      child: Icon(
                        Icons.add_reaction_outlined,
                        size: 14,
                        color: t.textMuted,
                      ),
                    ),
                    const SizedBox(width: 14),
                    if (indentLevel == 0)
                      GestureDetector(
                        onTap: onReply,
                        child: Text(
                          'Antworten',
                          style: TextStyle(
                            color: t.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Composer ──────────────────────────────────────────────────────────────────

class _Composer extends StatefulWidget {
  final TextEditingController controller;
  final String? replyingToUsername;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.replyingToUsername,
    required this.onCancelReply,
    required this.onSend,
  });

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final hasText = widget.controller.text.trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.replyingToUsername != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: t.surfaceWeak,
            child: Row(
              children: [
                Icon(Icons.reply, size: 14, color: t.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Antwort an @${widget.replyingToUsername}',
                  style: TextStyle(
                    color: t.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onCancelReply,
                  child: Icon(Icons.close, size: 16, color: t.textMuted),
                ),
              ],
            ),
          ),
        Container(
          padding: EdgeInsets.fromLTRB(
            14,
            10,
            14,
            MediaQuery.of(context).padding.bottom + 10,
          ),
          decoration: BoxDecoration(
            color: t.bg,
            border: Border(top: BorderSide(color: t.border)),
          ),
          child: Row(
            children: [
              PintAvatar(
                size: 32,
                imageUrl: context.read<AuthProvider>().user?.avatarUrl,
                avatarColor: context.read<AuthProvider>().user?.avatarColor,
                initials: context.read<AuthProvider>().user?.avatarInitial,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: t.surfaceWeak,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: t.border),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    onSubmitted: (_) => widget.onSend(),
                    style: TextStyle(
                      color: t.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.replyingToUsername != null
                          ? 'Antwort auf @${widget.replyingToUsername}…'
                          : 'Kommentar eingeben…',
                      hintStyle: TextStyle(color: t.textFaint, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: hasText ? widget.onSend : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: hasText ? t.gold : t.surfaceWeak,
                    shape: BoxShape.circle,
                    border: hasText ? null : Border.all(color: t.border),
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    size: 17,
                    color: hasText ? t.goldInk : t.textFaint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailSelfieDrag extends Drag {
  _DetailSelfieDrag({
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
