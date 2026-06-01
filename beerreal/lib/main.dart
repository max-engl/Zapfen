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
import 'features/notifications/services/notification_api_service.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'widgets/pint_loading.dart';
import 'widgets/top_bar.dart';
import 'widgets/bottom_nav.dart';
import 'screens/auth_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/capture_screen.dart';
import 'screens/map_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/notifications_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Keep more decoded images in RAM so scroll-back never re-decodes from disk.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 256 << 20; // 256 MB

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage);
  final authService = AuthService(apiClient, tokenStorage);
  final postService = PostService(apiClient);
  final commentService = CommentService(apiClient);
  final friendService = FriendService(apiClient);
  final profileService = ProfileService(apiClient);
  final drinkService = DrinkService(apiClient);
  final leaderboardService = LeaderboardService(apiClient);
  final notificationApiService = NotificationApiService(apiClient);

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
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authService),
        ),
        ChangeNotifierProvider<FeedProvider>(
          create: (_) => FeedProvider(postService, FeedDatabase.instance),
        ),
        ChangeNotifierProvider<ProfilePostsProvider>(
          create: (_) => ProfilePostsProvider(postService),
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
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(notificationApiService),
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

  static const _themePrefKey = 'pint_theme_dark';

  @override
  void initState() {
    super.initState();
    _loadTheme();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuth();
    });
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themePrefKey) ?? false;
    if (mounted) {
      setState(() => _theme = isDark ? PintTheme.dark : PintTheme.light);
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
        context.read<FriendProvider>().preloadFromCache();
        context.read<FeedProvider>().preloadFromCache().then((_) {
          if (mounted) setState(() => _feedPreloaded = true);
        });
      });
    }

    final showApp = authStatus == AuthStatus.authenticated && _feedPreloaded;

    return MaterialApp(
      title: 'Zapfen.',
      debugShowCheckedModeBanner: false,
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
        _ when showApp => PintApp(onToggleTheme: _toggleTheme),
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
  const PintApp({super.key, required this.onToggleTheme});

  @override
  State<PintApp> createState() => _PintAppState();
}

class _PintAppState extends State<PintApp> {
  PintScreen _screen = PintScreen.feed;
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

  Future<void> _setupNotificationTapHandlers() async {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data);
    });

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _handleNotificationTap(initial.data);
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'post':
        setState(() => _screen = PintScreen.feed);
      case 'friend_request':
      case 'friend_accepted':
        setState(() => _screen = PintScreen.friends);
    }
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
                  unreadNotifications: context.watch<NotificationProvider>().unreadCount,
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
              posted: false,
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
                      context.read<ProfilePostsProvider>().prepend(post);
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
