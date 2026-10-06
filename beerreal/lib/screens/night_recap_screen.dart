import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/recap/services/recap_service.dart';
import '../widgets/pint_loading.dart';
import '../theme.dart';

/// Shows the recent activity summary as a modal bottom sheet.
/// Call [NightRecapScreen.show] to present it.
class NightRecapScreen extends StatefulWidget {
  const NightRecapScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Provider.value(
        value: context.read<RecapService>(),
        child: const NightRecapScreen(),
      ),
    );
  }

  @override
  State<NightRecapScreen> createState() => _NightRecapScreenState();
}

class _NightRecapScreenState extends State<NightRecapScreen>
    with SingleTickerProviderStateMixin {
  NightRecap? _recap;
  bool _loading = true;
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));

    _load();
  }

  Future<void> _load() async {
    final recap = await context.read<RecapService>().getNightRecap();
    if (!mounted) return;
    setState(() {
      _recap = recap;
      _loading = false;
    });
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: t.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 16, bottom: 0),
            decoration: BoxDecoration(
              color: t.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 64),
              child: SpinningAppLogo(size: 28),
            )
          else if (_recap == null)
            _EmptyState(t: t)
          else
            FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: _RecapBody(recap: _recap!, t: t),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final PintTheme t;
  const _EmptyState({required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: t.goldFaint,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('✨', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Noch keine Aktivität',
            style: TextStyle(
              color: t.text,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Noch keine Bewertungen in diesem Zeitraum.',
            textAlign: TextAlign.center,
            style: TextStyle(color: t.textMuted, fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 28),
          _CloseButton(t: t),
        ],
      ),
    );
  }
}

// ── Main recap body ───────────────────────────────────────────────────────────

String _recentLabel() {
  final now = DateTime.now();
  const months = [
    'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
    'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
  ];
  final mo = months[now.month - 1];
  return '${now.day}. $mo ${now.year}';
}

class _RecapBody extends StatelessWidget {
  final NightRecap recap;
  final PintTheme t;

  const _RecapBody({required this.recap, required this.t});

  @override
  Widget build(BuildContext context) {
    final maxCount = recap.drinks.isEmpty
        ? 1
        : recap.drinks.map((d) => d.count).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero header ──────────────────────────────────────────────────
          _HeroHeader(recap: recap, t: t),

          const SizedBox(height: 20),

          // ── Stat cards row ───────────────────────────────────────────────
          _StatsRow(recap: recap, t: t),

          const SizedBox(height: 24),

          // ── Drinks section ───────────────────────────────────────────────
          if (recap.drinks.isNotEmpty) ...[
            Text(
              'Getrunken',
              style: TextStyle(
                color: t.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            ...recap.drinks.map(
              (d) => _DrinkRow(drink: d, maxCount: maxCount, t: t),
            ),
            const SizedBox(height: 20),
          ],

          // ── Close button ─────────────────────────────────────────────────
          _CloseButton(t: t),
        ],
      ),
    );
  }
}

// ── Hero header ───────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final NightRecap recap;
  final PintTheme t;
  const _HeroHeader({required this.recap, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.goldFaint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.goldBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Moon icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: t.goldSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: t.goldBorder),
            ),
            child: const Center(
              child: Text('🌙', style: TextStyle(fontSize: 34)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Letzte Aktivität',
                  style: TextStyle(
                    color: t.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _recentLabel(),
                  style: TextStyle(
                    color: t.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.gold,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${recap.totalDrinks} Getränk${recap.totalDrinks != 1 ? 'e' : ''} bewertet',
                    style: TextStyle(
                      color: t.goldInk,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                    ),
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

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final NightRecap recap;
  final PintTheme t;
  const _StatsRow({required this.recap, required this.t});

  @override
  Widget build(BuildContext context) {
    final uniqueTypes = recap.drinks.length;
    return Row(
      children: [
        _StatCard(
          icon: '🥤',
          value: '${recap.totalDrinks}',
          label: 'Bewertungen',
          t: t,
        ),
        const SizedBox(width: 10),
        _StatCard(
          icon: '🎭',
          value: '$uniqueTypes',
          label: uniqueTypes == 1 ? 'Sorte' : 'Sorten',
          t: t,
        ),
        if (recap.uniqueLocations > 0) ...[
          const SizedBox(width: 10),
          _StatCard(
            icon: '📍',
            value: '${recap.uniqueLocations}',
            label: recap.uniqueLocations == 1 ? 'Ort' : 'Orte',
            t: t,
          ),
        ],
        if (recap.totalReactions > 0) ...[
          const SizedBox(width: 10),
          _StatCard(
            icon: '❤️',
            value: '${recap.totalReactions}',
            label: recap.totalReactions == 1 ? 'Reaktion' : 'Reaktionen',
            t: t,
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final PintTheme t;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: t.surfaceWeak,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: t.text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: t.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Drink row ─────────────────────────────────────────────────────────────────

class _DrinkRow extends StatelessWidget {
  final RecapDrink drink;
  final int maxCount;
  final PintTheme t;

  const _DrinkRow({
    required this.drink,
    required this.maxCount,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount > 0 ? drink.count / maxCount : 1.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.surfaceWeak,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Emoji badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: t.goldSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.goldBorder),
                  ),
                  child: Center(
                    child: Text(
                      drink.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drink.name,
                        style: TextStyle(
                          color: t.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${drink.count}× bewertet',
                        style: TextStyle(
                          color: t.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Count badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: t.gold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '×${drink.count}',
                      style: TextStyle(
                        color: t.goldInk,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Progress bar
            if (maxCount > 1) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 4,
                  backgroundColor: t.border,
                  valueColor: AlwaysStoppedAnimation<Color>(t.gold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Close button ──────────────────────────────────────────────────────────────

class _CloseButton extends StatelessWidget {
  final PintTheme t;
  const _CloseButton({required this.t});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: t.gold,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              'Super! ✨',
              style: TextStyle(
                color: t.goldInk,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
