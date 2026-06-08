import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'core/notification_service.dart';
import 'core/friend_database.dart';
import 'theme.dart';
import 'core/api/api_client.dart';
import 'core/storage/token_storage.dart';
import 'core/feed_database.dart';
import 'core/post_cache_manager.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/posts/services/post_service.dart';
import 'features/posts/services/comment_service.dart';
import 'features/posts/providers/feed_provider.dart';
import 'features/posts/providers/profile_posts_provider.dart';
import 'features/friends/services/friend_service.dart';
import 'features/friends/providers/friend_provider.dart';
import 'features/profile/services/profile_service.dart';
import 'features/drinks/services/drink_service.dart';
import 'features/drinks/providers/drink_provider.dart';
import 'features/leaderboard/services/leaderboard_service.dart';
import 'features/leaderboard/providers/leaderboard_provider.dart';
import 'features/stats/services/stats_service.dart';
import 'features/stats/providers/stats_provider.dart';
import 'features/reports/services/report_service.dart';
import 'features/notifications/services/notification_api_service.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/achievements/services/achievement_service.dart';
import 'features/achievements/providers/achievement_provider.dart';
import 'features/recap/services/recap_service.dart';
import 'features/bingo/services/bingo_service.dart';
import 'features/bingo/providers/bingo_provider.dart';
import 'screens/night_recap_screen.dart';
import 'widgets/avatar.dart';
import 'widgets/pint_loading.dart';
import 'widgets/top_bar.dart';
import 'widgets/bottom_nav.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/capture_screen.dart';
import 'screens/map_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/post_detail_screen.dart';
import 'screens/friend_profile_screen.dart';
import 'features/friends/models/api_friend.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  try {
    await _main();
  } catch (e, st) {
    debugPrint('[startup] FATAL: $e\n$st');
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Startup error:\n$e',
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Keep more decoded images in RAM so scroll-back never re-decodes from disk.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 256 << 20; // 256 MB

  debugPrint('[startup] Firebase.initializeApp...');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[startup] Firebase ready');
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  debugPrint('[startup] NotificationService.init...');
  await NotificationService.init();
  debugPrint('[startup] NotificationService ready');

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage);
  final authService = AuthService(apiClient, tokenStorage);
  final authProvider = AuthProvider(authService);
  apiClient.onUnauthorized = () => authProvider.forceLogout();
  final postService = PostService(apiClient);
  final commentService = CommentService(apiClient);
  final friendService = FriendService(apiClient);
  final profileService = ProfileService(apiClient);
  final drinkService = DrinkService(apiClient);
  final leaderboardService = LeaderboardService(apiClient);
  final statsService = StatsService(apiClient);
  final reportService = ReportService(apiClient);
  final recapService = RecapService(apiClient);
  final bingoService = BingoService(apiClient);
  final notificationApiService = NotificationApiService(apiClient);
  final achievementService = AchievementService(apiClient);

  // Initialize post cache manager
  final prefs = await SharedPreferences.getInstance();
  final postCacheManager = PostCacheManager(prefs);

  runApp(
    MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: tokenStorage),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthService>.value(value: authService),
        Provider<PostService>.value(value: postService),
        Provider<CommentService>.value(value: commentService),
        Provider<FriendService>.value(value: friendService),
        Provider<ProfileService>.value(value: profileService),
        Provider<PostCacheManager>.value(value: postCacheManager),
        Provider<ReportService>.value(value: reportService),
        Provider<RecapService>.value(value: recapService),
        Provider<BingoService>.value(value: bingoService),
        Provider<AchievementService>.value(value: achievementService),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<FeedProvider>(
          create: (_) => FeedProvider(postService, FeedDatabase.instance),
        ),
        ChangeNotifierProvider<ProfilePostsProvider>(
          create: (_) => ProfilePostsProvider(postService, FeedDatabase.instance),
        ),
        ChangeNotifierProvider<FriendProvider>(
          create: (_) => FriendProvider(friendService, FriendDatabase.instance),
        ),
        Provider<DrinkService>.value(value: drinkService),
        ChangeNotifierProvider<DrinkProvider>(
          create: (_) => DrinkProvider(drinkService),
        ),
        ChangeNotifierProvider<LeaderboardProvider>(
          create: (_) => LeaderboardProvider(leaderboardService),
        ),
        ChangeNotifierProvider<StatsProvider>(
          create: (_) => StatsProvider(statsService),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(notificationApiService),
        ),
        ChangeNotifierProvider<AchievementProvider>(
          create: (_) => AchievementProvider(achievementService),
        ),
        ChangeNotifierProvider<BingoProvider>(
          create: (_) => BingoProvider(bingoService),
        ),
      ],
      child: const PintRoot(),
    ),
  );
}

