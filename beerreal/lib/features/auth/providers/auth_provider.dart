import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:dio/dio.dart';
import '../../../core/app_cache_manager.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthStatus _status = AuthStatus.checking;
  AppUser? _user;
  String? _errorMessage;

  AuthProvider(this._authService);

  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get errorMessage => _errorMessage;

  Future<void> checkAuth() async {
    _status = AuthStatus.checking;
    notifyListeners();
    try {
      _user = await _authService.me();
      _status = _user != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({
    required String emailOrUsername,
    required String password,
  }) async {
    _errorMessage = null;
    try {
      _user = await _authService.login(
        emailOrUsername: emailOrUsername,
        password: password,
      );
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
      _user = await _authService.register(
        username: username,
        email: email,
        password: password,
      );
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

  void updateUser(AppUser user) {
    _user = user;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    await AppCacheManager.instance.emptyCache();
    PaintingBinding.instance.imageCache.clear();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return data['message'] as String? ?? 'Request failed.';
    }
    return 'Request failed.';
  }
}
