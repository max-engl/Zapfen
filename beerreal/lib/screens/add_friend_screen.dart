import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import '../features/friends/models/api_friend.dart';
import '../features/friends/providers/friend_provider.dart';
import '../widgets/avatar.dart';
import '../widgets/shimmer_box.dart';
import '../features/auth/providers/auth_provider.dart';

class AddFriendScreen extends StatefulWidget {
  final VoidCallback onClose;
  const AddFriendScreen({super.key, required this.onClose});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _copied = false;
  String _toast = '';
  List<UserSearchResult> _searchResults = [];
  bool _searching = false;
  String? _inviteLink;
  bool _inviteLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendProvider>().load();
      context.read<FriendProvider>().loadRecommendations();
      _loadInviteLink();
    });
  }

  Future<void> _loadInviteLink() async {
    final link = await context.read<FriendProvider>().getInviteLink();
    if (mounted) {
      setState(() {
        _inviteLink = link;
        _inviteLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showToast(String msg) {
    setState(() => _toast = msg);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _toast = '');
    });
  }

  void _copy() {
    if (_inviteLink == null) return;
    Clipboard.setData(ClipboardData(text: _inviteLink!));
    setState(() => _copied = true);
    _showToast('Link kopiert');
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _onQueryChanged(String v, FriendProvider fp) async {
    setState(() {
      _query = v;
      _searching = v.length >= 2;
    });
    if (v.length >= 2) {
      final results = await fp.search(v);
      if (mounted && _query == v) {
        setState(() {
          _searchResults = results;
          _searching = false;
        });
      }
    } else {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final fp = context.watch<FriendProvider>();
    final me = context.read<AuthProvider>().user;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _Header(t: t, onClose: widget.onClose),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 100),
                    children: [
                      // Your code card
                      if (me != null)
                        _YourCodeCard(
                          t: t,
                          username: me.username,
                          inviteLink: _inviteLink,
                          inviteLoading: _inviteLoading,
                          copied: _copied,
                          onCopy: _copy,
                        ),
                      // Search field
                      _SearchField(
                        controller: _searchCtrl,
                        onChanged: (v) => _onQueryChanged(v, fp),
                      ),

                      // Recommendations (shown when not searching)
                      if (_query.length < 2) ...[
                        if (fp.recommendationsLoading || fp.recommendations.isNotEmpty) ...[
                          _SectionLabel(
                            label: 'Vielleicht kennst du',
                            t: t,
                          ),
                          if (fp.recommendationsLoading)
                            Column(
                              children: List.generate(
                                3,
                                (_) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                        width: 44,
                                        height: 44,
                                        child: ShimmerBox.circle(),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              height: 12,
                                              child: ShimmerBox(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            FractionallySizedBox(
                                              widthFactor: 0.55,
                                              child: SizedBox(
                                                height: 10,
                                                child: ShimmerBox(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        width: 90,
                                        height: 32,
                                        child: ShimmerBox(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            ...fp.recommendations.map(
                              (rec) => _RecommendationRow(
                                rec: rec,
                                t: t,
                                actionState: fp.actionFor(rec.id),
                                isFriend: fp.friends.any((f) => f.id == rec.id),
                                onAdd: () async {
                                  await fp.sendRequest(rec.id);
                                  if (context.mounted) {
                                    _showToast(
                                      'Anfrage an @${rec.username} gesendet',
                                    );
                                  }
                                },
                              ),
                            ),
                        ],
                      ],

                      // Search results
                      if (_query.length >= 2) ...[
                        _SectionLabel(
                          label: 'Suchergebnisse',
                          right: _searching ? '…' : '${_searchResults.length}',
                          t: t,
                        ),
                        if (_searching)
                          Column(
                            children: List.generate(
                              3,
                              (_) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: ShimmerBox.circle(),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            height: 12,
                                            child: ShimmerBox(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          FractionallySizedBox(
                                            widthFactor: 0.5,
                                            child: SizedBox(
                                              height: 10,
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
                            ),
                          )
                        else if (_searchResults.isEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                            child: Text(
                              'Keine Nutzer für "$_query" gefunden.',
                              style: TextStyle(
                                color: t.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          )
                        else
                          ..._searchResults.map(
                            (u) => _SearchResultRow(
                              user: u,
                              t: t,
                              actionState: fp.actionFor(u.id),
                              isFriend: fp.friends.any((f) => f.id == u.id),
                              onAdd: () async {
                                await fp.sendRequest(u.id);
                                if (context.mounted) {
                                  _showToast(
                                    'Anfrage an @${u.username} gesendet',
                                  );
                                }
                              },
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (_toast.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 28,
                child: _Toast(msg: _toast, t: t),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final PintTheme t;
  final VoidCallback onClose;
  const _Header({required this.t, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      child: Row(
        children: [
          _IconBtn(
            t: t,
            onTap: onClose,
            child: Icon(Icons.chevron_left, size: 20, color: t.text),
          ),
          const Spacer(),
          Text(
            'Zum Kreis hinzufügen',
            style: TextStyle(
              color: t.text,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: -0.32,
            ),
          ),
          const Spacer(),
          SizedBox(width: 36, height: 36),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final Widget child;
  final PintTheme t;
  final VoidCallback onTap;
  const _IconBtn({required this.child, required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) {
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

// ─── Your code card ────────────────────────────────────────────────────────

class _YourCodeCard extends StatefulWidget {
  final PintTheme t;
  final String username;
  final String? inviteLink;
  final bool inviteLoading;
  final bool copied;
  final VoidCallback onCopy;

  const _YourCodeCard({
    required this.t,
    required this.username,
    required this.inviteLink,
    required this.inviteLoading,
    required this.copied,
    required this.onCopy,
  });

  @override
  State<_YourCodeCard> createState() => _YourCodeCardState();
}

class _YourCodeCardState extends State<_YourCodeCard> {
  final _shareKey = GlobalKey();

  Future<void> _share() async {
    if (widget.inviteLink == null) return;
    final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    await Share.share(
      widget.inviteLink!,
      subject: 'Zapfen Einladung',
      sharePositionOrigin: origin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.goldFaint,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: t.goldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, size: 10, color: t.goldText),
              const SizedBox(width: 6),
              Text(
                'dein Einladungslink',
                style: TextStyle(
                  color: t.goldText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '@${widget.username}',
            style: TextStyle(
              color: t.text,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          // Link preview pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: t.surfaceWeak,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.border),
            ),
            child: widget.inviteLoading || widget.inviteLink == null
                ? SizedBox(
                    height: 14,
                    child: ShimmerBox(borderRadius: BorderRadius.circular(6)),
                  )
                : Text(
                    widget.inviteLink!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.textMuted,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  key: _shareKey,
                  onTap: widget.inviteLink != null ? _share : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: widget.inviteLink != null ? t.gold : t.surfaceWeak,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.ios_share,
                          size: 15,
                          color: widget.inviteLink != null
                              ? t.goldInk
                              : t.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Link teilen',
                          style: TextStyle(
                            color: widget.inviteLink != null
                                ? t.goldInk
                                : t.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: widget.inviteLink != null ? widget.onCopy : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: widget.copied ? t.goldSoft : t.surfaceWeak,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: widget.copied ? t.goldBorder : t.border,
                    ),
                  ),
                  child: Icon(
                    widget.copied ? Icons.check : Icons.copy_outlined,
                    size: 16,
                    color: widget.copied ? t.goldText : t.textMuted,
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

// ─── Search field ──────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: t.surfaceWeak,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 18, color: t.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: TextStyle(color: t.text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '@Handle oder Name suchen',
                  hintStyle: TextStyle(color: t.textMuted),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                child: Icon(Icons.close, size: 16, color: t.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Section label ─────────────────────────────────────────────────────────

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

// ─── Search result row ─────────────────────────────────────────────────────

class _SearchResultRow extends StatelessWidget {
  final UserSearchResult user;
  final String? actionState;
  final bool isFriend;
  final PintTheme t;
  final VoidCallback onAdd;
  const _SearchResultRow({
    required this.user,
    required this.actionState,
    required this.isFriend,
    required this.t,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final requested = actionState == 'requested' || isFriend;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.divider)),
      ),
      child: Row(
        children: [
          PintAvatar(
            size: 44,
            imageUrl: user.avatarUrl,
            avatarColor: user.avatarColor,
            initials: user.avatarInitial,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '@${user.username}',
              style: TextStyle(
                color: t.text,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.15,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: requested ? null : onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: requested ? t.surfaceWeak : t.goldSoft,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: requested ? t.border : t.goldBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: requested
                    ? [
                        Icon(Icons.check, size: 13, color: t.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          isFriend ? 'Befreundet' : 'Angefragt',
                          style: TextStyle(
                            color: t.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ]
                    : [
                        Icon(Icons.add, size: 13, color: t.goldText),
                        const SizedBox(width: 4),
                        Text(
                          'Hinzufügen',
                          style: TextStyle(
                            color: t.goldText,
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

// ─── Recommendation row ────────────────────────────────────────────────────

class _RecommendationRow extends StatelessWidget {
  final FriendRecommendation rec;
  final String? actionState;
  final bool isFriend;
  final PintTheme t;
  final VoidCallback onAdd;
  const _RecommendationRow({
    required this.rec,
    required this.actionState,
    required this.isFriend,
    required this.t,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final requested = actionState == 'requested' || isFriend;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.divider)),
      ),
      child: Row(
        children: [
          PintAvatar(
            size: 44,
            imageUrl: rec.avatarUrl,
            avatarColor: rec.avatarColor,
            initials: rec.avatarInitial,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${rec.username}',
                  style: TextStyle(
                    color: t.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rec.mutualCount == 1
                      ? '1 gemeinsamer Freund'
                      : '${rec.mutualCount} gemeinsame Freunde',
                  style: TextStyle(
                    color: t.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: requested ? null : onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: requested ? t.surfaceWeak : t.goldSoft,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: requested ? t.border : t.goldBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: requested
                    ? [
                        Icon(Icons.check, size: 13, color: t.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          isFriend ? 'Befreundet' : 'Angefragt',
                          style: TextStyle(
                            color: t.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ]
                    : [
                        Icon(Icons.add, size: 13, color: t.goldText),
                        const SizedBox(width: 4),
                        Text(
                          'Hinzufügen',
                          style: TextStyle(
                            color: t.goldText,
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

// ─── Toast ─────────────────────────────────────────────────────────────────

class _Toast extends StatelessWidget {
  final String msg;
  final PintTheme t;
  const _Toast({required this.msg, required this.t});

  @override
  Widget build(BuildContext context) {
    return Center(
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
            Icon(Icons.check, size: 15, color: t.goldInk),
            const SizedBox(width: 6),
            Text(
              msg,
              style: TextStyle(
                color: t.goldInk,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
