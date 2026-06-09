import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/bingo/providers/bingo_provider.dart';
import '../widgets/pint_loading.dart';
import '../features/bingo/services/bingo_service.dart';
import '../theme.dart';

class BingoScreen extends StatefulWidget {
  final BingoCard? initialCard;
  final String? ownerName;

  const BingoScreen({super.key, this.initialCard, this.ownerName});

  static Future<void> show(
    BuildContext context, {
    BingoCard? card,
    String? ownerName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Provider.value(
        value: context.read<BingoService>(),
        child: ChangeNotifierProvider.value(
          value: context.read<BingoProvider>(),
          child: BingoScreen(initialCard: card, ownerName: ownerName),
        ),
      ),
    );
  }

  @override
  State<BingoScreen> createState() => _BingoScreenState();
}

class _BingoScreenState extends State<BingoScreen> {
  int? _selectedCellIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialCard == null) {
        context.read<BingoProvider>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final prov = context.watch<BingoProvider>();
    final card = widget.initialCard ?? prov.card;
    final loading = widget.initialCard == null && prov.loading;
    final ownerName = widget.ownerName;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: t.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 48,
              offset: const Offset(0, -16),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Grabber ───────────────────────────────────────────────────
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: t.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),

            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🍺', style: TextStyle(fontSize: 21)),
                          const SizedBox(width: 8),
                          Text(
                            'Bier-Bingo',
                            style: TextStyle(
                              color: t.text,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.66, // -0.03em
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        card != null
                            ? ownerName != null
                                  ? '${card.monthLabel} · @$ownerName'
                                  : '${card.monthLabel} · für alle gleich'
                            : 'Monatliche Challenge',
                        style: TextStyle(
                          color: t.goldText,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.125, // 0.01em
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: t.surfaceWeak,
                        shape: BoxShape.circle,
                        border: Border.all(color: t.border),
                      ),
                      child: Icon(Icons.close_rounded, size: 19, color: t.text),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ───────────────────────────────────────────
            Expanded(
              child: loading && card == null
                  ? Center(child: SpinningAppLogo(size: 26))
                  : card == null
                  ? Center(
                      child: Text(
                        'Konnte nicht geladen werden.',
                        style: TextStyle(color: t.textMuted),
                      ),
                    )
                  : ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      children: [
                        // Stat pills — gap: 10
                        Row(
                          children: [
                            Expanded(
                              child: _StatPill(
                                icon: Icons.check_rounded,
                                iconSize: 15,
                                value: '${card.totalDone}/25',
                                label: 'erledigt',
                                hot: true,
                                t: t,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatPill(
                                icon: Icons.horizontal_rule_rounded,
                                iconSize: 15,
                                value: '${card.completedLines}',
                                label: card.completedLines == 1
                                    ? 'Zeile'
                                    : 'Zeilen',
                                hot: false,
                                t: t,
                              ),
                            ),
                          ],
                        ),
                        // marginBottom: 8
                        const SizedBox(height: 8),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: (card.totalDone / 25).clamp(0.0, 1.0),
                            minHeight: 7,
                            backgroundColor: t.surfaceWeak,
                            valueColor: AlwaysStoppedAnimation<Color>(t.gold),
                          ),
                        ),
                        // marginBottom: 16
                        const SizedBox(height: 16),
                        // Banners (margin: "0 0 14px")
                        if (card.isBlackout) ...[
                          _BlackoutBanner(t: t),
                          const SizedBox(height: 14),
                        ] else if (card.completedLines > 0) ...[
                          _LineBanner(lines: card.completedLines, t: t),
                          const SizedBox(height: 14),
                        ],
                        // 5×5 grid
                        _BingoGrid(
                          card: card,
                          t: t,
                          selectedIndex: _selectedCellIndex,
                          onCellTap: (i) => setState(() {
                            _selectedCellIndex =
                                _selectedCellIndex == i ? null : i;
                          }),
                        ),
                        // Task detail panel
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, -0.25),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: anim,
                                curve: Curves.easeOut,
                              )),
                              child: child,
                            ),
                          ),
                          child: _selectedCellIndex == null
                              ? const SizedBox.shrink(key: ValueKey('none'))
                              : Padding(
                                  key: ValueKey(_selectedCellIndex),
                                  padding: const EdgeInsets.only(top: 10),
                                  child: _BingoCellDetail(
                                    cell: card.cells[_selectedCellIndex!],
                                    t: t,
                                  ),
                                ),
                        ),
                        // Footnote marginTop: 14
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: t.textFaint,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Felder werden automatisch markiert, sobald ein Post passt — kein Antippen nötig. Neue Karte am 1. des nächsten Monats.',
                                style: TextStyle(
                                  color: t.textMuted,
                                  fontSize: 11.5,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),

            // ── Close button (fixed outside scroll — padding: "12px 20px 26px") ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: t.gold,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      'Schließen',
                      style: TextStyle(
                        color: t.goldInk,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.155, // -0.01em
                      ),
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

