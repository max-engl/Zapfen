import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../widgets/pint_loading.dart';
import 'package:provider/provider.dart';

import '../core/app_cache_manager.dart';
import '../features/friends/models/api_friend.dart';
import '../features/friends/providers/friend_provider.dart';
import '../features/notifications/models/app_notification.dart';
import '../features/notifications/providers/notification_provider.dart';
import '../features/posts/services/post_service.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import '../widgets/shimmer_box.dart';
import '../widgets/stagger_item.dart';
import 'friend_profile_screen.dart';
import 'post_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onGoToFriends;

  const NotificationsScreen({super.key, this.onGoToFriends});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<NotificationProvider>();
      await provider.load();
      if (mounted) provider.markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              unreadCount: provider.unreadCount,
              onClose: () => Navigator.of(context).pop(),
              onMarkAll: provider.unreadCount > 0
                  ? () => context.read<NotificationProvider>().markAllRead()
                  : null,
            ),
            Expanded(
              child: _Body(
                provider: provider,
                onGoToFriends: widget.onGoToFriends,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onClose;
  final VoidCallback? onMarkAll;

  const _Header({
    required this.unreadCount,
    required this.onClose,
    required this.onMarkAll,
  });

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.surfaceWeak,
                border: Border.all(color: t.border),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: t.text,
              ),
            ),
          ),
          const Spacer(),
          // Title + badge
          Row(
            children: [
              Text(
                'Benachrichtigungen',
                style: TextStyle(
                  color: t.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.02 * 16,
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: t.gold,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(
                    child: Text(
                      '$unreadCount',
                      style: TextStyle(
                        color: t.goldInk,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          // Mark all read
          GestureDetector(
            onTap: onMarkAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.done_all_rounded,
                    size: 14,
                    color: onMarkAll != null ? t.goldText : t.textFaint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Alle gelesen',
                    style: TextStyle(
                      color: onMarkAll != null ? t.goldText : t.textFaint,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final NotificationProvider provider;
  final VoidCallback? onGoToFriends;

  const _Body({required this.provider, this.onGoToFriends});

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);

    if (provider.loading && provider.notifications.isEmpty) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, __) => const _ShimmerRow(),
      );
    }

    if (provider.error != null && provider.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 40, color: t.textFaint),
              const SizedBox(height: 12),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: t.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.read<NotificationProvider>().load(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: t.surfaceWeak,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: t.border),
                  ),
                  child: Text(
                    'Erneut versuchen',
                    style: TextStyle(
                      color: t.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.notifications.isEmpty) {
      return Center(
        child: Text(
          'Noch keine Benachrichtigungen',
          style: TextStyle(color: t.textMuted, fontSize: 14),
        ),
      );
    }

    const groupOrder = ['Heute', 'Diese Woche', 'Früher'];
    final grouped = <String, List<AppNotification>>{};
    for (final n in provider.notifications) {
      grouped.putIfAbsent(n.group, () => []).add(n);
    }

    var notifIdx = 0;
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        for (final g in groupOrder)
          if (grouped.containsKey(g)) ...[
            _GroupHeader(label: g),
            for (final n in grouped[g]!)
              StaggerItem(
                key: ValueKey(n.id),
                index: notifIdx++,
                child: n.type == 'bingo_line'
                    ? _BingoLineNotifRow(notification: n)
                    : _NotifRow(notification: n, onGoToFriends: onGoToFriends),
              ),
          ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          child: Text(
            'Das war alles aus den letzten 30 Tagen 🍻',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: t.textFaint,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Group header ──────────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Container(
      color: t.bg,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: t.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.16 * 11,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: t.border)),
        ],
      ),
    );
  }
}

// ── Notification row ──────────────────────────────────────────────────────────

class _NotifRow extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback? onGoToFriends;

  const _NotifRow({required this.notification, this.onGoToFriends});

  @override
  State<_NotifRow> createState() => _NotifRowState();
}

class _NotifRowState extends State<_NotifRow> {
  bool _loading = false;

  Future<void> _handleTap() async {
    final n = widget.notification;

    // Always mark read
    if (!n.read) {
      context.read<NotificationProvider>().markRead(n.id);
    }

    switch (n.type) {
      case 'poured':
      case 'cheers':
      case 'selfie_reaction':
      case 'comment':
        if (n.postId == null) return;
        setState(() => _loading = true);
        try {
          final post = await context.read<PostService>().getPostById(n.postId!);
          if (!mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
          );
        } catch (_) {
          // Post may be deleted — silently ignore
        } finally {
          if (mounted) setState(() => _loading = false);
        }

      case 'accepted':
        if (n.actorId == null || n.actorUsername == null) return;
        final friend = ApiFriend(
          id: n.actorId!,
          username: n.actorUsername!,
          avatarUrl: n.actorAvatarUrl,
          avatarColor: n.actorAvatarColor,
          avatarInitial: n.actorAvatarInitial,
        );
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FriendProfileScreen(friend: friend),
          ),
        );

