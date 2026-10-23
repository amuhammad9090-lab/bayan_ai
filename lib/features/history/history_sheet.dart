import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/handoff.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../shared/widgets/common.dart';
import 'history_provider.dart';

IconData historyIcon(HistoryType t) {
  switch (t) {
    case HistoryType.ocr:
      return AppIcons.ocr;
    case HistoryType.quran:
      return AppIcons.quran;
    case HistoryType.nahwu:
      return AppIcons.nahwu;
  }
}

String historyLabel(HistoryType t) {
  switch (t) {
    case HistoryType.ocr:
      return 'OCR';
    case HistoryType.quran:
      return "Al-Qur'an";
    case HistoryType.nahwu:
      return 'Nahwu';
  }
}

String historyTitle(HistoryItem h) {
  final s = h.type == HistoryType.ocr ? h.output : h.input;
  final one = s.replaceAll('\n', ' ');
  return one.length > 60 ? '${one.substring(0, 60)}…' : one;
}

/// Pakai ulang item riwayat lewat HandoffService (nggak kenal fitur tujuan).
void reuseHistory(BuildContext context, HistoryItem h) {
  final handoff = context.read<HandoffService>();
  switch (h.type) {
    case HistoryType.ocr:
      handoff.send(HandoffTarget.nahwu, h.output);
      break;
    case HistoryType.nahwu:
      handoff.send(HandoffTarget.nahwu, h.input);
      break;
    case HistoryType.quran:
      handoff.send(HandoffTarget.quran, h.input);
      break;
  }
}

class HistoryTile extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onTap;
  final Widget? trailing;
  const HistoryTile({super.key, required this.item, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      shadow: false,
      padding: EdgeInsets.fromLTRB(12, 12, trailing == null ? 12 : 6, 12),
      onTap: onTap,
      child: Row(
        children: [
          IconChip(icon: historyIcon(item.type), size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  historyTitle(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  '${historyLabel(item.type)} · ${timeAgo(item.createdAt)}',
                  style: TextStyle(fontSize: 11.5, color: context.muted),
                ),
              ],
            ),
          ),
          trailing ?? Icon(AppIcons.chevronRight, size: 18, color: context.muted),
        ],
      ),
    );
  }
}

Future<void> showHistorySheet(BuildContext context, {String query = ''}) {
  final q = query.trim().toLowerCase();
  return showAppSheet<void>(
    context,
    title: q.isEmpty ? 'Riwayat' : 'Riwayat: "${query.trim()}"',
    icon: AppIcons.history,
    builder: (ctx) => Consumer<HistoryProvider>(
      builder: (ctx, history, _) {
        final items = q.isEmpty
            ? history.items
            : history.items
                .where((h) =>
                    h.input.toLowerCase().contains(q) ||
                    h.output.toLowerCase().contains(q))
                .toList();
        if (items.isEmpty) {
          return EmptyState(
            icon: AppIcons.history,
            title: q.isEmpty ? 'Belum ada riwayat' : 'Tidak ada yang cocok',
            subtitle: q.isEmpty
                ? 'Hasil OCR, pencarian ayat, dan analisis nahwu akan tersimpan di sini.'
                : 'Coba kata kunci lain.',
          );
        }
        return Column(
          children: [
            for (final h in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HistoryTile(
                  item: h,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    reuseHistory(context, h);
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => copyText(ctx, h.output, label: 'Hasil'),
                        icon: const Icon(AppIcons.copy, size: 17),
                        color: ctx.muted,
                      ),
                      IconButton(
                        onPressed: () => history.remove(h.id),
                        icon: const Icon(AppIcons.trash, size: 17),
                        color: AppColors.danger,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
