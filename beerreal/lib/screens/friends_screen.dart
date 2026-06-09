import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../features/blocks/providers/block_provider.dart';
import '../features/friends/models/api_friend.dart';
import '../features/friends/providers/friend_provider.dart';
import '../widgets/avatar.dart';
import '../widgets/pint_dialogs.dart';
import '../widgets/shimmer_box.dart';
import '../widgets/stagger_item.dart';
import 'add_friend_screen.dart';
import 'friend_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendProvider>().load();
    });
  }

  void _openAddFriend(BuildContext context) {
    final fp = context.read<FriendProvider>();
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 380),
            reverseTransitionDuration: const Duration(milliseconds: 280),
            pageBuilder: (_, __, ___) => ChangeNotifierProvider.value(
              value: fp,
              child: AddFriendScreen(
                onClose: () => Navigator.of(context).pop(),
              ),
            ),
            transitionsBuilder: (_, animation, __, child) {
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
              final fade = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              );
              return FadeTransition(
                opacity: fade,
                child: SlideTransition(position: slide, child: child),
              );
            },
          ),
        )
        .then((_) {
          if (mounted) fp.load();
        });
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final fp = context.watch<FriendProvider>();

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        if (fp.requests.isNotEmpty) ...[
          _SectionLabel(
            label: 'Anfragen für dich',
            right: '${fp.requests.length} ausstehend',
            t: t,
          ),
          ...fp.requests.asMap().entries.map(
            (e) => StaggerItem(
              key: ValueKey(e.value.id),
              index: e.key,
              child: _RequestRow(
                request: e.value,
                t: t,
                actionState: fp.actionFor(e.value.from.id),
                onAccept: () async {
                  final ok = await fp.acceptRequest(e.value.from.id);
                  if (ok && context.mounted) {
                    showPintSnackBar(
                      context,
                      '@${e.value.from.username} ist jetzt in deinem Kreis.',
                    );
                  }
                },
                onDecline: () => fp.declineRequest(e.value.from.id),
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],

        if (fp.sentRequests.isNotEmpty) ...[
          _SentRequestsSection(sentRequests: fp.sentRequests, t: t, fp: fp),
          const SizedBox(height: 18),
        ],

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: GestureDetector(
            onTap: () => _openAddFriend(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.goldBorderStrong, width: 1.5),
              ),
              child: Center(
                child: Text(
                  '+ Freund hinzufügen',
                  style: TextStyle(
                    color: t.goldText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),

        if (fp.loading && fp.friends.isEmpty && fp.requests.isEmpty)
          const _ShimmerFriendList()
        else if (fp.friends.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Noch keine Freunde. Füge welche hinzu!',
                style: TextStyle(color: t.textMuted, fontSize: 14),
              ),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: Text(
              'DEIN KREIS · ${fp.friends.length}',
              style: TextStyle(
                color: t.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
          ),
          ...fp.friends.asMap().entries.map(
            (e) => StaggerItem(
              key: ValueKey(e.value.id),
              index: e.key,
              child: _FriendRow(friend: e.value, t: t, fp: fp),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final String? right;
  final PintTheme t;

  const _SectionLabel({required this.label, this.right, required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: t.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: t.border)),
          if (right != null) ...[
            const SizedBox(width: 8),
            Text(right!, style: TextStyle(color: t.textMuted, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  final ApiFriendRequest request;
  final String? actionState;
  final PintTheme t;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RequestRow({
    required this.request,
    required this.actionState,
    required this.t,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final accepted = actionState == 'accepted';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surfaceWeaker,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          PintAvatar(
            size: 46,
            imageUrl: request.from.avatarUrl,
            avatarColor: request.from.avatarColor,
            initials: request.from.avatarInitial,
            ring: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${request.from.username}',
                  style: TextStyle(
                    color: t.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'möchte deinem Kreis beitreten',
                  style: TextStyle(color: t.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (accepted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: t.goldSoft,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: t.goldBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 13, color: t.goldText),
                  const SizedBox(width: 4),
                  Text(
                    'Im Kreis',
                    style: TextStyle(
                      color: t.goldText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                GestureDetector(
                  onTap: onDecline,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: t.surfaceWeak,
                      border: Border.all(color: t.border),
                    ),
                    child: Icon(Icons.close, size: 15, color: t.text),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onAccept,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: t.gold,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Annehmen',
                      style: TextStyle(
                        color: t.goldInk,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  final ApiFriend friend;
  final PintTheme t;
  final FriendProvider fp;

  const _FriendRow({required this.friend, required this.t, required this.fp});

  @override
  Widget build(BuildContext context) {
    final isBlocked = context.watch<BlockProvider>().isBlocked(friend.id);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => FriendProfileScreen(friend: friend)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.divider)),
        ),
        child: Row(
          children: [
            PintAvatar(
              size: 46,
              imageUrl: friend.avatarUrl,
              avatarColor: friend.avatarColor,
              initials: friend.avatarInitial,
              ring: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        friend.username,
                        style: TextStyle(
                          color: isBlocked ? t.textMuted : t.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.15,
                        ),
                      ),
                      if (isBlocked) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE05454).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFFE05454).withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            'Blockiert',
                            style: TextStyle(
                              color: Color(0xFFE05454),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${friend.username}',
                    style: TextStyle(color: t.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                final confirmed = await showPintConfirmDialog(
                  context,
                  title: 'Freund entfernen?',
                  message: '@${friend.username} aus deinem Kreis entfernen?',
                  confirmLabel: 'Entfernen',
                  destructive: true,
                );
                if (confirmed && context.mounted) {
                  fp.removeFriend(friend.id);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: t.surfaceWeak,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: t.border),
                ),
                child: Text(
                  'Entfernen',
                  style: TextStyle(
                    color: t.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class _ShimmerFriendList extends StatelessWidget {
  const _ShimmerFriendList();

  @override
  Widget build(BuildContext context) {
    return Column(children: List.generate(4, (_) => const _ShimmerFriendRow()));
  }
}

class _ShimmerFriendRow extends StatelessWidget {
  const _ShimmerFriendRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 46, height: 46, child: ShimmerBox.circle()),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 13,
                  child: ShimmerBox(borderRadius: BorderRadius.circular(6)),
                ),
                const SizedBox(height: 6),
                FractionallySizedBox(
                  widthFactor: 0.55,
                  child: SizedBox(
                    height: 11,
                    child: ShimmerBox(borderRadius: BorderRadius.circular(5)),
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

class _SentRequestsSection extends StatefulWidget {
  final List<ApiSentFriendRequest> sentRequests;
  final PintTheme t;
  final FriendProvider fp;

  const _SentRequestsSection({
    required this.sentRequests,
    required this.t,
    required this.fp,
  });

  @override
  State<_SentRequestsSection> createState() => _SentRequestsSectionState();
}

class _SentRequestsSectionState extends State<_SentRequestsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: Row(
              children: [
                Text(
                  'GESENDETE ANFRAGEN',
                  style: TextStyle(
                    color: widget.t.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Container(height: 1, color: widget.t.border)),
                const SizedBox(width: 8),
                Text(
                  '${widget.sentRequests.length} ausstehend',
                  style: TextStyle(color: widget.t.textMuted, fontSize: 12),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: widget.t.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: _expanded
              ? Column(
                  children: widget.sentRequests
                      .map(
                        (r) => _SentRequestRow(
                          request: r,
                          t: widget.t,
                          onCancel: () => widget.fp.cancelSentRequest(r.to.id),
                        ),
                      )
                      .toList(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _SentRequestRow extends StatelessWidget {
  final ApiSentFriendRequest request;
  final PintTheme t;
  final VoidCallback onCancel;

  const _SentRequestRow({
    required this.request,
    required this.t,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surfaceWeaker,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          PintAvatar(
            size: 46,
            imageUrl: request.to.avatarUrl,
            avatarColor: request.to.avatarColor,
            initials: request.to.avatarInitial,
            ring: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${request.to.username}',
                  style: TextStyle(
                    color: t.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Anfrage ausstehend',
                  style: TextStyle(color: t.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: t.surfaceWeak,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: t.border),
              ),
              child: Text(
                'Zurückziehen',
                style: TextStyle(
                  color: t.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
