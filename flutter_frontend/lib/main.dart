import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/auth_provider.dart';

import 'core/services/storage_service.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/shop/shop_screen.dart';
import 'presentation/screens/shop/my_shop_screen.dart';
import 'presentation/screens/rules/rules_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/profile/points_history_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/widgets/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await StorageService.init();
  
  runApp(const BoooonusApp());
}

class BoooonusApp extends StatelessWidget {
  const BoooonusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp.router(
            title: 'Booonus',
            theme: AppTheme.lightTheme,
            routerConfig: _createRouter(authProvider),
            debugShowCheckedModeBanner: false,
            // 控制文本缩放，确保跨平台一致性
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  // 限制文本缩放因子，避免过度缩放导致布局问题
                  textScaler: TextScaler.linear(
                    MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.3),
                  ),
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }

  GoRouter _createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: authProvider.isLoggedIn ? '/home' : '/login',
      redirect: (context, state) {
        final isLoggedIn = authProvider.isLoggedIn;
        final isLoggingIn = state.matchedLocation == '/login' ||
                           state.matchedLocation == '/register';
        final isSettings = state.matchedLocation == '/settings';

        // 设置页面可以在任何情况下访问
        if (isSettings) {
          return null;
        }

        if (!isLoggedIn && !isLoggingIn) {
          return '/login';
        }
        if (isLoggedIn && isLoggingIn) {
          return '/home';
        }
        return null;
      },
      routes: [
        // Auth routes
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        
        // Main app routes with bottom navigation
        ShellRoute(
          builder: (context, state, child) => MainNavigation(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/shop',
              builder: (context, state) => const ShopScreen(),
            ),
            GoRoute(
              path: '/rules',
              builder: (context, state) => const RulesScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
        
        // Settings route (outside main navigation)
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),

        // My Shop route (outside main navigation)
        GoRoute(
          path: '/my-shop',
          builder: (context, state) => const MyShopScreen(),
        ),

        // Points History routes (outside main navigation)
        GoRoute(
          path: '/points-history/my',
          builder: (context, state) => const PointsHistoryScreen(
            isMyHistory: true,
          ),
        ),
        GoRoute(
          path: '/points-history/partner',
          builder: (context, state) {
            final targetUserId = state.uri.queryParameters['targetUserId'];
            return PointsHistoryScreen(
              isMyHistory: false,
              targetUserId: targetUserId != null ? int.tryParse(targetUserId) : null,
            );
          },
        ),
      ],
    );
  }
}
