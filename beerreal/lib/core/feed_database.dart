import 'package:sqflite/sqflite.dart';
import '../features/posts/models/feed_post.dart';

class FeedDatabase {
  static final instance = FeedDatabase._();
  FeedDatabase._();

  Database? _db;

  Future<Database> get _database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      '$dir/pint_feed.db',
      version: 2,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE posts (
          id          TEXT PRIMARY KEY,
          sort_order  INTEGER NOT NULL,
          user_id     TEXT NOT NULL,
          username    TEXT NOT NULL,
          avatar_url  TEXT,
          caption     TEXT NOT NULL,
          drink_name  TEXT NOT NULL,
          drink_emoji TEXT NOT NULL,
          likes       INTEGER NOT NULL,
          comments    INTEGER NOT NULL,
          total_reactions INTEGER NOT NULL,
          views       INTEGER NOT NULL,
          image_url   TEXT NOT NULL,
          image_path  TEXT,
          selfie_url  TEXT NOT NULL,
          selfie_path TEXT,
          liked_by_me INTEGER NOT NULL,
          my_reaction TEXT,
          reactions   TEXT NOT NULL,
          created_at  TEXT NOT NULL,
          lat         REAL,
          lng         REAL
        )
      '''),
      onUpgrade: (db, oldVersion, newVersion) async {
        // v1 had drink_style and drink_abv; simplest migration is a full rebuild
        await db.execute('DROP TABLE IF EXISTS posts');
        await db.execute('''
          CREATE TABLE posts (
            id          TEXT PRIMARY KEY,
            sort_order  INTEGER NOT NULL,
            user_id     TEXT NOT NULL,
            username    TEXT NOT NULL,
            avatar_url  TEXT,
            caption     TEXT NOT NULL,
            drink_name  TEXT NOT NULL,
            drink_emoji TEXT NOT NULL,
            likes       INTEGER NOT NULL,
            comments    INTEGER NOT NULL,
            total_reactions INTEGER NOT NULL,
            views       INTEGER NOT NULL,
            image_url   TEXT NOT NULL,
            image_path  TEXT,
            selfie_url  TEXT NOT NULL,
            selfie_path TEXT,
            liked_by_me INTEGER NOT NULL,
            my_reaction TEXT,
            reactions   TEXT NOT NULL,
            created_at  TEXT NOT NULL,
            lat         REAL,
            lng         REAL
          )
        ''');
      },
    );
  }

  /// Returns all cached posts in their stored order. Never throws.
  Future<List<FeedPost>> loadPosts() async {
    try {
      final db = await _database;
      final rows = await db.query('posts', orderBy: 'sort_order ASC');
      return rows.map((r) => FeedPost.fromSqliteRow(r)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Replaces the entire cached feed atomically.
  Future<void> savePosts(List<FeedPost> posts) async {
    try {
      final db = await _database;
      final batch = db.batch();
      batch.delete('posts');
      for (var i = 0; i < posts.length; i++) {
        batch.insert(
          'posts',
          posts[i].toSqliteRow(i),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (_) {
      // Silently ignore write failures — network will refresh on next load.
    }
  }

  Future<void> clear() async {
    try {
      final db = await _database;
      await db.delete('posts');
    } catch (_) {}
  }
}
