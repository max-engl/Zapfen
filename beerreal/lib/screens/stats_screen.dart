import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../widgets/shimmer_box.dart';
import '../features/stats/models/stats_data.dart';
import '../features/stats/providers/stats_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmt(num n) {
  if (n >= 1000) {
    final k = n / 1000;
    return '${k == k.truncate() ? k.toInt() : k.toStringAsFixed(1)}k';
  }
  if (n is double && n != n.truncateToDouble()) return n.toStringAsFixed(1);
  return n.toInt().toString();
}

// ── Screen ────────────────────────────────────────────────────────────────────

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _scope = 'friends';
  String _range = 'week';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsProvider>().load(_scope, _range);
    });
  }

  void _setScope(String s) {
    setState(() => _scope = s);
    context.read<StatsProvider>().load(s, _range);
  }

  void _setRange(String r) {
    setState(() => _range = r);
    context.read<StatsProvider>().load(_scope, r);
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final provider = context.watch<StatsProvider>();
    final data = provider.dataFor(_scope, _range);
    final loading = provider.loading && data == null;
    final hasError = provider.error != null && data == null;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _StHeader(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: loading
                  ? _StatsShimmer(t: t)
                  : hasError
                      ? _StatsError(
                          t: t,
                          message: provider.error!,
                          onRetry: () => provider.refresh(_scope, _range),
                        )
                      : RefreshIndicator(
                          color: t.gold,
                          onRefresh: () => provider.refresh(_scope, _range),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 48),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ScopeToggle(scope: _scope, onChanged: _setScope),
                                _RangeChips(range: _range, onChanged: _setRange),
                                if (data != null) ...[
                                  _HeroKPI(data: data, range: _range),
                                  _StatCard(
                                    title: 'Getränke über die Zeit',
                                    hint: _range == 'week'
                                        ? 'nach Tag'
                                        : _range == 'month'
                                            ? 'nach Woche'
                                            : 'nach Monat',
                                    child: _TimelineChart(data: data, t: t),
                                  ),
                                  _StatTiles(data: data, scope: _scope),
                                  _StatCard(
                                    title: 'Wann wird gezapft',
                                    hint: 'nach Wochentag',
                                    child: _DowChart(dow: data.dow, t: t),
                                  ),
                                  _StatCard(
                                    title: 'Top Sorten',
                                    hint: _scope == 'friends' ? 'dein Kreis' : 'weltweit',
                                    child: _StylesChart(styles: data.styles, t: t),
                                  ),
                                  _Footer(data: data, scope: _scope),
                                ],
                              ],
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

// ── Header ────────────────────────────────────────────────────────────────────

class _StHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _StHeader({required this.onBack});

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
                Icon(Icons.bar_chart_rounded, size: 17, color: t.goldText),
                const SizedBox(width: 6),
                Text(
                  'Zapfstats',
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

// ── Scope toggle ──────────────────────────────────────────────────────────────

class _ScopeToggle extends StatelessWidget {
  final String scope;
  final ValueChanged<String> onChanged;
  const _ScopeToggle({required this.scope, required this.onChanged});

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
              active: scope == 'friends',
              onTap: () => onChanged('friends'),
            ),
            _ToggleBtn(
              label: 'Global',
              icon: Icons.language_rounded,
              active: scope == 'global',
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

// ── Range chips ───────────────────────────────────────────────────────────────

class _RangeChips extends StatelessWidget {
  final String range;
  final ValueChanged<String> onChanged;
  const _RangeChips({required this.range, required this.onChanged});

  static const _chips = [
    ('week', 'Woche'),
    ('month', 'Monat'),
    ('year', 'Jahr'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          for (int i = 0; i < _chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(_chips[i].$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: range == _chips[i].$1 ? t.goldSoft : t.surfaceWeak,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: range == _chips[i].$1 ? t.goldBorder : t.border,
                    ),
                  ),
                  child: Text(
                    _chips[i].$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: range == _chips[i].$1 ? t.goldText : t.textMuted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Hero KPI ──────────────────────────────────────────────────────────────────

class _HeroKPI extends StatelessWidget {
  final StatsData data;
  final String range;
  const _HeroKPI({required this.data, required this.range});

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final up = data.deltaPct >= 0;
    final deltaColor = up ? const Color(0xFF22c55e) : const Color(0xFFc2511e);
    final periodWord = range == 'week'
        ? 'diese Woche'
        : range == 'month'
            ? 'diesen Monat'
            : 'dieses Jahr';
    final prevWord = range == 'week'
        ? 'letzte Woche'
        : range == 'month'
            ? 'letzten Monat'
            : 'letztes Jahr';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gezapft · $periodWord',
            style: TextStyle(
              color: t.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.02,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(Icons.sports_bar_rounded, size: 22, color: t.goldText),
              const SizedBox(width: 6),
              Text(
                _fmt(data.total),
                style: TextStyle(
                  color: t.text,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                  height: 1,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Icon(
                      up ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                      size: 18,
                      color: deltaColor,
                    ),
                    Text(
                      '${data.deltaPct.abs()}%',
                      style: TextStyle(
                        color: deltaColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'vs. $prevWord',
            style: TextStyle(
              color: t.textFaint,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card shell ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String? hint;
  final Widget child;
  const _StatCard({required this.title, this.hint, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 13),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: t.text,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
              if (hint != null)
                Text(
                  hint!,
                  style: TextStyle(
                    color: t.textFaint,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Timeline chart ────────────────────────────────────────────────────────────

class _TimelineChart extends StatelessWidget {
  final StatsData data;
  final PintTheme t;
  const _TimelineChart({required this.data, required this.t});

  @override
  Widget build(BuildContext context) {
    final values = data.timeline.map((p) => p.count).toList();
    final labels = data.timeline.map((p) => p.label).toList();
    return SizedBox(
      height: 150,
      child: CustomPaint(
        painter: _TimelinePainter(
          values: values,
          labels: labels,
          gold: t.gold,
          goldText: t.goldText,
          bgColor: t.surface,
          borderColor: t.border,
          textFaintColor: t.textFaint,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final List<int> values;
  final List<String> labels;
  final Color gold;
  final Color goldText;
  final Color bgColor;
  final Color borderColor;
  final Color textFaintColor;

  _TimelinePainter({
    required this.values,
    required this.labels,
    required this.gold,
    required this.goldText,
    required this.bgColor,
    required this.borderColor,
    required this.textFaintColor,
  });

  static String _fmtVal(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return '${k == k.truncateToDouble() ? k.toInt() : k.toStringAsFixed(1)}k';
    }
    return '$n';
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const padB = 24.0, padT = 14.0, padX = 4.0;

    final maxVal = values.reduce(math.max);
    final n = values.length;
    final innerW = size.width - padX * 2;

    double px(int i) =>
        padX + (n == 1 ? innerW / 2 : (i / (n - 1)) * innerW);
    double py(int v) =>
        padT + (maxVal > 0 ? (1 - v / maxVal) : 1) * (size.height - padT - padB);

    final pts = List.generate(n, (i) => Offset(px(i), py(values[i])));

    // Baseline
    canvas.drawLine(
      Offset(padX, size.height - padB),
      Offset(size.width - padX, size.height - padB),
      Paint()
        ..color = borderColor
        ..strokeWidth = 1,
    );

    // Smooth line path
    final linePath = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      final cx = (pts[i - 1].dx + pts[i].dx) / 2;
      linePath.cubicTo(
          cx, pts[i - 1].dy, cx, pts[i].dy, pts[i].dx, pts[i].dy);
    }

    // Area fill
    final areaPath = Path.from(linePath)
      ..lineTo(pts.last.dx, size.height - padB)
      ..lineTo(pts.first.dx, size.height - padB)
      ..close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            gold.withValues(alpha: 0.32),
            gold.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromLTWH(0, padT, size.width, size.height - padT),
        ),
    );

    // Line
    canvas.drawPath(
      linePath,
      Paint()
        ..color = gold
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots
    final maxI = maxVal > 0 ? values.indexOf(maxVal) : 0;
    for (int i = 0; i < pts.length; i++) {
      final isMax = i == maxI && maxVal > 0;
      final r = isMax ? 4.0 : 2.5;
      canvas.drawCircle(pts[i], r, Paint()..color = isMax ? gold : bgColor);
      canvas.drawCircle(
        pts[i],
        r,
        Paint()
          ..color = gold
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    // Peak label
    if (maxVal > 0) {
      final tp = TextPainter(
        text: TextSpan(
          text: _fmtVal(maxVal),
          style: TextStyle(
            color: goldText,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(pts[maxI].dx - tp.width / 2, pts[maxI].dy - 18),
      );
    }

    // Axis labels
    for (int i = 0; i < labels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: textFaintColor,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(px(i) - tp.width / 2, size.height - padB + 6),
      );
    }
  }

  @override
  bool shouldRepaint(_TimelinePainter old) =>
      old.values != values || old.gold != gold || old.bgColor != bgColor;
}

// ── Stat tiles ────────────────────────────────────────────────────────────────

class _StatTiles extends StatelessWidget {
  final StatsData data;
  final String scope;
  const _StatTiles({required this.data, required this.scope});

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final tiles = [
      (Icons.schedule_rounded, 'Spitzenstunde', data.peakHour),
      (
        Icons.sports_bar_rounded,
        scope == 'friends' ? 'Ø pro Freund' : 'Ø pro Zapfer',
        _fmt(data.avgPerHead),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: t.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(tiles[i].$1, size: 16, color: t.goldText),
                    const SizedBox(height: 8),
                    Text(
                      tiles[i].$3,
                      style: TextStyle(
                        color: t.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tiles[i].$2,
                      style: TextStyle(
                        color: t.textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
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

// ── DoW bar chart ─────────────────────────────────────────────────────────────

class _DowChart extends StatelessWidget {
  final List<int> dow;
  final PintTheme t;
  const _DowChart({required this.dow, required this.t});

  static const _labels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  @override
  Widget build(BuildContext context) {
    final maxVal = dow.isEmpty ? 1 : dow.reduce(math.max);
    final maxI = maxVal > 0 ? dow.indexOf(maxVal) : -1;

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < dow.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _fmt(dow[i]),
                    style: TextStyle(
                      color: i == maxI ? t.goldText : t.textFaint,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    height: maxVal > 0
                        ? math.max(6.0, (dow[i] / maxVal) * 76)
                        : 6.0,
                    decoration: BoxDecoration(
                      color: i == maxI ? t.gold : t.surfaceWeak,
                      borderRadius: BorderRadius.circular(7),
                      border: i == maxI
                          ? null
                          : Border.all(color: t.border),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _labels[i],
                    style: TextStyle(
                      color: i == maxI ? t.text : t.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Styles breakdown ──────────────────────────────────────────────────────────

class _StylesChart extends StatelessWidget {
  final List<StatsStyleEntry> styles;
  final PintTheme t;
  const _StylesChart({required this.styles, required this.t});

  @override
  Widget build(BuildContext context) {
    final maxPct = styles.isEmpty ? 1 : styles.map((s) => s.pct).reduce(math.max);

    return Column(
      children: [
        for (int i = 0; i < styles.length; i++) ...[
          if (i > 0) const SizedBox(height: 11),
          Row(
            children: [
              SizedBox(
                width: 88,
                child: Text(
                  styles[i].name,
                  style: TextStyle(
                    color: t.text,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Stack(
                    children: [
                      Container(height: 10, color: t.surfaceWeak),
                      AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutCubic,
                        widthFactor: maxPct > 0 ? styles[i].pct / maxPct : 0,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: i == 0 ? t.gold : t.goldStrong,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 36,
                child: Text(
                  '${styles[i].pct}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: i == 0 ? t.goldText : t.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final StatsData data;
  final String scope;
  const _Footer({required this.data, required this.scope});

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final label = scope == 'friends'
        ? 'basiert auf ${data.userCount} Freunden'
        : 'basiert auf ${_fmt(data.userCount)} Zapfern';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Text(
        '$label 🍻',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: t.textFaint,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Loading shimmer ───────────────────────────────────────────────────────────

class _StatsShimmer extends StatelessWidget {
  final PintTheme t;
  const _StatsShimmer({required this.t});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 48),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: SizedBox(height: 52, child: ShimmerBox(borderRadius: BorderRadius.circular(14))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(children: [
              for (int i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: SizedBox(height: 36, child: ShimmerBox(borderRadius: BorderRadius.circular(999)))),
              ],
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 140, height: 13, child: ShimmerBox(borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 8),
              SizedBox(width: 100, height: 42, child: ShimmerBox(borderRadius: BorderRadius.circular(8))),
            ]),
          ),
          for (int c = 0; c < 3; c++)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: SizedBox(
                height: c == 1 ? 96 : 186,
                child: ShimmerBox(borderRadius: BorderRadius.circular(18)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _StatsError extends StatelessWidget {
  final PintTheme t;
  final String message;
  final VoidCallback onRetry;
  const _StatsError({required this.t, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded, size: 48, color: t.textMuted),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(color: t.textMuted, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: t.goldSoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: t.goldBorder),
                ),
                child: Text(
                  'Erneut versuchen',
                  style: TextStyle(color: t.goldText, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
