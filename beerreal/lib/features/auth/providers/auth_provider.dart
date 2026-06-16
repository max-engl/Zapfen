import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/app_cache_manager.dart';
import '../../../core/feed_database.dart';
import '../models/app_update_info.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthStatus _status = AuthStatus.checking;
  AppUser? _user;
  String? _errorMessage;
  AppUpdateInfo _updateInfo = AppUpdateInfo.none;

  AuthProvider(this._authService);

  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get errorMessage => _errorMessage;
  AppUpdateInfo get updateInfo => _updateInfo;
  bool get updateRequired => _updateInfo.updateRequired;
  bool get updateRecommended => _updateInfo.updateRecommended;
  List<String> get patchNotes => _updateInfo.patchNotes;
  String get latestVersion => _updateInfo.latestVersion;
  String get recommendedVersion => _updateInfo.recommendedVersion;
  String get mandatoryVersion => _updateInfo.mandatoryVersion;

  Future<void> checkAuth() async {
    debugPrint('[startup] checkAuth start');
    _status = AuthStatus.checking;
    notifyListeners();
    try {
      try {
        _updateInfo = await _authService.versionPolicy();
      } catch (e) {
        debugPrint('[startup] version policy error: $e');
      }
      final result = await _authService.me();
      _user = result.user;
      if (result.updateInfo.currentVersion.isNotEmpty) {
        _updateInfo = result.updateInfo;
      }
      _status = _user != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
    } catch (e) {
      debugPrint('[startup] checkAuth error: $e');
      _status = AuthStatus.unauthenticated;
    }
    debugPrint('[startup] checkAuth done → $_status');
    notifyListeners();
  }

  Future<bool> login({
    required String emailOrUsername,
    required String password,
  }) async {
    _errorMessage = null;
    try {
      final result = await _authService.login(
        emailOrUsername: emailOrUsername,
        password: password,
      );
      _user = result.user;
      _updateInfo = result.updateInfo;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    try {
      final result = await _authService.register(
        username: username,
        email: email,
        password: password,
      );
      _user = result.user;
      _updateInfo = result.updateInfo;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
      debugPrint(
        '[auth] register failed — status=${e.response?.statusCode} extracted="$_errorMessage" body=${e.response?.data}',
      );
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Something went wrong. Please try again.';
      debugPrint('[auth] register unexpected error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    try {
      await _authService.requestPasswordReset(email);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    _errorMessage = null;
    try {
      await _authService.resetPassword(token: token, newPassword: newPassword);
      return true;
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void updateUser(AppUser user) {
    _user = user;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    await AppCacheManager.instance.emptyCache();
    PaintingBinding.instance.imageCache.clear();
    await FeedDatabase.instance.clear();
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where(
          (k) =>
              k.startsWith('pint_') &&
              k != 'pint_theme_dark' &&
              k != 'pint_onboarding_done',
        )
        .toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Called by ApiClient when a 401 is received — clears state without
  /// async side-effects so it's safe to call from a Dio interceptor.
  void forceLogout() {
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return data['message'] as String? ?? 'Request failed.';
    }
    if (e.response == null) {
      debugPrint('[auth] connection error type=${e.type} msg=${e.message}');
      return 'Keine Verbindung zum Server. Bitte überprüfe deine Internetverbindung.';
    }
    return 'Request failed.';
  }
}
