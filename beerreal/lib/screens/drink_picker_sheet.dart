import 'package:flutter/material.dart';
import '../widgets/pint_loading.dart';
import '../features/drinks/models/drink_model.dart';
import '../features/drinks/providers/drink_provider.dart';
import '../theme.dart';

enum _PickerMode { list, create }

class DrinkPickerSheet extends StatefulWidget {
  final DrinkProvider provider;
  final DrinkModel? current;
  final ValueChanged<DrinkModel> onSelect;

  const DrinkPickerSheet({
    super.key,
    required this.provider,
    required this.current,
    required this.onSelect,
  });

  static Future<void> show(
    BuildContext context, {
    required DrinkProvider provider,
    required DrinkModel? current,
    required ValueChanged<DrinkModel> onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DrinkPickerSheet(
        provider: provider,
        current: current,
        onSelect: onSelect,
      ),
    );
  }

  @override
  State<DrinkPickerSheet> createState() => _DrinkPickerSheetState();
}

class _DrinkPickerSheetState extends State<DrinkPickerSheet> {
  _PickerMode _mode = _PickerMode.list;
  final _searchCtrl = TextEditingController();
  String _query = '';

  // create-form state
  final _nameCtrl = TextEditingController();
  final _emojiCtrl = TextEditingController();
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.trim().toLowerCase()));
    if (widget.provider.defaults.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.provider.load());
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _emojiCtrl.dispose();
    super.dispose();
  }

  void _goCreate() {
    if (_query.isNotEmpty) _nameCtrl.text = _searchCtrl.text.trim();
    setState(() => _mode = _PickerMode.create);
  }

  void _goList() => setState(() {
        _mode = _PickerMode.list;
        _saveError = null;
      });

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final emoji = _emojiCtrl.text.trim().isEmpty ? '🥤' : _emojiCtrl.text.trim();
    final drink = await widget.provider.createCustom(name: name, emoji: emoji);
    if (!mounted) return;
    if (drink != null) {
      widget.onSelect(drink);
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _saveError = 'Konnte nicht gespeichert werden. Bitte erneut versuchen.';
      });
    }
  }

  List<DrinkModel> get _filteredDefaults {
    if (_query.isEmpty) return widget.provider.defaults;
    return widget.provider.defaults
        .where((d) => d.name.toLowerCase().contains(_query))
        .toList();
  }

  List<DrinkModel> get _filteredCustom {
    if (_query.isEmpty) return widget.provider.custom;
    return widget.provider.custom
        .where((d) => d.name.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF101012),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0x14FFFFFF)),
          left: BorderSide(color: Color(0x14FFFFFF)),
          right: BorderSide(color: Color(0x14FFFFFF)),
        ),
      ),
      child: Column(children: [
        // Grabber
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(children: [
            if (_mode == _PickerMode.create)
              _SheetIconBtn(
                onTap: _goList,
                child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
              ),
            if (_mode == _PickerMode.create) const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  _mode == _PickerMode.create ? 'NEUES GETRÄNK' : 'WAS IST IN DEINEM GLAS',
                  style: TextStyle(
                    color: t.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _mode == _PickerMode.create ? 'Selbst definieren' : 'Getränk wählen',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ]),
            ),
            _SheetIconBtn(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ]),
        ),

        // Body
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _mode == _PickerMode.list
                ? _buildList(t)
                : _buildCreateForm(t),
          ),
        ),
      ]),
    );
  }

  // ── List mode ──────────────────────────────────────────────────────────────

  Widget _buildList(PintTheme t) {
    return Column(key: const ValueKey('list'), children: [
      // Search
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0x0FFFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: Row(children: [
            const Icon(Icons.search_rounded, color: Color(0x80FFFFFF), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Getränk suchen…',
                  hintStyle: TextStyle(color: Color(0x80FFFFFF), fontSize: 15),
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () => _searchCtrl.clear(),
                child: const Icon(Icons.close, color: Color(0x80FFFFFF), size: 16),
              ),
          ]),
        ),
      ),

      // "Define your own" CTA
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: GestureDetector(
          onTap: _goCreate,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: t.goldFaint,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: t.goldBorderStrong,
                style: BorderStyle.solid,
                width: 1.5,
              ),
            ),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: t.gold,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.add_rounded, color: t.goldInk, size: 20),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Eigenes Getränk definieren',
                    style: TextStyle(
                        color: t.gold,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2)),
                const SizedBox(height: 1),
                Text('Hausgemacht, Cocktail, alles nicht Gelistete',
                    style: TextStyle(
                        color: t.gold.withValues(alpha: 0.7), fontSize: 12)),
              ]),
            ]),
          ),
        ),
      ),

      // Drink list
      Expanded(
        child: ListenableBuilder(
          listenable: widget.provider,
          builder: (_, __) {
            if (widget.provider.loading) {
              return const Center(child: SpinningAppLogo());
            }

            final customs = _filteredCustom;
            final defs = _filteredDefaults;
            final hasResults = customs.isNotEmpty || defs.isNotEmpty;

            if (!hasResults) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                child: Center(
                  child: Text(
                    'Kein Treffer für "$_query".\nFüge es als eigenes Getränk oben hinzu.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 14, height: 1.5),
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              children: [
                if (customs.isNotEmpty) ...[
                  _SectionLabel('Deine Getränke'),
                  ...customs.map((d) => _DrinkRow(
                        t: t,
                        drink: d,
                        selected: widget.current?.id == d.id,
                        onTap: () {
                          widget.onSelect(d);
                          Navigator.of(context).pop();
                        },
                      )),
                ],
                if (defs.isNotEmpty) ...[
                  _SectionLabel(_query.isNotEmpty ? 'Ergebnisse' : 'Gerade beliebt'),
                  ...defs.map((d) => _DrinkRow(
                        t: t,
                        drink: d,
                        selected: widget.current?.id == d.id,
                        onTap: () {
                          widget.onSelect(d);
                          Navigator.of(context).pop();
                        },
                      )),
                ],
              ],
            );
          },
        ),
      ),
    ]);
  }

  // ── Create form mode ───────────────────────────────────────────────────────

  Widget _buildCreateForm(PintTheme t) {
    return SingleChildScrollView(
      key: const ValueKey('create'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Preview card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x0AFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x12FFFFFF)),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([_nameCtrl, _emojiCtrl]),
            builder: (_, __) {
              final name = _nameCtrl.text.trim();
              final emoji = _emojiCtrl.text.trim().isEmpty ? '🥤' : _emojiCtrl.text.trim();
              return Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: t.goldFaint,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: t.goldBorder),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    name.isEmpty ? 'Dein Getränkename' : name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: name.isEmpty ? const Color(0x66FFFFFF) : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ]);
            },
          ),
        ),

        const SizedBox(height: 16),
        _FieldLabel('Getränkename'),
        _FormInput(ctrl: _nameCtrl, placeholder: 'z.B. Garage Hazy IPA', autofocus: true),

        const SizedBox(height: 4),
        _FieldLabel('Emoji'),
        _FormInput(ctrl: _emojiCtrl, placeholder: '🥤  (optional)'),

        if (_saveError != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_saveError!,
                style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13)),
          ),

        const SizedBox(height: 22),
        ListenableBuilder(
          listenable: _nameCtrl,
          builder: (_, __) {
            final canSave = _nameCtrl.text.trim().isNotEmpty && !_saving;
            return GestureDetector(
              onTap: canSave ? _save : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: canSave ? PintTheme.dark.gold : const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (_saving)
                    SpinningAppLogo(size: 18)
                  else ...[
                    Icon(Icons.check_rounded,
                        size: 16,
                        color: canSave ? PintTheme.dark.goldInk : const Color(0x59FFFFFF)),
                    const SizedBox(width: 8),
                    Text('Speichern & verwenden',
                        style: TextStyle(
                          color: canSave ? PintTheme.dark.goldInk : const Color(0x59FFFFFF),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        )),
                  ],
                ]),
              ),
            );
          },
        ),
      ]),
    );
  }
}