// ── Root ─────────────────────────────────────────────────────────────────────

class PintRoot extends StatefulWidget {
  const PintRoot({super.key});

  @override
  State<PintRoot> createState() => _PintRootState();
}

class _PintRootState extends State<PintRoot> {
  PintTheme _theme = PintTheme.light;
  bool _feedPreloaded = false;
  bool _preloadStarted = false;
  bool _onboardingDone = false;
  bool _onboardingChecked = false;
  PintScreen _postOnboardingScreen = PintScreen.feed;

  // Deep links
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _deepLinkSub;
  String? _pendingInviteToken;

  static const _themePrefKey = 'pint_theme_dark';
  static const _onboardingPrefKey = 'pint_onboarding_done';
  static const _forceOnboarding = false; // set false to skip in prod

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _initDeepLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuth();
    });
  }

  Future<void> _initDeepLinks() async {
    _deepLinkSub = _appLinks.uriLinkStream.listen(_handleDeepLink);
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handleDeepLink(initial);
    } catch (_) {}
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme != 'zapfen' || uri.host != 'invite') return;
    final token = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    if (token == null || token.isEmpty) return;

    final navCtx = _navigatorKey.currentContext;
    if (navCtx != null) {
      _showInviteSheet(navCtx, token);
    } else {
      // App not fully ready yet — queue it
      _pendingInviteToken = token;
    }
  }

  void _showInviteSheet(BuildContext ctx, String token) {
    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _InviteSheet(token: token),
    );
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    super.dispose();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themePrefKey) ?? false;
    final onboardingDone = prefs.getBool(_onboardingPrefKey) ?? false;
    if (mounted) {
      debugPrint('[startup] _onboardingChecked = true');
      setState(() {
        _theme = isDark ? PintTheme.dark : PintTheme.light;
        _onboardingDone = _forceOnboarding ? false : onboardingDone;
        _onboardingChecked = true;
      });
    }
  }

  Future<void> _completeOnboarding({
    PintScreen initialScreen = PintScreen.feed,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingPrefKey, true);
    if (mounted) {
      setState(() {
        _onboardingDone = true;
        _postOnboardingScreen = initialScreen;
      });
    }
  }

  Future<void> _toggleTheme() async {
    final next = _theme.isDark ? PintTheme.light : PintTheme.dark;
    setState(() => _theme = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePrefKey, next.isDark);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _theme.isDark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
    );

    final authStatus = context.watch<AuthProvider>().status;

    // As soon as auth succeeds, kick off the SQLite preload exactly once.
    // The loading screen stays visible until preload finishes so the feed
    // screen never renders with an empty post list.
    if (authStatus == AuthStatus.authenticated && !_preloadStarted) {
      _preloadStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('[startup] auth OK — starting cache preload');
        context.read<FriendProvider>().preloadFromCache();
        context.read<ProfilePostsProvider>().preloadFromCache();
        context.read<FeedProvider>().preloadFromCache().then((_) {
          debugPrint('[startup] _feedPreloaded = true');
          if (mounted) setState(() => _feedPreloaded = true);
        });
      });
    }

    final showApp =
        authStatus == AuthStatus.authenticated &&
        _feedPreloaded &&
        _onboardingChecked;

    // Flush a queued deep link once the navigator is ready
    if (showApp && _onboardingDone && _pendingInviteToken != null) {
      final token = _pendingInviteToken!;
      _pendingInviteToken = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _navigatorKey.currentContext;
        if (ctx != null && mounted) _showInviteSheet(ctx, token);
      });
    }

    return MaterialApp(
      title: 'Zapfen.',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: ThemeData(useMaterial3: true),
      builder: (context, child) => PintThemeProvider(
        theme: _theme,
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.translucent,
          child: child!,
        ),
      ),
      home: switch (authStatus) {
        AuthStatus.unauthenticated => const AuthScreen(),
        _ when showApp && !_onboardingDone => OnboardingScreen(
          onComplete: () => _completeOnboarding(),
          onGoToFriends: () =>
              _completeOnboarding(initialScreen: PintScreen.friends),
        ),
        _ when showApp => PintApp(
          onToggleTheme: _toggleTheme,
          initialScreen: _postOnboardingScreen,
        ),
        _ => const _LoadingScreen(),
      },
    );
  }
}

