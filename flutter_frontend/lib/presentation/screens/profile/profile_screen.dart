import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/shop_api_service.dart';
import '../../../core/services/couple_api_service.dart';
import '../../../core/models/couple.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/user_avatar.dart';
import 'avatar_selection_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _itemCount = 0;
  bool _isLoading = true;
  Couple? _couple;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 导航到头像选择页面
  void _navigateToAvatarSelection() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AvatarSelectionScreen(),
      ),
    );
  }

  // 导航到积分记录页面
  void _navigateToPointsHistory(bool isMyHistory) {
    if (isMyHistory) {
      context.push('/points-history/my');
    } else {
      final targetUserId = _couple?.partner.id;
      if (targetUserId != null) {
        context.push('/points-history/partner?targetUserId=$targetUserId');
      }
    }
  }

  Future<void> _loadData() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      if (user != null) {
        // 加载商品数量
        final itemsResponse = await ShopApiService.getItems(ownerId: user.id);
        final items = itemsResponse['items'] as List<dynamic>? ?? [];

        // 加载情侣信息
        Couple? couple;
        try {
          final coupleResponse = await CoupleApiService.getCouple();
          if (coupleResponse['couple'] != null) {
            couple = Couple.fromJson(coupleResponse['couple']);
          }
        } catch (e) {
          // 如果没有情侣关系，couple保持为null
          if (!e.toString().contains('暂无情侣关系')) {
            print('Unexpected error loading couple info: $e');
          }
        }

        setState(() {
          _itemCount = items.length;
          _couple = couple;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _itemCount = 0;
        _couple = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // 与home_screen相同的温暖白色背景
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.user;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 用户信息卡片
                _buildUserInfoCard(user),

                const SizedBox(height: 32),

                // 功能设置区域
                _buildFunctionSettings(),

                const SizedBox(height: 32),

                // 退出登录按钮
                _buildLogoutButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  // 构建用户信息卡片
  Widget _buildUserInfoCard(user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer, // 非常浅的桃色，与home_screen一致
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // 左侧头像
          UserAvatar(
            avatar: user?.avatar,
            size: 60,
            borderColor: AppColors.primary,
            borderWidth: 3,
            showEditIcon: true,
            onTap: () => _navigateToAvatarSelection(),
          ),
          const SizedBox(width: 16),
          // 右侧信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.username ?? '未知用户',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onBackground, // 深棕色
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '总积分：${user?.points ?? 0}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primary, // 温暖桃粉色
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      '商品数量：${_isLoading ? '--' : _itemCount}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.onBackground, // 深棕色
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建功能设置区域
  Widget _buildFunctionSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '功能设置',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground, // 深棕色
            ),
          ),
          const SizedBox(height: 20),
          _buildSettingItem(
            icon: Icons.store,
            iconColor: AppColors.primary, // 温暖桃粉色
            title: '管理我的小卖部',
            subtitle: _isLoading ? '加载中...' : '$_itemCount个商品',
            onTap: () => context.push('/my-shop'),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.history,
            iconColor: AppColors.primary, // 温暖桃粉色
            title: '我的积分记录',
            subtitle: '查看我的积分变化历史',
            onTap: () => _navigateToPointsHistory(true),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.people,
            iconColor: AppColors.accent, // 薄荷绿
            title: '对方的积分记录',
            subtitle: _couple != null ? '查看${_couple!.partner.username}的积分变化历史' : '需要建立情侣关系',
            onTap: _couple != null ? () => _navigateToPointsHistory(false) : null,
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.notifications,
            iconColor: AppColors.primary, // 温暖桃粉色
            title: '通知设置',
            subtitle: '约定提醒、积分变动通知',
            onTap: () {
              // TODO: Navigate to notification settings
            },
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.security,
            iconColor: AppColors.primary, // 温暖桃粉色
            title: '隐私设置',
            subtitle: '账户安全、数据隐私',
            onTap: () {
              // TODO: Navigate to privacy settings
            },
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.palette,
            iconColor: AppColors.primary, // 温暖桃粉色
            title: '应用设置',
            subtitle: '主题、语言、其他偏好',
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }

  // 构建设置项
  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // 确保整个区域都可以点击
      child: Opacity(
        opacity: onTap != null ? 1.0 : 0.5, // 当不可点击时降低透明度
        child: Container(
          width: double.infinity, // 确保容器占满整个宽度
          padding: const EdgeInsets.symmetric(vertical: 8), // 增加垂直点击区域
          child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onBackground, // 深棕色
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant, // 稍浅的棕色
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.onSurfaceVariant, // 稍浅的棕色
            ),
          ],
        ),
      ),
      ),
    );
  }

  // 构建退出登录按钮
  Widget _buildLogoutButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: GestureDetector(
        onTap: () => _showLogoutDialog(context),
        behavior: HitTestBehavior.opaque, // 确保整个区域都可以点击
        child: Container(
          width: double.infinity, // 确保容器占满整个宽度
          padding: const EdgeInsets.symmetric(vertical: 8), // 增加垂直点击区域
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.logout,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  '退出登录',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onBackground, // 深棕色
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final userProvider = Provider.of<UserProvider>(context, listen: false);

              await authProvider.logout();
              userProvider.clear();

              if (context.mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}
