import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../features/posts/models/post_mention.dart';

/// Renders a caption string where `@username` tokens matching known [mentions]
/// are highlighted and optionally tappable via [onMentionTap].
///
/// An optional [prefix] span (e.g. a bold author name) is prepended inline.
class MentionText extends StatefulWidget {
  final String text;
  final List<PostMention> mentions;
  final TextStyle baseStyle;
  final TextStyle? mentionStyle;
  final InlineSpan? prefix;
  final void Function(String userId, String username)? onMentionTap;

  const MentionText({
    super.key,
    required this.text,
    required this.mentions,
    required this.baseStyle,
    this.mentionStyle,
    this.prefix,
    this.onMentionTap,
  });

  @override
  State<MentionText> createState() => _MentionTextState();
}

class _MentionTextState extends State<MentionText> {
  final _recognizers = <TapGestureRecognizer>[];
  late List<InlineSpan> _spans;

  @override
  void initState() {
    super.initState();
    _rebuild();
  }

  @override
  void didUpdateWidget(MentionText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text ||
        old.mentions != widget.mentions ||
        old.prefix != widget.prefix ||
        old.onMentionTap != widget.onMentionTap) {
      _disposeRecognizers();
      _rebuild();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  void _rebuild() {
    final mentionMap = {
      for (final m in widget.mentions) m.username.toLowerCase(): m
    };
    final spans = <InlineSpan>[];
    final regex = RegExp(r'@(\w+)');
    final text = widget.text;

    final effectiveMentionStyle = widget.mentionStyle ??
        widget.baseStyle.copyWith(
          color: const Color(0xFFD4A017),
          fontWeight: FontWeight.w700,
        );

    int lastEnd = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: widget.baseStyle,
        ));
      }
      final username = match.group(1)!;
      final mention = mentionMap[username.toLowerCase()];
      if (mention != null && widget.onMentionTap != null) {
        final uid = mention.userId;
        final uname = mention.username;
        final recognizer = TapGestureRecognizer()
          ..onTap = () => widget.onMentionTap!(uid, uname);
        _recognizers.add(recognizer);
        spans.add(TextSpan(
          text: '@$username',
          style: effectiveMentionStyle,
          recognizer: recognizer,
        ));
      } else {
        spans.add(TextSpan(
          text: '@$username',
          style: mention != null ? effectiveMentionStyle : widget.baseStyle,
        ));
      }
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: widget.baseStyle,
      ));
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: widget.baseStyle));
    }
    if (widget.prefix != null) spans.insert(0, widget.prefix!);

    _spans = spans;
  }

  @override
  Widget build(BuildContext context) {
    return RichText(text: TextSpan(children: _spans));
  }
}