// ── Loading screen ────────────────────────────────────────────────────────────

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      body: const Center(child: PintLogoLoaderInline(size: 72)),
    );
  }
}

// ── Main app shell ────────────────────────────────────────────────────────────

class PintApp extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final PintScreen initialScreen;
  const PintApp({
    super.key,
    required this.onToggleTheme,
    this.initialScreen = PintScreen.feed,
  });

  @override
  State<PintApp> createState() => _PintAppState();
}

class _PintAppState extends State<PintApp> {
  late PintScreen _screen = widget.initialScreen;
  bool _captureOpen = false;

  @override
  void initState() {
    super.initState();
    NotificationService.setupPermissions(context.read<ApiClient>());
    _setupNotificationTapHandlers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().load();
    });
  }

  void _setupNotificationTapHandlers() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data);
    });

    FirebaseMessaging.instance.getInitialMessage().then((initial) {
      if (initial != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _handleNotificationTap(initial.data);
        });
      }
    });
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'post':
        final postId = data['postId'] as String?;
        setState(() => _screen = PintScreen.feed);
        if (postId != null) _openPostById(postId);
      case 'friend_request':
        setState(() => _screen = PintScreen.friends);
      case 'friend_accepted':
        setState(() => _screen = PintScreen.friends);
        _openFriendProfile(data);
      case 'group_active':
        setState(() => _screen = PintScreen.feed);
      case 'night_recap':
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) NightRecapScreen.show(context);
        });
    }
  }

  Future<void> _openPostById(String postId) async {
    try {
      final post = await context.read<PostService>().getPostById(postId);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
      );
    } catch (_) {}
  }

  void _openFriendProfile(Map<String, dynamic> data) {
    final actorId = data['actorId'] as String?;
    final actorUsername = data['actorUsername'] as String?;
    if (actorId == null || actorUsername == null) return;

    final friend = ApiFriend(
      id: actorId,
      username: actorUsername,
      avatarUrl: data['actorAvatarUrl'] as String?,
      avatarColor: data['actorAvatarColor'] as String?,
      avatarInitial: data['actorAvatarInitial'] as String?,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => FriendProfileScreen(friend: friend)),
      );
    });
  }

  void _openCapture() => setState(() => _captureOpen = true);

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                PintTopBar(
                  unreadNotifications: context
                      .watch<NotificationProvider>()
                      .unreadCount,
                  onBell: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: context.read<NotificationProvider>(),
                          child: ChangeNotifierProvider.value(
                            value: context.read<FriendProvider>(),
                            child: NotificationsScreen(
                              onGoToFriends: () {
                                Navigator.of(context).pop();
                                setState(() => _screen = PintScreen.friends);
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  onToggleTheme: widget.onToggleTheme,
                  onStats: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StatsScreen()),
                    );
                  },
                  onLeaderboard: () {
                    context.read<LeaderboardProvider>().refresh();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LeaderboardScreen(),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) {
                      final scale = Tween<double>(begin: 0.93, end: 1.0)
                          .animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            ),
                          );
                      return ScaleTransition(
                        scale: scale,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(_screen),
                      child: _buildScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PintBottomNav(
              current: _screen,
              onSelect: (s) => setState(() => _screen = s),
              onCapture: _openCapture,
              pendingRequests: context.watch<FriendProvider>().requests.length,
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    ),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: _captureOpen
                ? CaptureScreen(
                    key: const ValueKey('capture_screen'),
                    postService: context.read<PostService>(),
                    drinkProvider: context.read<DrinkProvider>(),
                    onClose: () => setState(() => _captureOpen = false),
                    onPosted: (post) {
                      setState(() => _captureOpen = false);
                      context.read<FeedProvider>().prepend(post);
                      final profilePosts = context.read<ProfilePostsProvider>();
                      final previousStreak = profilePosts.streak;
                      profilePosts.prepend(post);
                      if (previousStreak < 5 && profilePosts.streak >= 5) {
                        HapticFeedback.mediumImpact();
                      }
                      context.read<AchievementProvider>().refresh();
                      setState(() => _screen = PintScreen.feed);
                    },
                  )
                : const SizedBox.shrink(key: ValueKey('capture_screen_empty')),
          ),
        ],
      ),
    );
  }

  Widget _buildScreen() {
    return switch (_screen) {
      PintScreen.feed => FeedScreen(onCapture: _openCapture),
      PintScreen.map => const MapScreen(),
      PintScreen.friends => const FriendsScreen(),
      PintScreen.profile => const ProfileScreen(),
    };
  }
}