      case 'request':
        widget.onGoToFriends?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final n = widget.notification;
    final badgeData = _badge(n.type, t);

    return GestureDetector(
      onTap: _loading ? null : _handleTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 16, 13),
        decoration: BoxDecoration(
          color: n.read ? Colors.transparent : t.goldFaint,
          border: Border(bottom: BorderSide(color: t.divider)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread dot
            SizedBox(
              width: 8,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: n.read ? Colors.transparent : t.gold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Avatar or icon tile
            Stack(
              clipBehavior: Clip.none,
              children: [
                if (n.actorUsername != null)
                  PintAvatar(
                    size: 44,
                    imageUrl: n.actorAvatarUrl,
                    avatarColor: n.actorAvatarColor,
                    initials: n.actorAvatarInitial,
                  )
                else
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: badgeData.bg,
                    ),
                    child: Icon(badgeData.icon, size: 20, color: badgeData.fg),
                  ),
                if (n.actorUsername != null)
                  Positioned(
                    right: -3,
                    bottom: -3,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: badgeData.bg,
                        border: Border.all(color: t.bg, width: 2),
                      ),
                      child: Icon(
                        badgeData.icon,
                        size: 11,
                        color: badgeData.fg,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Text block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: t.text,
                      ),
                      children: [
                        if (n.actorUsername != null)
                          TextSpan(
                            text: '@${n.actorUsername}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.01 * 14,
                            ),
                          ),
                        if (n.mutualCount > 0)
                          TextSpan(
                            text: ' · ${n.mutualCount} gemeinsame',
                            style: TextStyle(
                              color: t.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        TextSpan(
                          text: ' ${_body(n.type)}',
                          style: TextStyle(
                            color: t.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${n.timeLabel} ago',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: t.textFaint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (n.type == 'request') _FriendActions(notification: n),
                ],
              ),
            ),
            // Post thumbnail or loading spinner
            if (_loading)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: SpinningAppLogo(size: 46),
              )
            else if (n.postThumbUrl != null) ...[
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: n.postThumbUrl!,
                  cacheManager: AppCacheManager.instance,
                  width: 46,
                  height: 46,
                  memCacheWidth: 138,
                  memCacheHeight: 138,
                  fadeInDuration: Duration.zero,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const ShimmerBox(),
                  errorWidget: (_, __, ___) =>
                      Container(width: 46, height: 46, color: t.surfaceWeak),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Bingo line notification row ───────────────────────────────────────────────

class _BingoLineNotifRow extends StatelessWidget {
  final AppNotification notification;
  const _BingoLineNotifRow({required this.notification});

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final n = notification;

    return GestureDetector(
      onTap: () {
        if (!n.read) context.read<NotificationProvider>().markRead(n.id);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 5, 10, 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [t.goldFaint, t.goldSoft.withValues(alpha: 0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.goldBorder, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Unread dot
              SizedBox(
                width: 8,
                child: n.read
                    ? const SizedBox.shrink()
                    : Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: t.gold,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              // Avatar with gold ring
              PintAvatar(
                size: 46,
                imageUrl: n.actorAvatarUrl,
                avatarColor: n.actorAvatarColor,
                initials: n.actorAvatarInitial,
                ring: true,
              ),
              const SizedBox(width: 12),
              // Text block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'BINGO!',
                          style: TextStyle(
                            color: t.goldText,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text('🎊', style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.3,
                          color: t.text,
                        ),
                        children: [
                          if (n.actorUsername != null)
                            TextSpan(
                              text: '@${n.actorUsername}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          TextSpan(
                            text: ' hat eine Zeile im Bingo-Feld komplett!',
                            style: TextStyle(
                              color: t.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${n.timeLabel} ago',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: t.goldText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Mini 5×5 bingo grid
              _MiniBingoGrid(t: t),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBingoGrid extends StatelessWidget {
  final PintTheme t;
  const _MiniBingoGrid({required this.t});

  static const _completedRow = 2; // highlight row index 2 (middle row)

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Column(
        children: List.generate(5, (row) {
          final isCompletedRow = row == _completedRow;
          return Expanded(
            child: Row(
              children: List.generate(5, (col) {
                final isCenter = row == 2 && col == 2;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(1.5),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCompletedRow
                            ? t.gold
                            : isCenter
                            ? t.goldSoft
                            : t.surfaceWeak.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: isCenter && !isCompletedRow
                          ? Center(
                              child: Text(
                                '★',
                                style: TextStyle(
                                  fontSize: 5,
                                  color: t.goldText,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

// ── Friend request inline actions ─────────────────────────────────────────────

class _FriendActions extends StatefulWidget {
  final AppNotification notification;
  const _FriendActions({required this.notification});

  @override
  State<_FriendActions> createState() => _FriendActionsState();
}

class _FriendActionsState extends State<_FriendActions> {
  String? _state; // 'accepted' | 'declined' | null

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);

    if (_state == 'accepted') {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: _PillChip(
          label: 'Befreundet',
          icon: Icons.check_rounded,
          color: t.textMuted,
          bg: t.surfaceWeak,
          border: t.border,
        ),
      );
    }
    if (_state == 'declined') {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: _PillChip(
          label: 'Abgelehnt',
          color: t.textFaint,
          bg: t.surfaceWeak,
          border: t.border,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final actorId = widget.notification.actorId;
              if (actorId == null) return;
              final friendProvider = context.read<FriendProvider>();
              final notifProvider = context.read<NotificationProvider>();
              final ok = await friendProvider.acceptRequest(actorId);
              if (ok && mounted) {
                setState(() => _state = 'accepted');
                notifProvider.markRead(widget.notification.id);
              }
            },
            child: _PillChip(
              label: 'Annehmen',
              bg: t.gold,
              color: t.goldInk,
              border: t.gold,
              bold: true,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final actorId = widget.notification.actorId;
              if (actorId == null) return;
              final ok = await context.read<FriendProvider>().declineRequest(
                actorId,
              );
              if (ok && mounted) {
                setState(() => _state = 'declined');
              }
            },
            child: _PillChip(
              label: 'Ablehnen',
              bg: t.surfaceWeak,
              color: t.text,
              border: t.border,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color bg;
  final Color border;
  final bool bold;

  const _PillChip({
    required this.label,
    this.icon,
    required this.color,
    required this.bg,
    required this.border,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer placeholder row ───────────────────────────────────────────────────

class _ShimmerRow extends StatelessWidget {
  const _ShimmerRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const SizedBox.square(dimension: 44, child: ShimmerBox.circle()),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 160,
                  height: 13,
                  child: ShimmerBox(borderRadius: BorderRadius.circular(6)),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 90,
                  height: 11,
                  child: ShimmerBox(borderRadius: BorderRadius.circular(6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge helpers ─────────────────────────────────────────────────────────────

class _BadgeData {
  final IconData icon;
  final Color bg;
  final Color fg;
  const _BadgeData({required this.icon, required this.bg, required this.fg});
}

_BadgeData _badge(String type, PintTheme t) {
  switch (type) {
    case 'cheers':
      return _BadgeData(
        icon: Icons.sports_bar_outlined,
        bg: t.goldSoft,
        fg: t.goldText,
      );
    case 'selfie_reaction':
      return _BadgeData(
        icon: Icons.face_retouching_natural_outlined,
        bg: t.goldSoft,
        fg: t.goldText,
      );
    case 'comment':
      return _BadgeData(
        icon: Icons.chat_bubble_outline_rounded,
        bg: t.surfaceWeak,
        fg: t.text,
      );
    case 'request':
      return _BadgeData(
        icon: Icons.person_add_outlined,
        bg: t.goldSoft,
        fg: t.goldText,
      );
    case 'accepted':
      return _BadgeData(
        icon: Icons.check_rounded,
        bg: t.goldSoft,
        fg: t.goldText,
      );
    case 'bingo_line':
      return _BadgeData(
        icon: Icons.grid_on_rounded,
        bg: t.goldSoft,
        fg: t.goldText,
      );
    case 'poured':
    default:
      return _BadgeData(
        icon: Icons.sports_bar_outlined,
        bg: t.surfaceWeak,
        fg: t.text,
      );
  }
}

String _body(String type) {
  switch (type) {
    case 'cheers':
      return 'hat auf deinen Beitrag reagiert';
    case 'selfie_reaction':
      return 'hat mit einem Selfie auf deinen Beitrag reagiert';
    case 'comment':
      return 'hat deinen Beitrag kommentiert';
    case 'request':
      return 'möchte mit dir befreundet sein.';
    case 'accepted':
      return 'hat deine Freundschaftsanfrage angenommen.';
    case 'poured':
      return 'hat gerade gezapft!';
    case 'bingo_line':
      return 'hat eine Bingo-Zeile komplett! 🎰';
    default:
      return '';
  }
}
