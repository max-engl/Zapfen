import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/api_friend.dart';
import '../services/friend_service.dart';
import '../../../core/friend_database.dart';

class FriendProvider extends ChangeNotifier {
  final FriendService _friendService;
  final FriendDatabase _db;

  FriendProvider(this._friendService, this._db);

  List<ApiFriend> _friends = [];
  List<ApiFriendRequest> _requests = [];
  List<ApiSentFriendRequest> _sentRequests = [];
  List<FriendRecommendation> _recommendations = [];
  bool _loading = false;
  bool _recommendationsLoading = false;
  String? _error;

  // per-user UI state for AddFriendScreen
  final Map<String, String> _userActions = {}; // userId → 'requested' | 'accepted' | 'removed'

  List<ApiFriend> get friends => _friends;
  List<ApiFriendRequest> get requests => _requests;
  List<ApiSentFriendRequest> get sentRequests => _sentRequests;
  List<FriendRecommendation> get recommendations => _recommendations;
  bool get loading => _loading;
  bool get recommendationsLoading => _recommendationsLoading;
  String? get error => _error;
  String? actionFor(String userId) => _userActions[userId];

  /// Populates from SQLite cache without a network call.
  /// Call this at app startup so the friends screen renders instantly.
  Future<void> preloadFromCache() async {
    final cachedFriends = await _db.loadFriends();
    final cachedRequests = await _db.loadRequests();
    if (cachedFriends.isNotEmpty || cachedRequests.isNotEmpty) {
      _friends = cachedFriends;
      _requests = cachedRequests;
      notifyListeners();
    }
  }

  Future<void> load() async {
    _error = null;

    // Only show loading shimmer when there's nothing cached yet.
    if (_friends.isEmpty && _requests.isEmpty) {
      _loading = true;
      notifyListeners();
    }

    bool dirty = false;
    try {
      final results = await Future.wait([
        _friendService.getFriends(),
        _friendService.getFriendRequests(),
        _friendService.getSentFriendRequests(),
      ]);
      final newFriends = results[0] as List<ApiFriend>;
      final newRequests = results[1] as List<ApiFriendRequest>;
      final newSentRequests = results[2] as List<ApiSentFriendRequest>;

      final freshFriendIds = newFriends.map((f) => f.id).toSet();
      final currentFriendIds = _friends.map((f) => f.id).toSet();
      final freshRequestIds = newRequests.map((r) => r.id).toSet();
      final currentRequestIds = _requests.map((r) => r.id).toSet();
      final freshSentIds = newSentRequests.map((r) => r.id).toSet();
      final currentSentIds = _sentRequests.map((r) => r.id).toSet();
      dirty = !setEquals(freshFriendIds, currentFriendIds) ||
              !setEquals(freshRequestIds, currentRequestIds) ||
              !setEquals(freshSentIds, currentSentIds);

      if (dirty) {
        _friends = newFriends;
        _requests = newRequests;
        _sentRequests = newSentRequests;
        _db.saveFriends(_friends);
        _db.saveRequests(_requests);
      }
    } on DioException catch (e) {
      _error = _extractError(e);
      dirty = true;
    } catch (_) {
      _error = 'Could not load friends.';
      dirty = true;
    } finally {
      if (_loading || dirty) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> sendRequest(String userId) async {
    try {
      await _friendService.sendFriendRequest(userId);
      _userActions[userId] = 'requested';
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> acceptRequest(String userId) async {
    try {
      await _friendService.acceptFriendRequest(userId);
      final idx = _requests.indexWhere((r) => r.from.id == userId);
      if (idx == -1) {
        // Request already gone (race condition / double-tap) — sync with server
        load();
        return true;
      }
      final req = _requests[idx];
      _friends = [..._friends, req.from];
      _requests.removeWhere((r) => r.from.id == userId);
      _userActions[userId] = 'accepted';
      _db.saveFriends(_friends);
      _db.saveRequests(_requests);
      notifyListeners();
      load(); // sync with server so the friends list is up to date
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> declineRequest(String userId) async {
    try {
      await _friendService.removeFriend(userId);
      _requests.removeWhere((r) => r.from.id == userId);
      _db.saveRequests(_requests);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelSentRequest(String userId) async {
    try {
      await _friendService.removeFriend(userId);
      _sentRequests.removeWhere((r) => r.to.id == userId);
      _userActions[userId] = 'removed';
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeFriend(String userId) async {
    try {
      await _friendService.removeFriend(userId);
      _friends.removeWhere((f) => f.id == userId);
      _userActions[userId] = 'removed';
      _db.saveFriends(_friends);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadRecommendations() async {
    if (_recommendationsLoading) return;
    _recommendationsLoading = true;
    notifyListeners();
    try {
      final results = await _friendService.getRecommendations();
      _recommendations = results;
    } catch (_) {
      _recommendations = [];
    } finally {
      _recommendationsLoading = false;
      notifyListeners();
    }
  }

  Future<List<UserSearchResult>> search(String query) async {
    try {
      return await _friendService.searchUsers(query);
    } catch (_) {
      return [];
    }
  }

  Future<String?> getInviteLink() async {
    try {
      return await _friendService.getInviteLink();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> resolveInviteToken(String token) async {
    try {
      return await _friendService.resolveInviteToken(token);
    } catch (_) {
      return null;
    }
  }

  Future<bool> acceptInviteToken(String token) async {
    try {
      await _friendService.acceptInviteToken(token);
      return true;
    } on DioException catch (e) {
      // 409 = already friends or request already exists — treat as success
      if (e.response?.statusCode == 409) return true;
      return false;
    } catch (_) {
      return false;
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map) return data['message'] as String? ?? 'Request failed.';
    return 'Request failed.';
  }
}