// ── Invite sheet (shown when app is opened via zapfen://invite/<token>) ───────

class _InviteSheet extends StatefulWidget {
  final String token;
  const _InviteSheet({required this.token});

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  bool _resolving = true;
  Map<String, dynamic>? _inviter;
  bool _sending = false;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final data = await context.read<FriendProvider>().resolveInviteToken(
      widget.token,
    );
    if (!mounted) return;
    if (data == null) {
      setState(() {
        _error = 'Ungültiger Einladungslink.';
        _resolving = false;
      });
    } else {
      setState(() {
        _inviter = data;
        _resolving = false;
      });
    }
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final ok = await context.read<FriendProvider>().acceptInviteToken(
      widget.token,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      _done = ok;
      _error = ok ? null : 'Anfrage fehlgeschlagen.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: t.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: t.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (_resolving)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: t.gold,
                ),
              ),
            )
          else if (_error != null && !_done)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                _error!,
                style: TextStyle(color: t.textMuted, fontSize: 14),
              ),
            )
          else if (_done)
            Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: t.goldSoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: t.goldBorder),
                  ),
                  child: Icon(Icons.check, color: t.goldText, size: 28),
                ),
                const SizedBox(height: 14),
                Text(
                  'Anfrage gesendet!',
                  style: TextStyle(
                    color: t.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '@${_inviter?['username'] ?? ''} bekommt jetzt deine Anfrage.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: t.surfaceWeak,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.border),
                    ),
                    child: Text(
                      'Schließen',
                      style: TextStyle(
                        color: t.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else if (_inviter != null) ...[
            PintAvatar(
              size: 64,
              imageUrl: _inviter!['avatarUrl'] as String?,
              avatarColor: _inviter!['avatarColor'] as String?,
              initials: _inviter!['avatarInitial'] as String?,
              ring: true,
            ),
            const SizedBox(height: 14),
            Text(
              'Freundschaftsanfrage senden?',
              style: TextStyle(
                color: t.text,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '@${_inviter!['username']}',
              style: TextStyle(color: t.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: t.surfaceWeak,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: t.border),
                      ),
                      child: Center(
                        child: Text(
                          'Abbrechen',
                          style: TextStyle(
                            color: t.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _sending ? null : _send,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: t.gold,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: _sending
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: t.goldInk,
                                ),
                              )
                            : Text(
                                'Hinzufügen',
                                style: TextStyle(
                                  color: t.goldInk,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
