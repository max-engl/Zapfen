import 'dart:convert';
import 'post_reaction.dart';

class FeedPost {
  final String id;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String? avatarColor;
  final String? avatarInitial;
  final String caption;
  final String drinkName;
  final String drinkEmoji;
  final int? rating;
  final int likes;
  final int comments;
  final int totalReactions;
  final int views;
  final String imageUrl;
  final String? imagePath;
  final String selfieUrl;
  final String? selfiePath;
  final bool likedByMe;
  final String? myReaction;
  final List<PostReaction> reactions;
  final DateTime createdAt;
  final double? lat;
  final double? lng;

  const FeedPost({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.avatarColor,
    this.avatarInitial,
    required this.caption,
    this.drinkName = '',
    this.drinkEmoji = '',
    this.rating,
    required this.likes,
    required this.comments,
    this.totalReactions = 0,
    this.views = 0,
    required this.imageUrl,
    this.imagePath,
    required this.selfieUrl,
    this.selfiePath,
    this.likedByMe = false,
    this.myReaction,
    this.reactions = const [],
    required this.createdAt,
    this.lat,
    this.lng,
  });

  String get drinkLabel {
    if (drinkName.isEmpty) return '';
    if (drinkEmoji.isNotEmpty) return '$drinkEmoji $drinkName';
    return drinkName;
  }

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final drink = json['drink'] as Map<String, dynamic>? ?? {};
    final myReaction = json['myReaction'] as String?;
    final rawReactions = json['reactions'] as List<dynamic>? ?? [];
    return FeedPost(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      userId: (user['_id'] ?? user['id'] ?? '') as String,
      username: (user['username'] ?? '') as String,
      avatarUrl: user['avatarUrl'] as String?,
      avatarColor: user['avatarColor'] as String?,
      avatarInitial: user['avatarInitial'] as String?,
      caption: (json['caption'] ?? '') as String,
      drinkName: (drink['name'] as String?) ?? '',
      drinkEmoji: (drink['emoji'] as String?) ?? '',
      rating: (json['rating'] as num?)?.toInt(),
      likes: (stats['likes'] ?? 0) as int,
      comments: (stats['comments'] ?? 0) as int,
      totalReactions: (stats['reactions'] ?? 0) as int,
      views: (stats['views'] ?? 0) as int,
      imageUrl: (json['imageUrl'] ?? '') as String,
      imagePath: json['imagePath'] as String?,
      selfieUrl: (json['selfieUrl'] ?? '') as String,
      selfiePath: json['selfiePath'] as String?,
      likedByMe: (json['likedByMe'] ?? false) as bool,
      myReaction: myReaction,
      reactions: rawReactions
          .map(
            (e) => PostReaction.fromJson(e as Map<String, dynamic>, myReaction),
          )
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }

  // ── SQLite serialization ──────────────────────────────────────────────────

  factory FeedPost.fromSqliteRow(Map<String, dynamic> row) {
    final myReaction = row['my_reaction'] as String?;
    final rawReactions =
        jsonDecode(row['reactions'] as String) as List<dynamic>;
    return FeedPost(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      username: row['username'] as String,
      avatarUrl: row['avatar_url'] as String?,
      avatarColor: row['avatar_color'] as String?,
      avatarInitial: row['avatar_initial'] as String?,
      caption: row['caption'] as String,
      drinkName: row['drink_name'] as String,
      drinkEmoji: row['drink_emoji'] as String,
      rating: row['rating'] as int?,
      likes: row['likes'] as int,
      comments: row['comments'] as int,
      totalReactions: row['total_reactions'] as int,
      views: row['views'] as int,
      imageUrl: row['image_url'] as String,
      imagePath: row['image_path'] as String?,
      selfieUrl: row['selfie_url'] as String,
      selfiePath: row['selfie_path'] as String?,
      likedByMe: (row['liked_by_me'] as int) == 1,
      myReaction: myReaction,
      reactions: rawReactions
          .map(
            (e) => PostReaction.fromJson(e as Map<String, dynamic>, myReaction),
          )
          .toList(),
      createdAt: DateTime.parse(row['created_at'] as String),
      lat: row['lat'] as double?,
      lng: row['lng'] as double?,
    );
  }

  Map<String, dynamic> toSqliteRow(int sortOrder) => {
    'id': id,
    'sort_order': sortOrder,
    'user_id': userId,
    'username': username,
    'avatar_url': avatarUrl,
    'avatar_color': avatarColor,
    'avatar_initial': avatarInitial,
    'caption': caption,
    'drink_name': drinkName,
    'drink_emoji': drinkEmoji,
    'rating': rating,
    'likes': likes,
    'comments': comments,
    'total_reactions': totalReactions,
    'views': views,
    'image_url': imageUrl,
    'image_path': imagePath,
    'selfie_url': selfieUrl,
    'selfie_path': selfiePath,
    'liked_by_me': likedByMe ? 1 : 0,
    'my_reaction': myReaction,
    'reactions': jsonEncode(
      reactions.map((r) => {'emoji': r.emoji, 'count': r.count}).toList(),
    ),
    'created_at': createdAt.toIso8601String(),
    'lat': lat,
    'lng': lng,
  };

  FeedPost copyWith({
    int? likes,
    bool? likedByMe,
    int? totalReactions,
    String? myReaction,
    List<PostReaction>? reactions,
    bool clearMyReaction = false,
    int? comments,
    int? views,
  }) => FeedPost(
    id: id,
    userId: userId,
    username: username,
    avatarUrl: avatarUrl,
    avatarColor: avatarColor,
    avatarInitial: avatarInitial,
    caption: caption,
    drinkName: drinkName,
    drinkEmoji: drinkEmoji,
    rating: rating,
    likes: likes ?? this.likes,
    comments: comments ?? this.comments,
    totalReactions: totalReactions ?? this.totalReactions,
    views: views ?? this.views,
    imageUrl: imageUrl,
    imagePath: imagePath,
    selfieUrl: selfieUrl,
    selfiePath: selfiePath,
    likedByMe: likedByMe ?? this.likedByMe,
    myReaction: clearMyReaction ? null : (myReaction ?? this.myReaction),
    reactions: reactions ?? this.reactions,
    createdAt: createdAt,
    lat: lat,
    lng: lng,
  );

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) {
      final m = diff.inMinutes % 60;
      return m > 0 ? '${diff.inHours}h ${m}m' : '${diff.inHours}h';
    }
    return '${diff.inDays}d';
  }
}

/// Builds an 84-cell heatmap grid (col-major, 12 weeks × 7 days) from a list
/// of posts. Cell 0 = 83 days ago, cell 83 = today.
List<int> buildHeatmapFromPosts(List<FeedPost> posts) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final grid = List<int>.filled(84, 0);
  for (final post in posts) {
    final postDay = DateTime(
      post.createdAt.year,
      post.createdAt.month,
      post.createdAt.day,
    );
    final daysAgo = today.difference(postDay).inDays;
    if (daysAgo < 0 || daysAgo > 83) continue;
    final index = 83 - daysAgo;
    grid[index]++;
  }
  return grid;
}
