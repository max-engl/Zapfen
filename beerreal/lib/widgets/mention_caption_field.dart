import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/posts/models/post_mention.dart';
import '../features/posts/services/post_service.dart';
import '../theme.dart';
import 'avatar.dart';

/// Caption text field with live @mention autocomplete.
///
/// Detects when the user types `@word` (preceded by start-of-text or a space)
/// and fetches matching users via [PostService.searchUsers]. Selecting a
/// suggestion inserts the full `@username ` and calls [onMentionsChanged] with
/// the current list of tagged users.
class MentionCaptionField extends StatefulWidget {
  final PintTheme t;
  final TextEditingController ctrl;
  final bool enabled;
  final List<PostMention> initialMentions;
  final ValueChanged<List<PostMention>> onMentionsChanged;

  static const maxLength = 140;

  const MentionCaptionField({
    super.key,
    required this.t,
    required this.ctrl,
    required this.onMentionsChanged,
    this.enabled = true,
    this.initialMentions = const [],
  });

  @override
  State<MentionCaptionField> createState() => _MentionCaptionFieldState();
}

class _MentionCaptionFieldState extends State<MentionCaptionField> {
  // Maps lowercase username → PostMention for lookups during display
  final _known = <String, PostMention>{};

  List<PostMention> _suggestions = [];
  bool _loading = false;
  String? _activeQuery; // null = not in mention-typing mode
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    for (final m in widget.initialMentions) {
      _known[m.username.toLowerCase()] = m;
    }
    widget.ctrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_onTextChanged);
    _debounce?.cancel();
    super.dispose();
  }

  // ── Text change handler ───────────────────────────────────────────────────

  void _onTextChanged() {
    final query = _extractQuery(widget.ctrl);
    if (query == null) {
      if (_activeQuery != null) {
        setState(() {
          _activeQuery = null;
          _suggestions = [];
          _loading = false;
        });
      }
      _notifyMentions();
      return;
    }
    if (query == _activeQuery) return;

    setState(() {
      _activeQuery = query;
      if (query.length < 2) {
        _suggestions = [];
        _loading = false;
      } else {
        _loading = true;
      }
    });

    _debounce?.cancel();
    if (query.length >= 2) {
      _debounce = Timer(
        const Duration(milliseconds: 280),
        () => _fetchSuggestions(query),
      );
    }
    _notifyMentions();
  }

  /// Returns the partial username after the last `@` the cursor is inside,
  /// or null if the cursor is not inside a mention token.
  String? _extractQuery(TextEditingController ctrl) {
    final text = ctrl.text;
    final cursor =
        ctrl.selection.isValid ? ctrl.selection.baseOffset : text.length;
    if (cursor <= 0) return null;
    final before = text.substring(0, cursor);
    final lastAt = before.lastIndexOf('@');
    if (lastAt < 0) return null;
    // @ must be at start or preceded by whitespace
    if (lastAt > 0) {
      final prev = before[lastAt - 1];
      if (prev != ' ' && prev != '\n') return null;
    }
    final afterAt = before.substring(lastAt + 1);
    if (afterAt.contains(' ') || afterAt.contains('\n')) return null;
    return afterAt;
  }

  // ── Suggestion fetch ──────────────────────────────────────────────────────

  Future<void> _fetchSuggestions(String query) async {
    if (!mounted) return;
    try {
      final results =
          await context.read<PostService>().searchUsers(query);
      if (mounted && _activeQuery == query) {
        setState(() {
          _suggestions = results;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Selection ─────────────────────────────────────────────────────────────

  void _selectMention(PostMention mention) {
    final ctrl = widget.ctrl;
    final text = ctrl.text;
    final cursor =
        ctrl.selection.isValid ? ctrl.selection.baseOffset : text.length;
    final before = text.substring(0, cursor);
    final lastAt = before.lastIndexOf('@');
    if (lastAt < 0) return;

    final replacement = '@${mention.username} ';
    final newText =
        text.substring(0, lastAt) + replacement + text.substring(cursor);
    final newCursor = lastAt + replacement.length;

    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );

    _known[mention.username.toLowerCase()] = mention;
    setState(() {
      _activeQuery = null;
      _suggestions = [];
      _loading = false;
    });
    _notifyMentions();
  }

  // ── Mentions notification ─────────────────────────────────────────────────

  void _notifyMentions() {
    final text = widget.ctrl.text;
    final active = RegExp(r'@(\w+)')
        .allMatches(text)
        .map((m) => m.group(1)!.toLowerCase())
        .toSet();
    final result = _known.entries
        .where((e) => active.contains(e.key))
        .map((e) => e.value)
        .toList();
    widget.onMentionsChanged(result);
  }

  bool get _showSuggestions =>
      _activeQuery != null &&
      _activeQuery!.length >= 2 &&
      (_loading || _suggestions.isNotEmpty);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showSuggestions) ...[
          _SuggestionList(
            t: t,
            suggestions: _suggestions,
            loading: _loading,
            onSelect: _selectMention,
          ),
          const SizedBox(height: 6),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x0DFFFFFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: Column(
            children: [
              TextField(
                controller: widget.ctrl,
                readOnly: !widget.enabled,
                maxLines: null,
                minLines: 3,
                maxLength: MentionCaptionField.maxLength,
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
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
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
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: widget.ctrl,
                    builder: (_, val, __) {
                      final len = val.text.length;
                      return Text(
                        '$len/${MentionCaptionField.maxLength}',
                        style: TextStyle(
                          color: len > MentionCaptionField.maxLength - 20
                              ? t.gold
                              : Colors.white.withValues(alpha: 0.4),
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
        ),
      ],
    );
  }
}

// ── Suggestion list ───────────────────────────────────────────────────────────

class _SuggestionList extends StatelessWidget {
  final PintTheme t;
  final List<PostMention> suggestions;
  final bool loading;
  final ValueChanged<PostMention> onSelect;

  const _SuggestionList({
    required this.t,
    required this.suggestions,
    required this.loading,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x22FFFFFF)),
        boxShadow: const [
          BoxShadow(color: Color(0x44000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: loading && suggestions.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(18),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white38,
                  ),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.06),
              ),
              itemBuilder: (context, i) {
                final m = suggestions[i];
                return GestureDetector(
                  onTap: () => onSelect(m),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        PintAvatar(
                          size: 30,
                          imageUrl: m.avatarUrl,
                          initials: m.username.isNotEmpty
                              ? m.username[0].toUpperCase()
                              : '?',
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '@${m.username}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
