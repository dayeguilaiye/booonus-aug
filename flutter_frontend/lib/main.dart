import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/auth_provider.dart';

import 'core/services/storage_service.dart';
import 'core/services/preload_manager.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/widgets/main_navigation.dart';
import 'widgets/deferred_loader.dart';

// 延迟导入非首屏必需的组件
import 'deferred/shop_deferred.dart' deferred as shop_deferred;
import 'deferred/profile_deferred.dart' deferred as profile_deferred;
import 'deferred/rules_deferred.dart' deferred as rules_deferred;
import 'deferred/settings_deferred.dart' deferred as settings_deferred;

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

        // 如果用户未登录且不在登录/注册页面，重定向到登录页
        if (!isLoggedIn && !isLoggingIn) {
          return '/login';
        }

        // 如果用户已登录且在登录/注册页面，重定向到首页
        if (isLoggedIn && isLoggingIn) {
          // 用户登录成功后，开始预加载组件
          PreloadManager().preloadAllComponents();
          return '/home';
        }

        // 智能预加载：根据当前路由预测用户行为
        if (isLoggedIn) {
          PreloadManager().smartPreload(
            currentRoute: state.matchedLocation,
            isLoggedIn: isLoggedIn,
          );
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
              builder: (context, state) => DeferredLoader(
                loadLibrary: shop_deferred.loadLibrary,
                builder: () => shop_deferred.ShopScreen(),
                componentName: '商店',
              ),
            ),
            GoRoute(
              path: '/rules',
              builder: (context, state) => DeferredLoader(
                loadLibrary: rules_deferred.loadLibrary,
                builder: () => rules_deferred.RulesScreen(),
                componentName: '规则',
              ),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => DeferredLoader(
                loadLibrary: profile_deferred.loadLibrary,
                builder: () => profile_deferred.ProfileScreen(),
                componentName: '个人资料',
              ),
            ),
          ],
        ),
        
        // Settings route (outside main navigation)
        GoRoute(
          path: '/settings',
          builder: (context, state) => DeferredLoader(
            loadLibrary: settings_deferred.loadLibrary,
            builder: () => settings_deferred.SettingsScreen(),
            componentName: '设置',
          ),
        ),

        // My Shop route (outside main navigation)
        GoRoute(
          path: '/my-shop',
          builder: (context, state) => DeferredLoader(
            loadLibrary: shop_deferred.loadLibrary,
            builder: () => shop_deferred.MyShopScreen(),
            componentName: '我的小卖部',
          ),
        ),

        // Points History routes (outside main navigation)
        GoRoute(
          path: '/points-history/my',
          builder: (context, state) => DeferredLoader(
            loadLibrary: profile_deferred.loadLibrary,
            builder: () => profile_deferred.PointsHistoryScreen(
              isMyHistory: true,
            ),
            componentName: '积分记录',
          ),
        ),
        GoRoute(
          path: '/points-history/partner',
          builder: (context, state) {
            final targetUserId = state.uri.queryParameters['targetUserId'];
            return DeferredLoader(
              loadLibrary: profile_deferred.loadLibrary,
              builder: () => profile_deferred.PointsHistoryScreen(
                isMyHistory: false,
                targetUserId: targetUserId != null ? int.tryParse(targetUserId) : null,
              ),
              componentName: '积分记录',
            );
          },
        ),
      ],
    );
  }
}