// ── Small sub-widgets ─────────────────────────────────────────────────────────

class _SheetIconBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _SheetIconBtn({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0x14FFFFFF),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0x66FFFFFF),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

class _DrinkRow extends StatelessWidget {
  final PintTheme t;
  final DrinkModel drink;
  final bool selected;
  final VoidCallback onTap;
  const _DrinkRow({required this.t, required this.drink, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? t.goldFaint : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? t.goldBorder : Colors.transparent,
          ),
        ),
        child: Row(children: [
          // Emoji thumbnail
          Stack(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: t.goldFaint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.goldBorder),
              ),
              child: Center(
                child: Text(
                  drink.emoji.isNotEmpty ? drink.emoji : '🥤',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            if (drink.isCustom)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: t.gold,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Text('DEINS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: t.goldInk,
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8)),
                ),
              ),
          ]),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              drink.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Radio circle
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? t.gold : Colors.transparent,
              border: Border.all(
                color: selected ? t.gold : const Color(0x33FFFFFF),
                width: 2,
              ),
            ),
            child: selected
                ? Icon(Icons.check_rounded, size: 13, color: t.goldInk)
                : null,
          ),
        ]),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0x80FFFFFF),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _FormInput extends StatelessWidget {
  final TextEditingController ctrl;
  final String placeholder;
  final bool autofocus;

  const _FormInput({
    required this.ctrl,
    required this.placeholder,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: TextField(
        controller: ctrl,
        autofocus: autofocus,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          hintText: placeholder,
          hintStyle: const TextStyle(color: Color(0x66FFFFFF), fontSize: 16),
        ),
      ),
    );
  }
}
