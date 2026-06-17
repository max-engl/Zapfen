import 'api_friend.dart';

/// Response of GET /friends/poured-today — who in the circle has already
/// poured today, used for the "Friends today" home-screen widget.
class FriendsToday {
  final int count;
  final int total;
  final List<ApiFriend> friends;

  const FriendsToday({
    required this.count,
    required this.total,
    required this.friends,
  });

  factory FriendsToday.fromJson(Map<String, dynamic> json) {
    final list = (json['friends'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(ApiFriend.fromJson)
        .toList();
    return FriendsToday(
      count: (json['count'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      friends: list,
    );
  }

  static const empty = FriendsToday(count: 0, total: 0, friends: []);
}
