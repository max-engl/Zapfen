class ApiConstants {
  static const String host = '10.170.54.9';
  static String get baseUrl => 'http://$host:3000';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  // Posts
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
  static String sendFriendRequest(String userId) => '/friends/request/$userId';
  static String acceptFriendRequest(String userId) => '/friends/accept/$userId';
  static String removeFriend(String userId) => '/friends/$userId';
  static const String myInvite = '/friends/invite';
  static String resolveInvite(String token) => '/friends/invite/$token';
  static String acceptInvite(String token) => '/friends/invite/$token/accept';

  // Users / Profile
  static const String updateAvatar = '/users/me/avatar';
  static const String removeAvatar = '/users/me/avatar';
  static const String updateMe = '/users/me';
  static const String searchUsers = '/users/search';

  // Auth – password change
  static const String changePassword = '/auth/password';

  // Post reactions
  static String reactToPost(String id) => '/posts/$id/reactions';

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
