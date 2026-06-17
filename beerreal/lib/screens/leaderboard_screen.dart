import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../features/leaderboard/models/leaderboard_entry.dart';
import '../features/leaderboard/providers/leaderboard_provider.dart';
import '../widgets/avatar.dart';
import '../widgets/img_placeholder.dart';
import '../widgets/pint_refresh_logo.dart';
import '../widgets/shimmer_box.dart';
import '../widgets/stagger_item.dart';
import '../features/friends/models/api_friend.dart';
import 'friend_profile_screen.dart';
import 'stats_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _board = 'friends';
  String _metric = 'pints'; // 'pints' | 'drinksWk' | 'drinksMo'

  static String _fmtCount(int n) {
    if (n >= 1000000) {
      final m = n / 1000000;
      return '${m == m.truncateToDouble() ? m.toInt() : m.toStringAsFixed(1)}M';
    }
    if (n >= 1000) {
      final k = n / 1000;
      return '${k == k.truncateToDouble() ? k.toInt() : k.toStringAsFixed(1)}k';
    }
    return '$n';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaderboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final provider = context.watch<LeaderboardProvider>();

    final sorted = provider.sorted(_board, _metric);
    final top3 = sorted.take(3).toList();
    final rest = sorted.length > 3 ? sorted.sublist(3) : <LeaderboardEntry>[];
    final friendIds = provider.friendEntries
        .where((e) => !e.isYou)
        .map((e) => e.userId)
        .toSet();

    final youEntry = provider.friendEntries
        .cast<LeaderboardEntry?>()
        .firstWhere((e) => e!.isYou, orElse: () => null);
    final youIdxFriends = sorted.indexWhere((e) => e.isYou);
    final youRankFriends = youIdxFriends >= 0
        ? youIdxFriends + 1
        : sorted.length;
    final youRank = _board == 'friends'
        ? youRankFriends
        : provider.yourGlobalRank;

    final countLabel = _board == 'friends'
        ? '${provider.friendEntries.length} in deinem Kreis'
        : '${_fmtCount(provider.totalUsers)} Zapfer';
    final periodLabel = _metric == 'drinksWk'
        ? 'dieser Woche'
        : _metric == 'drinksMo'
        ? 'diesem Monat'
        : 'Gesamt';

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _LBHeader(
              onBack: () => Navigator.of(context).pop(),
              onStats: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const StatsScreen())),
            ),
            Expanded(
              child: Stack(
                children: [
                  provider.loading && sorted.isEmpty
                      ? _LeaderboardShimmer(t: t)
                      : provider.error != null && sorted.isEmpty
                      ? _ErrorState(
                          t: t,
                          message: provider.error!,
                          onRetry: () => provider.refresh(),
                        )
                      : CustomScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            CupertinoSliverRefreshControl(
                              onRefresh: () => provider.refresh(),
                              builder:
                                  (
                                    _,
                                    state,
                                    pulledExtent,
                                    triggerDistance,
                                    __,
                                  ) => PintRefreshLogo(
                                    state: state,
                                    pulledExtent: pulledExtent,
                                    triggerDistance: triggerDistance,
                                  ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.only(bottom: 130),
                              sliver: SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _BoardToggle(
                                      board: _board,
                                      onChanged: (b) =>
                                          setState(() => _board = b),
                                    ),
                                    _Subtitle(
                                      board: _board,
                                      countLabel: countLabel,
                                      periodLabel: periodLabel,
                                    ),
                                    _MetricChips(
                                      metric: _metric,
                                      onChanged: (m) =>
                                          setState(() => _metric = m),
                                    ),
                                    if (top3.isNotEmpty)
                                      _Podium(
                                        top3: top3,
                                        metric: _metric,
                                        friendIds: friendIds,
                                      ),
                                    _SectionLabel(t: t),
                                    ...rest.asMap().entries.map(
                                      (e) => StaggerItem(
                                        index: e.key,
                                        child: _RankRow(
                                          entry: e.value,
                                          rank: e.key + 4,
                                          metric: _metric,
                                          canOpenProfile:
                                              friendIds.contains(
                                                e.value.userId,
                                              ) &&
                                              !e.value.isYou,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                  if (youEntry != null)
                    _YouBar(
                      board: _board,
                      rank: youRank,
                      youEntry: youEntry,
                      metric: _metric,
                      yourPercentile: provider.yourPercentile,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _LBHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onStats;
  const _LBHeader({required this.onBack, this.onStats});

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.surfaceWeak,
                border: Border.all(color: t.border),
              ),
              child: Icon(Icons.chevron_left, size: 22, color: t.text),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_rounded, size: 17, color: t.goldText),
                const SizedBox(width: 6),
                Text(
                  'Bestenliste',
                  style: TextStyle(
                    color: t.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

void _openLeaderboardProfile(BuildContext context, LeaderboardEntry entry) {
  final friend = ApiFriend(
    id: entry.userId,
    username: entry.username,
    avatarUrl: entry.avatarUrl,
    avatarColor: entry.avatarColor,
    avatarInitial: entry.avatarInitial,
  );
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => FriendProfileScreen(friend: friend)),
  );
}

// ── Board toggle ──────────────────────────────────────────────────────────────

class _BoardToggle extends StatelessWidget {
  final String board;
  final ValueChanged<String> onChanged;
  const _BoardToggle({required this.board, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: t.surfaceWeaker,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.borderWeak),
        ),
        child: Row(
          children: [
            _ToggleBtn(
              label: 'Dein Kreis',
              icon: Icons.people_rounded,
              active: board == 'friends',
              onTap: () => onChanged('friends'),
            ),
            _ToggleBtn(
              label: 'Global',
              icon: Icons.language_rounded,
              active: board == 'global',
              onTap: () => onChanged('global'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ToggleBtn({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? t.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: active ? t.goldInk : t.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? t.goldInk : t.textMuted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Subtitle line ─────────────────────────────────────────────────────────────

class _Subtitle extends StatelessWidget {
  final String board;
  final String countLabel;
  final String periodLabel;
  const _Subtitle({
    required this.board,
    required this.countLabel,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Row(
        children: [
          Icon(
            board == 'friends' ? Icons.people_rounded : Icons.language_rounded,
            size: 14,
            color: t.goldText,
          ),
          const SizedBox(width: 6),
          Text(
            '$countLabel · sortiert nach $periodLabel',
            style: TextStyle(
              color: t.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Metric chips ──────────────────────────────────────────────────────────────

class _MetricChips extends StatelessWidget {
  final String metric;
  final ValueChanged<String> onChanged;
  const _MetricChips({required this.metric, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _Chip(
            label: 'Gesamt',
            id: 'pints',
            metric: metric,
            onChanged: onChanged,
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Diese Woche',
            id: 'drinksWk',
            metric: metric,
            onChanged: onChanged,
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Dieser Monat',
            id: 'drinksMo',
            metric: metric,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String id;
  final String metric;
  final ValueChanged<String> onChanged;
  const _Chip({
    required this.label,
    required this.id,
    required this.metric,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final active = metric == id;
    return GestureDetector(
      onTap: () => onChanged(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? t.goldSoft : t.surfaceWeak,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? t.goldBorder : t.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? t.goldText : t.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}

// ── Podium ────────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> top3;
  final String metric;
  final Set<String> friendIds;
  const _Podium({
    required this.top3,
    required this.metric,
    required this.friendIds,
  });

  @override
  Widget build(BuildContext context) {
    // Visual order: 2nd (left), 1st (center), 3rd (right)
    final slots = [
      if (top3.length > 1)
        _PodiumSlot(
          entry: top3[1],
          rank: 2,
          avatarSize: 60,
          pedestalH: 64,
          canOpenProfile: friendIds.contains(top3[1].userId) && !top3[1].isYou,
        ),
      if (top3.isNotEmpty)
        _PodiumSlot(
          entry: top3[0],
          rank: 1,
          avatarSize: 78,
          pedestalH: 92,
          canOpenProfile: friendIds.contains(top3[0].userId) && !top3[0].isYou,
        ),
      if (top3.length > 2)
        _PodiumSlot(
          entry: top3[2],
          rank: 3,
          avatarSize: 60,
          pedestalH: 50,
          canOpenProfile: friendIds.contains(top3[2].userId) && !top3[2].isYou,
        ),
    ];
    if (slots.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < slots.length; i++) ...[
            Expanded(
              child: _PodiumColumn(slot: slots[i], metric: metric),
            ),
            if (i < slots.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _PodiumSlot {
  final LeaderboardEntry entry;
  final int rank;
  final double avatarSize;
  final double pedestalH;
  final bool canOpenProfile;
  const _PodiumSlot({
    required this.entry,
    required this.rank,
    required this.avatarSize,
    required this.pedestalH,
    required this.canOpenProfile,
  });
}

class _PodiumColumn extends StatelessWidget {
  final _PodiumSlot slot;
  final String metric;
  const _PodiumColumn({required this.slot, required this.metric});

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final isFirst = slot.rank == 1;
    final ringColor = isFirst ? t.gold : t.selfieOutline;
    // Visual order left→right: rank2=0, rank1=1, rank3=2
    final staggerIndex = slot.rank == 2
        ? 0
        : slot.rank == 1
        ? 1
        : 2;
    const animMs = 420;
    const staggerMs = 90;
    const totalMs = animMs + staggerMs * 2;
    final start = (staggerMs * staggerIndex) / totalMs;
    final end = (staggerMs * staggerIndex + animMs) / totalMs;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: totalMs),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(-16 * (1 - value), -16 * (1 - value)),
          child: child,
        ),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: slot.canOpenProfile
            ? () => _openLeaderboardProfile(context, slot.entry)
            : null,
        child: Column(
          children: [
            // Crown for 1st
            SizedBox(
              height: 28,
              child: isFirst
                  ? Icon(
                      Icons.workspace_premium_rounded,
                      size: 24,
                      color: t.gold,
                    )
                  : null,
            ),
            // Avatar + rank badge
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: slot.avatarSize,
                  height: slot.avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ringColor,
                      width: isFirst ? 3 : 2,
                    ),
                  ),
                  child: ClipOval(
                    child: PintAvatar(
                      size: slot.avatarSize,
                      imageUrl: slot.entry.avatarUrl,
                      avatarColor: slot.entry.avatarColor,
                      initials: slot.entry.avatarInitial,
                      tone: ImgTone.avatar,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFirst ? t.gold : t.surface,
                      border: Border.all(color: t.bg, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '${slot.rank}',
                        style: TextStyle(
                          color: isFirst ? t.goldInk : t.text,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Name
            Text(
              slot.entry.username.split(' ').first,
              style: TextStyle(
                color: t.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            _MetricVal(entry: slot.entry, metric: metric, big: isFirst),
            const SizedBox(height: 10),
            // Pedestal
            Container(
              height: slot.pedestalH,
              decoration: BoxDecoration(
                color: isFirst ? t.gold : t.surfaceWeak,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                border: isFirst ? null : Border.all(color: t.border),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${slot.rank}',
                    style: TextStyle(
                      color: isFirst ? t.goldInk : t.textFaint,
                      fontSize: isFirst ? 30 : 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
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

// ── Metric value display ──────────────────────────────────────────────────────

class _MetricVal extends StatelessWidget {
  final LeaderboardEntry entry;
  final String metric;
  final bool big;
  const _MetricVal({
    required this.entry,
    required this.metric,
    this.big = false,
  });

  String _fmt(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return '${k == k.truncateToDouble() ? k.toInt() : k.toStringAsFixed(1)}k';
    }
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final val = entry.valueFor(metric);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Icon(Icons.sports_bar_rounded, size: big ? 13 : 12, color: t.goldText),
        const SizedBox(width: 3),
        Text(
          _fmt(val),
          style: TextStyle(
            color: t.text,
            fontSize: big ? 17 : 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          'Drinks',
          style: TextStyle(
            color: t.textFaint,
            fontSize: big ? 11 : 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── "The rest" divider ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final PintTheme t;
  const _SectionLabel({required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Row(
        children: [
          Text(
            'Die anderen',
            style: TextStyle(
              color: t.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: t.border)),
        ],
      ),
    );
  }
}

// ── Rank row ──────────────────────────────────────────────────────────────────

class _RankRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final String metric;
  final bool canOpenProfile;
  const _RankRow({
    required this.entry,
    required this.rank,
    required this.metric,
    required this.canOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canOpenProfile
          ? () => _openLeaderboardProfile(context, entry)
          : null,
      child: Container(
        margin: entry.isYou
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 2)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: entry.isYou ? t.goldFaint : Colors.transparent,
          borderRadius: entry.isYou ? BorderRadius.circular(14) : null,
          border: entry.isYou
              ? Border.all(color: t.goldBorder)
              : Border(bottom: BorderSide(color: t.divider)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: entry.isYou ? t.goldText : t.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: entry.isYou
                    ? Border.all(color: t.gold, width: 2)
                    : null,
              ),
              child: ClipOval(
                child: PintAvatar(
                  size: 42,
                  imageUrl: entry.avatarUrl,
                  avatarColor: entry.avatarColor,
                  initials: entry.avatarInitial,
                  tone: ImgTone.avatar,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.isYou ? '${entry.username} · Du' : entry.username,
                    style: TextStyle(
                      color: t.text,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@${entry.username}',
                    style: TextStyle(color: t.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            _MoveDelta(move: entry.moveFor(metric), isNew: entry.isNew),
            const SizedBox(width: 8),
            SizedBox(
              width: 64,
              child: Align(
                alignment: Alignment.centerRight,
                child: _MetricVal(entry: entry, metric: metric),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Move delta ────────────────────────────────────────────────────────────────

class _MoveDelta extends StatelessWidget {
  final int move;
  final bool isNew;
  const _MoveDelta({required this.move, required this.isNew});

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    if (isNew) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: t.goldFaint,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: t.goldBorder),
        ),
        child: Text(
          'NEU',
          style: TextStyle(
            color: t.goldText,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      );
    }
    if (move == 0) {
      return SizedBox(
        width: 22,
        child: Text(
          '–',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: t.textFaint,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    final up = move > 0;
    final col = up ? const Color(0xFF22c55e) : const Color(0xFFc2511e);
    return SizedBox(
      width: 34,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            up ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
            size: 14,
            color: col,
          ),
          Text(
            '${move.abs()}',
            style: TextStyle(
              color: col,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pinned "your rank" bar ────────────────────────────────────────────────────

class _YouBar extends StatelessWidget {
  final String board;
  final int rank;
  final LeaderboardEntry youEntry;
  final String metric;
  final String yourPercentile;

  const _YouBar({
    required this.board,
    required this.rank,
    required this.youEntry,
    required this.metric,
    required this.yourPercentile,
  });

  String _fmt(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return '${k == k.truncateToDouble() ? k.toInt() : k.toStringAsFixed(1)}k';
    }
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final rankLabel = board == 'global' ? '#${_fmt(rank)}' : '#$rank';
    final sub = board == 'global'
        ? (yourPercentile.isNotEmpty
              ? '$yourPercentile aller Zapfer weltweit'
              : 'Top Zapfer')
        : 'Mehr zapfen um aufzusteigen';

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.38],
            colors: [t.bg.withValues(alpha: 0.0), t.bg],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 26),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: t.gold,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                rankLabel,
                style: TextStyle(
                  color: t.goldInk,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 0,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: PintAvatar(
                    size: 38,
                    imageUrl: youEntry.avatarUrl,
                    avatarColor: youEntry.avatarColor,
                    initials: youEntry.avatarInitial,
                    tone: ImgTone.selfie,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Deine Position',
                      style: TextStyle(
                        color: t.goldInk,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                      ),
                    ),
                    Text(
                      sub,
                      style: const TextStyle(
                        color: Color(0xB23A1F02),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x243A1F02),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Icon(Icons.sports_bar_rounded, size: 13, color: t.goldInk),
                    const SizedBox(width: 3),
                    Text(
                      _fmt(youEntry.valueFor(metric)),
                      style: TextStyle(
                        color: t.goldInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Drinks',
                      style: const TextStyle(
                        color: Color(0x993A1F02),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Loading shimmer ───────────────────────────────────────────────────────────

class _LeaderboardShimmer extends StatelessWidget {
  final PintTheme t;
  const _LeaderboardShimmer({required this.t});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 130),
      child: Column(
        children: [
          // Segment shimmer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: SizedBox(
              height: 52,
              child: ShimmerBox(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          // Chips shimmer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                SizedBox(
                  height: 34,
                  width: 110,
                  child: ShimmerBox(borderRadius: BorderRadius.circular(999)),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 34,
                  width: 140,
                  child: ShimmerBox(borderRadius: BorderRadius.circular(999)),
                ),
              ],
            ),
          ),
          // Podium shimmer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 160,
                    child: ShimmerBox(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 200,
                    child: ShimmerBox(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 140,
                    child: ShimmerBox(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Row shimmers
          for (int i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 16,
                    child: ShimmerBox(borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 42,
                    height: 42,
                    child: ShimmerBox.circle(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 13,
                          width: 120,
                          child: ShimmerBox(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 11,
                          width: 80,
                          child: ShimmerBox(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
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

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final PintTheme t;
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({
    required this.t,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 48, color: t.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: t.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: t.goldSoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: t.goldBorder),
                ),
                child: Text(
                  'Erneut versuchen',
                  style: TextStyle(
                    color: t.goldText,
                    fontWeight: FontWeight.w700,
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
