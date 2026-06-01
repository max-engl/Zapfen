import 'package:sqflite/sqflite.dart';
import '../features/friends/models/api_friend.dart';

class FriendDatabase {
  static final instance = FriendDatabase._();
  FriendDatabase._();

  Database? _db;

  Future<Database> get _database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      '$dir/pint_friends.db',
      version: 2,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE friends (
            id            TEXT PRIMARY KEY,
            username      TEXT NOT NULL,
            avatar_url    TEXT,
            avatar_color  TEXT,
            avatar_initial TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE friend_requests (
            id                   TEXT PRIMARY KEY,
            from_id              TEXT NOT NULL,
            from_username        TEXT NOT NULL,
            from_avatar_url      TEXT,
            from_avatar_color    TEXT,
            from_avatar_initial  TEXT,
            sent_at              TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS friends');
        await db.execute('DROP TABLE IF EXISTS friend_requests');
        await db.execute('''
          CREATE TABLE friends (
            id            TEXT PRIMARY KEY,
            username      TEXT NOT NULL,
            avatar_url    TEXT,
            avatar_color  TEXT,
            avatar_initial TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE friend_requests (
            id                   TEXT PRIMARY KEY,
            from_id              TEXT NOT NULL,
            from_username        TEXT NOT NULL,
            from_avatar_url      TEXT,
            from_avatar_color    TEXT,
            from_avatar_initial  TEXT,
            sent_at              TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<ApiFriend>> loadFriends() async {
    try {
      final db = await _database;
      final rows = await db.query('friends', orderBy: 'username ASC');
      return rows
          .map((r) => ApiFriend(
                id: r['id'] as String,
                username: r['username'] as String,
                avatarUrl: r['avatar_url'] as String?,
                avatarColor: r['avatar_color'] as String?,
                avatarInitial: r['avatar_initial'] as String?,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveFriends(List<ApiFriend> friends) async {
    try {
      final db = await _database;
      final batch = db.batch();
      batch.delete('friends');
      for (final f in friends) {
        batch.insert(
          'friends',
          {
            'id': f.id,
            'username': f.username,
            'avatar_url': f.avatarUrl,
            'avatar_color': f.avatarColor,
            'avatar_initial': f.avatarInitial,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (_) {}
  }

  Future<List<ApiFriendRequest>> loadRequests() async {
    try {
      final db = await _database;
      final rows = await db.query('friend_requests', orderBy: 'sent_at DESC');
      return rows
          .map((r) => ApiFriendRequest(
                id: r['id'] as String,
                from: ApiFriend(
                  id: r['from_id'] as String,
                  username: r['from_username'] as String,
                  avatarUrl: r['from_avatar_url'] as String?,
                  avatarColor: r['from_avatar_color'] as String?,
                  avatarInitial: r['from_avatar_initial'] as String?,
                ),
                sentAt: DateTime.parse(r['sent_at'] as String),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRequests(List<ApiFriendRequest> requests) async {
    try {
      final db = await _database;
      final batch = db.batch();
      batch.delete('friend_requests');
      for (final r in requests) {
        batch.insert(
          'friend_requests',
          {
            'id': r.id,
            'from_id': r.from.id,
            'from_username': r.from.username,
            'from_avatar_url': r.from.avatarUrl,
            'from_avatar_color': r.from.avatarColor,
            'from_avatar_initial': r.from.avatarInitial,
            'sent_at': r.sentAt.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      final db = await _database;
      await Future.wait([db.delete('friends'), db.delete('friend_requests')]);
    } catch (_) {}
  }
}
