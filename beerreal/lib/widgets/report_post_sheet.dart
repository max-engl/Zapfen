import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/blocks/providers/block_provider.dart';
import '../features/posts/models/feed_post.dart';
import '../features/reports/services/report_service.dart';
import '../theme.dart';
import 'pint_dialogs.dart';

// ── Post options sheet (delete / report / block) ───────────────────────────

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
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  if (onDelete != null) {
                    if (!context.mounted) return;
                    final confirmed = await showPintConfirmDialog(
                      context,
                      title: 'Beitrag löschen?',
                      message: 'Dieser Beitrag wird dauerhaft entfernt.',
                      confirmLabel: 'Löschen',
                      destructive: true,
                    );
                    if (confirmed) onDelete();
                  } else if (onReport != null) {
                    onReport();
                  } else {
                    if (context.mounted) showReportPostReasonSheet(context, post: post);
                  }
                },
              ),
              // Only show block option for other users' posts
              if (onDelete == null) ...[
                const SizedBox(height: 8),
                _BlockUserButton(t: t, post: post, sheetContext: sheetContext),
              ],
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

// ── Block user button inside post options ──────────────────────────────────

class _BlockUserButton extends StatelessWidget {
  final PintTheme t;
  final FeedPost post;
  final BuildContext sheetContext;

  const _BlockUserButton({
    required this.t,
    required this.post,
    required this.sheetContext,
  });

  @override
  Widget build(BuildContext context) {
    final blockProvider = context.watch<BlockProvider>();
    final isBlocked = blockProvider.isBlocked(post.userId);
    return _PostOptionButton(
      t: t,
      icon: isBlocked ? Icons.person_add_outlined : Icons.block,
      title: isBlocked ? 'Blockierung aufheben' : 'Nutzer blockieren',
      subtitle: isBlocked
          ? '@${post.username} wird wieder sichtbar.'
          : 'Beiträge von @${post.username} ausblenden.',
      destructive: !isBlocked,
      onTap: () async {
        Navigator.of(sheetContext).pop();
        try {
          if (isBlocked) {
            await blockProvider.unblockUser(post.userId);
            if (context.mounted) {
              showPintSnackBar(context, '@${post.username} wurde entsperrt.');
            }
          } else {
            await blockProvider.blockUser(post.userId);
            if (context.mounted) {
              showPintSnackBar(context, '@${post.username} wurde blockiert.');
            }
          }
        } catch (_) {
          if (context.mounted) {
            showPintSnackBar(context, 'Aktion fehlgeschlagen.', isError: true);
          }
        }
      },
    );
  }
}

// ── Report reason sheet ────────────────────────────────────────────────────

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

const _kReportReasons = [
  (label: 'Spam', icon: Icons.campaign_outlined),
  (label: 'Beleidigung oder Hassrede', icon: Icons.sentiment_very_dissatisfied_outlined),
  (label: 'Unangemessenes Bild', icon: Icons.no_photography_outlined),
  (label: 'Gewalt oder Bedrohung', icon: Icons.warning_amber_outlined),
  (label: 'Anderes', icon: Icons.more_horiz),
];

class _ReportPostReasonSheet extends StatefulWidget {
  final FeedPost post;

  const _ReportPostReasonSheet({required this.post});

  @override
  State<_ReportPostReasonSheet> createState() => _ReportPostReasonSheetState();
}

class _ReportPostReasonSheetState extends State<_ReportPostReasonSheet> {
  String? _selectedReason;
  final _detailController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  void _close() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  bool get _canSubmit =>
      _selectedReason != null &&
      (_selectedReason != 'Anderes' || _detailController.text.trim().length >= 5);

  Future<void> _submit() async {
    if (!_canSubmit || _submitting) return;
    final reason = _selectedReason == 'Anderes'
        ? _detailController.text.trim()
        : _selectedReason!;
    setState(() => _submitting = true);
    try {
      await context.read<ReportService>().reportPost(
        postId: widget.post.id,
        reason: reason,
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
              const SizedBox(height: 4),
              Text(
                'Warum meldest du den Beitrag von @${widget.post.username}?',
                style: TextStyle(color: t.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              // Reason chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kReportReasons.map((r) {
                  final selected = _selectedReason == r.label;
                  return GestureDetector(
                    onTap: _submitting
                        ? null
                        : () => setState(() => _selectedReason = r.label),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? t.goldSoft : t.surfaceWeak,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? t.goldBorder : t.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            r.icon,
                            size: 15,
                            color: selected ? t.goldText : t.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            r.label,
                            style: TextStyle(
                              color: selected ? t.goldText : t.text,
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              // Extra detail field for "Anderes"
              if (_selectedReason == 'Anderes') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _detailController,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 300,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: t.text),
                  cursorColor: t.gold,
                  decoration: InputDecoration(
                    hintText: 'Beschreibe das Problem kurz...',
                    hintStyle: TextStyle(color: t.textFaint),
                    counterStyle: TextStyle(color: t.textFaint),
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
                ),
              ],
              const SizedBox(height: 14),
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
                      onPressed: (_canSubmit && !_submitting) ? _submit : null,
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
    );
  }
}

// ── Shared sheet widgets ───────────────────────────────────────────────────

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
