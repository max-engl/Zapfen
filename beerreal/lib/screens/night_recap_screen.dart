import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/recap/services/recap_service.dart';
import '../theme.dart';

/// Shows last night's drinking summary as a modal bottom sheet.
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
      duration: const Duration(milliseconds: 480),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));

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
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: t.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 14, bottom: 4),
            decoration: BoxDecoration(
              color: t.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 56),
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2, color: t.gold),
              ),
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

// ── Empty state (no activity last night) ─────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final PintTheme t;
  const _EmptyState({required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🌙', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 14),
          Text(
            'Ruhige Nacht',
            style: TextStyle(
              color: t.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Gestern Abend gab\'s nichts zu loggen.',
            textAlign: TextAlign.center,
            style: TextStyle(color: t.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          _CloseButton(t: t),
        ],
      ),
    );
  }
}

// ── Main recap body ───────────────────────────────────────────────────────────

class _RecapBody extends StatelessWidget {
  final NightRecap recap;
  final PintTheme t;

  const _RecapBody({required this.recap, required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text('🌙', style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Letzte Nacht',
                    style: TextStyle(
                      color: t.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '${recap.totalDrinks} Drink${recap.totalDrinks != 1 ? 's' : ''} geloggt',
                    style: TextStyle(color: t.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Drink list
          ...recap.drinks.map((d) => _DrinkRow(drink: d, t: t)),

          const SizedBox(height: 20),

          // Stats chips row
          Row(
            children: [
              if (recap.uniqueLocations > 0) ...[
                _StatChip(
                  icon: Icons.location_on_rounded,
                  label:
                      '${recap.uniqueLocations} ${recap.uniqueLocations == 1 ? 'Ort' : 'Orte'}',
                  t: t,
                ),
                const SizedBox(width: 8),
              ],
              if (recap.totalReactions > 0)
                _StatChip(
                  icon: Icons.sports_bar_outlined,
                  label: '${recap.totalReactions} Reaktion${recap.totalReactions != 1 ? 'en' : ''}',
                  t: t,
                ),
            ],
          ),

          const SizedBox(height: 24),

          _CloseButton(t: t),
        ],
      ),
    );
  }
}

// ── Drink row ─────────────────────────────────────────────────────────────────

class _DrinkRow extends StatelessWidget {
  final RecapDrink drink;
  final PintTheme t;

  const _DrinkRow({required this.drink, required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: t.goldSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.goldBorder),
            ),
            child: Center(
              child: Text(drink.emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              drink.name,
              style: TextStyle(
                color: t.text,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: t.surfaceWeak,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: t.border),
            ),
            child: Text(
              '×${drink.count}',
              style: TextStyle(
                color: t.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final PintTheme t;

  const _StatChip({required this.icon, required this.label, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: t.surfaceWeak,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: t.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: t.goldText),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: t.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: t.gold,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              'Prost! 🍺',
              style: TextStyle(
                color: t.goldInk,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
