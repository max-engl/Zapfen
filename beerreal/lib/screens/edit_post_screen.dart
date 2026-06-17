import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../features/drinks/models/drink_model.dart';
import '../features/drinks/providers/drink_provider.dart';
import '../features/posts/models/feed_post.dart';
import '../theme.dart';
import 'drink_picker_sheet.dart';

class EditPostScreen extends StatefulWidget {
  final FeedPost post;
  final Future<FeedPost> Function({
    required String caption,
    required String drinkName,
    required String drinkEmoji,
  }) onSave;

  const EditPostScreen({super.key, required this.post, required this.onSave});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late final TextEditingController _captionCtrl;
  DrinkModel? _selectedDrink;
  bool _saving = false;
  String? _error;

  static const _quickPicks = [
    DrinkModel(id: '__bier', name: 'Bier', emoji: '🍺', isDefault: true, isCustom: false),
    DrinkModel(id: '__weizen', name: 'Weizen', emoji: '🍺', isDefault: true, isCustom: false),
    DrinkModel(id: '__radler', name: 'Radler', emoji: '🍋', isDefault: true, isCustom: false),
    DrinkModel(id: '__cocktail', name: 'Cocktail', emoji: '🍸', isDefault: true, isCustom: false),
    DrinkModel(id: '__wein', name: 'Wein', emoji: '🍷', isDefault: true, isCustom: false),
    DrinkModel(id: '__shot', name: 'Shot', emoji: '🥃', isDefault: true, isCustom: false),
  ];

