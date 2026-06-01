import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../features/friends/models/api_friend.dart';
import '../features/friends/providers/friend_provider.dart';
import '../widgets/avatar.dart';
import '../widgets/shimmer_box.dart';
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
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: fp,
              child: AddFriendScreen(
                onClose: () => Navigator.of(context).pop(),
              ),
            ),
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
        // Search + Add row
        if (fp.loading && fp.friends.isEmpty)
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
          ...fp.friends.map((f) => _FriendRow(friend: f, t: t, fp: fp)),
        ],

        Padding(
          padding: const EdgeInsets.all(18),
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
      ],
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
            PintAvatar(size: 46, imageUrl: friend.avatarUrl, avatarColor: friend.avatarColor, initials: friend.avatarInitial, ring: false),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.username,
                    style: TextStyle(
                      color: t.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.15,
                    ),
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
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: t.surface,
                    title: Text(
                      'Freund entfernen?',
                      style: TextStyle(color: t.text),
                    ),
                    content: Text(
                      '@${friend.username} aus deinem Kreis entfernen?',
                      style: TextStyle(color: t.textMuted),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          'Abbrechen',
                          style: TextStyle(color: t.textMuted),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          'Entfernen',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
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
