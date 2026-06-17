import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'ios_widget_service.dart';
import 'widget_snapshot.dart';
import '../features/posts/providers/profile_posts_provider.dart';
import '../features/leaderboard/providers/leaderboard_provider.dart';
import '../features/friends/providers/friends_today_provider.dart';
import '../features/friends/models/api_friend.dart';

const String _defaultAvatarColorHex = '#6A7C8C';

/// Builds a [WidgetSnapshot] from whichever providers currently have data
/// and pushes it to the iOS home-screen widgets. Safe to call at any time —
/// providers that haven't loaded yet just contribute empty/zero values.
class WidgetSyncService {
  static void push(BuildContext context) {
    final posts = context.read<ProfilePostsProvider>();
    final leaderboard = context.read<LeaderboardProvider>();
    final friendsToday = context.read<FriendsTodayProvider>();

    final weekly = List.of(leaderboard.friendEntries)
      ..sort((a, b) => b.drinksWk.compareTo(a.drinksWk));
    final youIndex = weekly.indexWhere((e) => e.isYou);

    IosWidgetService.updateSnapshot(
      WidgetSnapshot(
        totalPints: posts.totalPints,
        pintsToday: posts.postsToday,
        last24hCount: posts.last24hHours.length,
        last24hHours: posts.last24hHours,
        streakDays: posts.streak,
        streakGrid: posts.widgetStreakGrid,
        friendsTodayCount: friendsToday.data.count,
        friendsTotal: friendsToday.data.total,
        friendAvatars: friendsToday.data.friends
            .map(_toWidgetAvatar)
            .toList(),
        circleRank: youIndex >= 0 ? youIndex + 1 : 0,
        circleTotal: weekly.length,
        circleTrend: youIndex >= 0 ? weekly[youIndex].wkMove : 0,
        circlePodium: [
          for (var i = 0; i < weekly.length && i < 3; i++)
            WidgetPodiumEntry(
              rank: i + 1,
              value: weekly[i].drinksWk,
              isYou: weekly[i].isYou,
            ),
        ],
      ),
    );
  }

  static WidgetAvatar _toWidgetAvatar(ApiFriend f) {
    final initial = (f.avatarInitial?.isNotEmpty ?? false)
        ? f.avatarInitial!
        : (f.username.isNotEmpty ? f.username[0] : '?');
    return WidgetAvatar(
      initial: initial.toUpperCase(),
      colorHex: f.avatarColor ?? _defaultAvatarColorHex,
    );
  }
}