  @override
  void initState() {
    super.initState();
    _captionCtrl = TextEditingController(text: widget.post.caption);
    _selectedDrink = widget.post.drinkName.isNotEmpty
        ? DrinkModel(
            id: '__current',
            name: widget.post.drinkName,
            emoji: widget.post.drinkEmoji,
            isDefault: false,
            isCustom: false,
          )
        : null;
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  bool _isQuickPickMatch(DrinkModel pick) {
    if (_selectedDrink == null) return false;
    return _selectedDrink!.id == pick.id ||
        _selectedDrink!.name.toLowerCase() == pick.name.toLowerCase();
  }

  bool get _customSelected =>
      _selectedDrink != null && !_quickPicks.any(_isQuickPickMatch);

  void _openDrinkPicker() {
    final drinkProvider = context.read<DrinkProvider>();
    if (drinkProvider.defaults.isEmpty) drinkProvider.load();
    DrinkPickerSheet.show(
      context,
      provider: drinkProvider,
      current: _selectedDrink,
      onSelect: (drink) => setState(() => _selectedDrink = drink),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await widget.onSave(
        caption: _captionCtrl.text.trim(),
        drinkName: _selectedDrink?.name ?? '',
        drinkEmoji: _selectedDrink?.emoji ?? '',
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Speichern fehlgeschlagen. Bitte erneut versuchen.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar — matches capture screen _CamTopBar layout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _saving ? null : () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x1AFFFFFF),
                      ),
                      child: const Center(
                        child: Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, size: 10, color: t.gold),
                      const SizedBox(width: 6),
                      Text(
                        'BEITRAG BEARBEITEN',
                        style: TextStyle(
                          color: t.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(width: 38),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drink picker
                    _DrinkPickSection(
                      t: t,
                      selected: _selectedDrink,
                      quickPicks: _quickPicks,
                      isQuickPickMatch: _isQuickPickMatch,
                      customSelected: _customSelected,
                      onSelect: _saving ? null : (d) => setState(() => _selectedDrink = d),
                      onMore: _saving ? null : _openDrinkPicker,
                    ),
                    const SizedBox(height: 14),

                    // Caption field
                    _CaptionSection(t: t, ctrl: _captionCtrl, enabled: !_saving),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Save button pinned to bottom, slides with keyboard
            AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.fromLTRB(
                18, 0, 18,
                keyboardHeight > 0 ? keyboardHeight + 8 : 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFFF6B6B),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  _SaveButton(saving: _saving, onTap: _saving ? null : _save),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Drink pick section ────────────────────────────────────────────────────────

class _DrinkPickSection extends StatelessWidget {
  final PintTheme t;
  final DrinkModel? selected;
  final List<DrinkModel> quickPicks;
  final bool Function(DrinkModel) isQuickPickMatch;
  final bool customSelected;
  final ValueChanged<DrinkModel>? onSelect;
  final VoidCallback? onMore;

  const _DrinkPickSection({
    required this.t,
    required this.selected,
    required this.quickPicks,
    required this.isQuickPickMatch,
    required this.customSelected,
    this.onSelect,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x0FFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: t.goldFaint,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: t.goldBorder),
                  ),
                  child: Icon(Icons.local_bar_outlined, color: t.gold, size: 13),
                ),
                const SizedBox(width: 10),
                Text(
                  'GETRÄNK',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                if (customSelected) ...[
                  _DrinkChip(
                    t: t,
                    emoji: selected!.emoji.isNotEmpty ? selected!.emoji : '🍺',
                    name: selected!.name,
                    selected: true,
                    onTap: onMore,
                  ),
                  const SizedBox(width: 6),
                ],
                for (int i = 0; i < quickPicks.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  _DrinkChip(
                    t: t,
                    emoji: quickPicks[i].emoji,
                    name: quickPicks[i].name,
                    selected: isQuickPickMatch(quickPicks[i]),
                    onTap: onSelect != null ? () => onSelect!(quickPicks[i]) : null,
                  ),
                ],
                const SizedBox(width: 6),
                _DrinkChip(
                  t: t,
                  emoji: '',
                  name: 'Mehr',
                  selected: false,
                  onTap: onMore,
                  isMore: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _DrinkChip extends StatelessWidget {
  final PintTheme t;
  final String emoji;
  final String name;
  final bool selected;
  final VoidCallback? onTap;
  final bool isMore;

  const _DrinkChip({
    required this.t,
    required this.emoji,
    required this.name,
    required this.selected,
    this.onTap,
    this.isMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? t.gold : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? t.gold : const Color(0x14FFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMore) ...[
              Icon(Icons.add_rounded, color: Colors.white.withValues(alpha: 0.6), size: 13),
              const SizedBox(width: 4),
            ] else if (emoji.isNotEmpty) ...[
              Text(emoji, style: const TextStyle(fontSize: 15, height: 1)),
              const SizedBox(width: 6),
            ],
            Text(
              name,
              style: TextStyle(
                color: selected
                    ? t.goldInk
                    : isMore
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Caption section ───────────────────────────────────────────────────────────

class _CaptionSection extends StatelessWidget {
  final PintTheme t;
  final TextEditingController ctrl;
  final bool enabled;
  static const _max = 140;

  const _CaptionSection({required this.t, required this.ctrl, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        children: [
          TextField(
            controller: ctrl,
            readOnly: !enabled,
            maxLines: null,
            minLines: 3,
            maxLength: _max,
            autofocus: false,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.4,
              letterSpacing: -0.2,
            ),
            decoration: const InputDecoration(
              hintText: 'Sag etwas dazu…',
              hintStyle: TextStyle(color: Color(0x66FFFFFF)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              counterText: '',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '@erwähnen',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
              const SizedBox(width: 8),
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '#tag',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
              const Spacer(),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: ctrl,
                builder: (_, val, __) {
                  final len = val.text.length;
                  return Text(
                    '$len/$_max',
                    style: TextStyle(
                      color: len > _max - 20 ? t.gold : Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Save button — mirrors _PostBtn from capture_screen ────────────────────────

class _SaveButton extends StatefulWidget {
  final bool saving;
  final VoidCallback? onTap;

  const _SaveButton({required this.saving, this.onTap});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) {
    HapticFeedback.mediumImpact();
    setState(() => _pressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
    widget.onTap?.call();
  }

  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final disabled = widget.onTap == null;
    return GestureDetector(
      onTapDown: disabled ? null : _onTapDown,
      onTapUp: disabled ? null : _onTapUp,
      onTapCancel: disabled ? null : _onTapCancel,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: t.gold,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: widget.saving
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: t.goldInk,
                    ),
                  )
                : Text(
                    'Speichern',
                    style: TextStyle(
                      color: t.goldInk,
                      fontSize: 17,
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
