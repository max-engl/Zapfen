class ApiConstants {
  // Defaults to production. Switch to local dev:
  //   flutter run --dart-define=API_HOST=10.170.54.9 --dart-define=API_SCHEME=http --dart-define=API_PORT=3000
  static const String host = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'api.zapfenapp.de',
  );
  static const String scheme = String.fromEnvironment(
    'API_SCHEME',
    defaultValue: 'https',
  );
  static const String port = String.fromEnvironment(
    'API_PORT',
    defaultValue: '',
  );
  static String get baseUrl =>
      port.isEmpty ? '$scheme://$host' : '$scheme://$host:$port';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  // Postst
  static const String feed = '/posts';
  static const String myPosts = '/posts/me';
  static const String mapPosts = '/posts/map';
  static const String uploadPost = '/posts/upload';
  static String postById(String id) => '/posts/$id';
  static String userPosts(String userId) => '/posts/user/$userId';
  static String deletePost(String id) => '/posts/$id';
  static String likePost(String id) => '/posts/$id/like';
  static String viewPost(String id) => '/posts/$id/view';

  // Friends
  static const String friends = '/friends';
  static const String friendRequests = '/friends/requests';
  static const String friendSentRequests = '/friends/sent-requests';
  static String sendFriendRequest(String userId) => '/friends/request/$userId';
  static String acceptFriendRequest(String userId) => '/friends/accept/$userId';
  static String removeFriend(String userId) => '/friends/$userId';
  static const String friendRecommendations = '/friends/recommendations';
  static const String myInvite = '/friends/invite';
  static String resolveInvite(String token) => '/friends/invite/$token';
  static String acceptInvite(String token) => '/friends/invite/$token/accept';

  // Users / Profile
  static const String updateAvatar = '/users/me/avatar';
  static const String removeAvatar = '/users/me/avatar';
  static const String updateMe = '/users/me';
  static const String searchUsers = '/users/search';

  // Auth – password change / account deletion / password reset
  static const String changePassword = '/auth/password';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String deleteAccount = '/users/me';

  // Post reactions
  static String reactToPost(String id) => '/posts/$id/reactions';
  static String selfieReactToPost(String id) => '/posts/$id/selfie-reaction';

  // Drinks
  static const String drinks = '/drinks';
  static String deleteDrink(String id) => '/drinks/$id';

  // Comments (post-level)
  static String postComments(String postId) => '/posts/$postId/comments';

  // Leaderboard
  static const String leaderboardFriends = '/leaderboard/friends';
  static const String leaderboardGlobal = '/leaderboard/global';

  // Stats
  static const String stats = '/stats';

  // Reports
  static String reportPost(String postId) => '/reports/posts/$postId';

  // Blocks
  static const String blocks = '/blocks';
  static String blockUser(String userId) => '/blocks/$userId';

  // Achievements
  static const String achievementsMe = '/achievements/me';
  static const String achievementLocationTargets =
      '/achievements/location-targets';
  static String achievementsForUser(String userId) =>
      '/achievements/user/$userId';

  // Recap
  static const String nightRecap = '/recap/night';

  // Achievement friend standings
  static String achievementFriendStandings(String achievementId) =>
      '/achievements/$achievementId/friends';

  // Bingo
  static const String bingoCard = '/bingo/card';
  static String bingoCardForUser(String userId) => '/bingo/user/$userId';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationRead(String id) => '/notifications/$id/read';

  // Comments (individual)
  static String replyToComment(String commentId) =>
      '/comments/$commentId/replies';
  static String deleteComment(String commentId) => '/comments/$commentId';
  static String reactToComment(String commentId) =>
      '/comments/$commentId/reactions';
}