// ── Stat pill ─────────────────────────────────────────────────────────────────
// padding: "11px 13px", borderRadius: 14, gap: 9
// icon box: 30×30, borderRadius: 9
// value: fontSize 17, w900, letterSpacing -0.03em
// label: fontSize 10.5, w600, marginTop: 2

class _StatPill extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final String value;
  final String label;
  final bool hot;
  final PintTheme t;

  const _StatPill({
    required this.icon,
    required this.iconSize,
    required this.value,
    required this.label,
    required this.hot,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: hot ? t.goldSoft : t.surfaceWeak,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hot ? t.goldBorder : t.border),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: hot ? t.gold : t.surfaceWeak,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: hot ? t.goldInk : t.goldText,
            ),
          ),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: t.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.51, // -0.03em
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: t.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Blackout banner ───────────────────────────────────────────────────────────
// padding: "13px 15px", borderRadius: 14, gap: 10
// 👑 fontSize: 22, title: 14.5 w900, subtitle: 12 w600 opacity 0.85

class _BlackoutBanner extends StatelessWidget {
  final PintTheme t;
  const _BlackoutBanner({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: t.gold,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text('👑', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'BLACKOUT!',
                  style: TextStyle(
                    color: t.goldInk,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Alle 25 Felder — legendäres Abzeichen verdient.',
                  style: TextStyle(
                    color: t.goldInk.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

// ── Line banner ───────────────────────────────────────────────────────────────
// padding: "11px 14px", borderRadius: 14, gap: 9
// icon: 16px goldText, text: 12.5 w600, bold part: w800 goldText

class _LineBanner extends StatelessWidget {
  final int lines;
  final PintTheme t;
  const _LineBanner({required this.lines, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: t.goldFaint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.goldBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.horizontal_rule_rounded, size: 16, color: t.goldText),
          const SizedBox(width: 9),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: t.text,
                ),
                children: [
                  TextSpan(
                    text: '$lines ${lines == 1 ? 'Zeile' : 'Zeilen'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: t.goldText,
                    ),
                  ),
                  const TextSpan(
                    text: ' komplett — die goldenen Felder zählen.',
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

// ── Bingo 5×5 grid ────────────────────────────────────────────────────────────
// gap: 6, childAspectRatio: 1.0 (square cells)

class _BingoGrid extends StatelessWidget {
  final BingoCard card;
  final PintTheme t;
  final int? selectedIndex;
  final ValueChanged<int>? onCellTap;

  const _BingoGrid({
    required this.card,
    required this.t,
    this.selectedIndex,
    this.onCellTap,
  });

  bool _isRowComplete(int row) =>
      [0, 1, 2, 3, 4].every((c) => card.cells[row * 5 + c].done);
  bool _isColComplete(int col) =>
      [0, 1, 2, 3, 4].every((r) => card.cells[r * 5 + col].done);
  bool get _isDiag1 => [0, 1, 2, 3, 4].every((i) => card.cells[i * 5 + i].done);
  bool get _isDiag2 =>
      [0, 1, 2, 3, 4].every((i) => card.cells[i * 5 + (4 - i)].done);

  bool _isInCompletedLine(int index) {
    final row = index ~/ 5;
    final col = index % 5;
    if (_isRowComplete(row)) return true;
    if (_isColComplete(col)) return true;
    if (row == col && _isDiag1) return true;
    if (row + col == 4 && _isDiag2) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.0,
      ),
      itemCount: 25,
      itemBuilder: (_, i) => _BingoCell(
        cell: card.cells[i],
        inLine: _isInCompletedLine(i),
        t: t,
        isSelected: selectedIndex == i,
        onTap: onCellTap == null ? null : () => onCellTap!(i),
      ),
    );
  }
}

// ── Single bingo cell ─────────────────────────────────────────────────────────
// Three states: done+inLine (gold fill) · done (gold tint + tick) · undone (faint)
// padding: "2px 3px", gap: 3, borderRadius: 12, overflow: hidden
// emoji: 21px · label: 8.2px w700 -0.01em uppercase lineHeight 1.12
// tick: 14×14 circle, top 4 right 4, check icon 9px
// free star: 9px w800 0.04em letterSpacing, top 4 right 4

class _BingoCell extends StatelessWidget {
  final BingoCell cell;
  final bool inLine;
  final PintTheme t;
  final bool isSelected;
  final VoidCallback? onTap;

  const _BingoCell({
    required this.cell,
    required this.inLine,
    required this.t,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = cell.done;
    final isFree = cell.isFree;

    final Color bgColor;
    final Color borderColor;
    final Color labelColor;

    if (done && inLine) {
      bgColor = t.gold;
      borderColor = Colors.transparent;
      labelColor = t.goldInk;
    } else if (done) {
      bgColor = t.goldSoft;
      borderColor = t.goldBorder;
      labelColor = t.text;
    } else {
      bgColor = t.surfaceWeaker;
      borderColor = t.border;
      labelColor = t.textFaint;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: t.gold, width: 2)
            : Border.all(color: borderColor),
        boxShadow: (done && inLine)
            ? [
                BoxShadow(
                  color: t.goldStrong,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Main content — padding "2px 3px", gap 3
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (done)
                  Text(
                    cell.emoji,
                    style: const TextStyle(fontSize: 21, height: 1),
                    textAlign: TextAlign.center,
                  )
                else
                  Opacity(
                    opacity: 0.32,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ]),
                      child: Text(
                        cell.emoji,
                        style: const TextStyle(fontSize: 21, height: 1),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                const SizedBox(height: 3),
                Text(
                  cell.label.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 8.2,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.082, // -0.01em
                    height: 1.12,
                  ),
                ),
              ],
            ),
          ),
          // Tick badge: done, not in completed line, not free
          if (done && !inLine && !isFree)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: t.gold,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, size: 9, color: t.goldInk),
              ),
            ),
          // Free space star
          if (isFree)
            Positioned(
              top: 4,
              right: 4,
              child: Text(
                '★',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.36, // 0.04em
                  color: (done && inLine) ? t.goldInk : t.goldText,
                  height: 1,
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }
}

// ── Bingo cell detail panel ───────────────────────────────────────────────────

class _BingoCellDetail extends StatelessWidget {
  final BingoCell cell;
  final PintTheme t;

  const _BingoCellDetail({required this.cell, required this.t});

  @override
  Widget build(BuildContext context) {
    final done = cell.done;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: done ? t.goldSoft : t.surfaceWeak,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: done ? t.goldBorder : t.border),
      ),
      child: Row(
        children: [
          Text(cell.emoji, style: const TextStyle(fontSize: 36, height: 1)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cell.label,
                  style: TextStyle(
                    color: t.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1.3,
                  ),
                ),
                if (done) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: t.goldText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Erledigt',
                        style: TextStyle(
                          color: t.goldText,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
