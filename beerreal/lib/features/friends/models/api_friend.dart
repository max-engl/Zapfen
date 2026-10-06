class ApiFriend {
  final String id;
  final String username;
  final String? avatarUrl;
  final String? avatarColor;
  final String? avatarInitial;

  const ApiFriend({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.avatarColor,
    this.avatarInitial,
  });

  factory ApiFriend.fromJson(Map<String, dynamic> json) {
    return ApiFriend(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      username: (json['username'] ?? '') as String,
      avatarUrl: json['avatarUrl'] as String?,
      avatarColor: json['avatarColor'] as String?,
      avatarInitial: json['avatarInitial'] as String?,
    );
  }
}

class ApiFriendRequest {
  final String id;
  final ApiFriend from;
  final DateTime sentAt;

  const ApiFriendRequest({
    required this.id,
    required this.from,
    required this.sentAt,
  });

  factory ApiFriendRequest.fromJson(Map<String, dynamic> json) {
    return ApiFriendRequest(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      from: ApiFriend.fromJson(json['from'] as Map<String, dynamic>),
      sentAt: DateTime.parse(json['sentAt'] as String),
    );
  }
}

class UserSearchResult {
  final String id;
  final String username;
  final String? avatarUrl;
  final String? avatarColor;
  final String? avatarInitial;

  const UserSearchResult({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.avatarColor,
    this.avatarInitial,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      username: (json['username'] ?? '') as String,
      avatarUrl: json['avatarUrl'] as String?,
      avatarColor: json['avatarColor'] as String?,
      avatarInitial: json['avatarInitial'] as String?,
    );
  }
}

class ApiSentFriendRequest {
  final String id;
  final ApiFriend to;
  final DateTime sentAt;

  const ApiSentFriendRequest({
    required this.id,
    required this.to,
    required this.sentAt,
  });

  factory ApiSentFriendRequest.fromJson(Map<String, dynamic> json) {
    return ApiSentFriendRequest(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      to: ApiFriend.fromJson(json['to'] as Map<String, dynamic>),
      sentAt: DateTime.parse(json['sentAt'] as String),
    );
  }
}

class FriendRecommendation {
  final String id;
  final String username;
  final String? avatarUrl;
  final String? avatarColor;
  final String? avatarInitial;
  final int mutualCount;

  const FriendRecommendation({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.avatarColor,
    this.avatarInitial,
    required this.mutualCount,
  });

  factory FriendRecommendation.fromJson(Map<String, dynamic> json) {
    return FriendRecommendation(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      username: (json['username'] ?? '') as String,
      avatarUrl: json['avatarUrl'] as String?,
      avatarColor: json['avatarColor'] as String?,
      avatarInitial: json['avatarInitial'] as String?,
      mutualCount: (json['mutualCount'] as num?)?.toInt() ?? 0,
    );
  }
}
