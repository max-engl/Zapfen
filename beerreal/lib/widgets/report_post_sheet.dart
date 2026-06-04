import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/posts/models/feed_post.dart';
import '../features/reports/services/report_service.dart';
import '../theme.dart';
import 'pint_dialogs.dart';

Future<void> showPostOptionsSheet(
  BuildContext context, {
  required FeedPost post,
  VoidCallback? onDelete,
  VoidCallback? onReport,
}) {
  final t = PintThemeProvider.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: t.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: t.isDark ? 0.45 : 0.12),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHandle(t: t),
              const SizedBox(height: 8),
              _PostOptionButton(
                t: t,
                icon: onDelete != null
                    ? Icons.delete_outline
                    : Icons.flag_outlined,
                title: onDelete != null ? 'Beitrag löschen' : 'Beitrag melden',
                subtitle: onDelete != null
                    ? 'Entfernt deinen Beitrag dauerhaft.'
                    : 'Schicke diesen Beitrag zur Admin-Prüfung.',
                destructive: true,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  if (onDelete != null) {
                    onDelete();
                  } else if (onReport != null) {
                    onReport();
                  } else {
                    showReportPostReasonSheet(context, post: post);
                  }
                },
              ),
              const SizedBox(height: 8),
              _PostOptionButton(
                t: t,
                icon: Icons.close,
                title: 'Schließen',
                subtitle: 'Zurück zum Beitrag.',
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showReportPostReasonSheet(
  BuildContext context, {
  required FeedPost post,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _ReportPostReasonSheet(post: post),
  );
}

class _ReportPostReasonSheet extends StatefulWidget {
  final FeedPost post;

  const _ReportPostReasonSheet({required this.post});

  @override
  State<_ReportPostReasonSheet> createState() => _ReportPostReasonSheetState();
}

class _ReportPostReasonSheetState extends State<_ReportPostReasonSheet> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _close() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    try {
      await context.read<ReportService>().reportPost(
        postId: widget.post.id,
        reason: _reasonController.text.trim(),
      );
      if (!mounted) return;
      _close();
      showPintSnackBar(context, 'Meldung abgeschickt');
    } catch (error) {
      final message = error is DioException
          ? (error.response?.data is Map
                ? error.response?.data['message']?.toString()
                : null)
          : null;
      if (!mounted) return;
      setState(() => _submitting = false);
      showPintSnackBar(
        context,
        message ?? 'Meldung konnte nicht gesendet werden',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: t.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: t.isDark ? 0.5 : 0.14),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _SheetHandle(t: t)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Beitrag melden',
                        style: TextStyle(
                          color: t.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _submitting ? null : _close,
                      icon: Icon(Icons.close, color: t.textMuted),
                      style: IconButton.styleFrom(
                        backgroundColor: t.surfaceWeak,
                        side: BorderSide(color: t.border),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Warum meldest du den Beitrag von @${widget.post.username}?',
                  style: TextStyle(color: t.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _reasonController,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 500,
                  autofocus: true,
                  style: TextStyle(color: t.text),
                  cursorColor: t.gold,
                  decoration: InputDecoration(
                    hintText: 'Grund eingeben...',
                    hintStyle: TextStyle(color: t.textFaint),
                    counterStyle: TextStyle(color: t.textFaint),
                    errorStyle: const TextStyle(
                      color: Color(0xFFE05454),
                      fontWeight: FontWeight.w600,
                    ),
                    filled: true,
                    fillColor: t.surfaceWeak,
                    contentPadding: const EdgeInsets.all(14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: t.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: t.goldBorder),
                    ),
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'Bitte gib einen Grund an.';
                    }
                    if (trimmed.length < 5) {
                      return 'Bitte etwas genauer beschreiben.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting ? null : _close,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: t.text,
                          side: BorderSide(color: t.border),
                          backgroundColor: t.surfaceWeak,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Abbrechen'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: t.gold,
                          foregroundColor: t.goldInk,
                          disabledBackgroundColor: t.goldSoft,
                          disabledForegroundColor: t.textMuted,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(_submitting ? 'Sendet...' : 'Senden'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  final PintTheme t;

  const _SheetHandle({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: t.textFaint,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _PostOptionButton extends StatelessWidget {
  final PintTheme t;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool destructive;
  final VoidCallback onTap;

  const _PostOptionButton({
    required this.t,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFE05454) : t.text;
    final bg = destructive
        ? const Color(0xFFE05454).withValues(alpha: 0.12)
        : t.surfaceWeak;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: destructive ? color.withValues(alpha: 0.25) : t.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: destructive ? color.withValues(alpha: 0.12) : t.goldSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: destructive ? color : t.goldText,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: t.textMuted, fontSize: 12),
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
