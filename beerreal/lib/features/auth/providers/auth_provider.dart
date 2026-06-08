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
  bool _updateRequired = false;
  List<String> _patchNotes = [];

  AuthProvider(this._authService);

  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get updateRequired => _updateRequired;
  List<String> get patchNotes => _patchNotes;

  Future<void> checkAuth() async {
    debugPrint('[startup] checkAuth start');
    _status = AuthStatus.checking;
    notifyListeners();
    try {
      final result = await _authService.me();
      _user = result.user;
      _updateRequired = result.updateRequired;
      _patchNotes = result.patchNotes;
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
      _updateRequired = result.updateRequired;
      _patchNotes = result.patchNotes;
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
      _updateRequired = result.updateRequired;
      _patchNotes = result.patchNotes;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
      debugPrint('[auth] register failed — status=${e.response?.statusCode} extracted="$_errorMessage" body=${e.response?.data}');
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Something went wrong. Please try again.';
      debugPrint('[auth] register unexpected error: $e');
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
    _updateRequired = false;
    _patchNotes = [];
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Called by ApiClient when a 401 is received — clears state without
  /// async side-effects so it's safe to call from a Dio interceptor.
  void forceLogout() {
    _user = null;
    _updateRequired = false;
    _patchNotes = [];
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
