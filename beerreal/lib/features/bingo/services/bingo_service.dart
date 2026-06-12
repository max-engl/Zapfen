import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';

class BingoCell {
  final String id;
  final String label;
  final String emoji;
  final bool done;

  const BingoCell({
    required this.id,
    required this.label,
    required this.emoji,
    required this.done,
  });

  bool get isFree => id == 'free';

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'emoji': emoji,
        'done': done,
      };

  factory BingoCell.fromJson(Map<String, dynamic> j) => BingoCell(
    id: (j['id'] as String?) ?? '',
    label: (j['label'] as String?) ?? '',
    emoji: (j['emoji'] as String?) ?? '🍺',
    done: (j['done'] as bool?) ?? false,
  );
}

class BingoCard {
  final List<BingoCell> cells;
  final int completedLines;
  final bool isBlackout;
  final String monthLabel;
  final int totalDone;

  const BingoCard({
    required this.cells,
    required this.completedLines,
    required this.isBlackout,
    required this.monthLabel,
    required this.totalDone,
  });

  Map<String, dynamic> toJson() => {
        'card': cells.map((c) => c.toJson()).toList(),
        'completedLines': completedLines,
        'isBlackout': isBlackout,
        'monthLabel': monthLabel,
        'totalDone': totalDone,
      };

  factory BingoCard.fromJson(Map<String, dynamic> j) => BingoCard(
    cells: (j['card'] as List<dynamic>? ?? [])
        .map((e) => BingoCell.fromJson(e as Map<String, dynamic>))
        .toList(),
    completedLines: (j['completedLines'] as num?)?.toInt() ?? 0,
    isBlackout: (j['isBlackout'] as bool?) ?? false,
    monthLabel: (j['monthLabel'] as String?) ?? '',
    totalDone: (j['totalDone'] as num?)?.toInt() ?? 0,
  );
}

class BingoService {
  final ApiClient _api;

  const BingoService(this._api);

  Future<BingoCard?> fetchCard() async {
    try {
      final res = await _api.dio.get(ApiConstants.bingoCard);
      return BingoCard.fromJson(res.data as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }

  Future<BingoCard?> fetchCardForUser(String userId) async {
    try {
      final res = await _api.dio.get(ApiConstants.bingoCardForUser(userId));
      return BingoCard.fromJson(res.data as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }
}
