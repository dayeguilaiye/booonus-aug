import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/shop_api_service.dart';
import '../../../core/services/couple_api_service.dart';
import '../../../core/services/rules_api_service.dart';
import '../../../core/models/couple.dart';
import '../../../core/models/rule.dart';
import '../../../core/models/shop_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../core/utils/download_utils.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/export_page_widget.dart';
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
  final ScreenshotController _screenshotController = ScreenshotController();

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
            icon: Icons.download,
            iconColor: AppColors.accent, // 薄荷绿
            title: '导出为图片',
            subtitle: '生成约定和商品的图片版本',
            onTap: _couple != null ? _exportToImage : null,
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

  // 检查并请求权限
  Future<bool> _checkAndRequestPermissions() async {
    // Web平台下载不需要权限，直接返回true
    if (PlatformUtils.isWeb) {
      return true;
    }

    if (!PlatformUtils.isAndroid && !PlatformUtils.isIOS) {
      return false; // 只支持Android和iOS平台
    }

    if (PlatformUtils.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = deviceInfo.version.sdkInt;

      // Android SDK 29及以上版本不需要读权限来写入文件
      return sdkInt >= 29 ? true : await Permission.storage.request().isGranted;
    } else if (PlatformUtils.isIOS) {
      // iOS权限处理 - 尝试多种权限类型
      try {
        print('Debug: Starting iOS permission check...');

        // 尝试不同的权限类型
        List<Permission> permissionsToTry = [
          Permission.photosAddOnly,  // iOS 14+ 添加照片权限
          Permission.photos,         // 完整相册权限
        ];

        for (int i = 0; i < permissionsToTry.length; i++) {
          final permission = permissionsToTry[i];
          final permissionName = permission == Permission.photosAddOnly ? 'photosAddOnly' : 'photos';

          print('Debug: Trying permission: $permissionName');

          try {
            // 检查权限状态
            final status = await permission.status;
            print('Debug: $permissionName status = $status');

            if (status.isGranted) {
              print('Debug: $permissionName already granted');
              return true;
            }

            // 请求权限
            print('Debug: Requesting $permissionName permission...');
            final result = await permission.request();
            print('Debug: $permissionName request result = $result');

            if (result.isGranted) {
              print('Debug: $permissionName granted!');
              return true;
            } else if (result.isPermanentlyDenied) {
              print('Debug: $permissionName permanently denied');
              if (i == permissionsToTry.length - 1) {
                // 最后一个权限也被永久拒绝
                _showPermissionDeniedDialog();
                return false;
              }
              // 尝试下一个权限
              continue;
            } else {
              print('Debug: $permissionName denied, trying next...');
              if (i == permissionsToTry.length - 1) {
                // 最后一个权限也被拒绝
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('需要相册权限才能保存图片'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
                return false;
              }
              // 尝试下一个权限
              continue;
            }
          } catch (e) {
            print('Debug: Error with $permissionName: $e');
            if (i == permissionsToTry.length - 1) {
              // 最后一个权限也出错了
              throw e;
            }
            // 尝试下一个权限
            continue;
          }
        }

        return false;
      } catch (e) {
        print('Debug: All permission requests failed: $e');
        print('Debug: Error type: ${e.runtimeType}');

        // 显示错误信息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('权限请求失败，请检查应用权限设置: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return false;
      }
    }

    return false; // 不支持的平台
  }

  // 显示权限被拒绝的对话框
  void _showPermissionDeniedDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要相册权限'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('保存图片需要访问相册权限。'),
            SizedBox(height: 12),
            Text('请按以下步骤开启权限：', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('1. 点击"去设置"按钮'),
            Text('2. 找到"照片"或"相册"选项'),
            Text('3. 选择"所有照片"或"添加照片"'),
            SizedBox(height: 8),
            Text('如果设置中没有相册选项，请删除应用重新安装。',
                 style: TextStyle(color: Colors.orange, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings(); // 打开应用设置页面
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  // 导出为图片
  Future<void>  _exportToImage() async {
    try {
      // 检查权限
      final hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('需要相册权限才能保存图片'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // 显示加载提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('正在生成图片...'),
            backgroundColor: AppColors.primary,
          ),
        );
      }

      // 获取当前用户信息
      if (!mounted) return;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.user;

      if (currentUser == null || _couple == null) {
        throw Exception('用户信息或情侣信息不完整');
      }

      // 获取规则和商品数据
      final rulesResponse = await RulesApiService.getRules();
      final rulesData = rulesResponse['rules'] as List<dynamic>? ?? [];
      final rules = rulesData.map((rule) => Rule.fromJson(rule)).toList();

      // 获取当前用户的商品
      final currentUserShopsResponse = await ShopApiService.getItems(ownerId: currentUser.id);
      final currentUserShopsData = currentUserShopsResponse['items'] as List<dynamic>? ?? [];
      final currentUserShops = currentUserShopsData.map((item) => ShopItem.fromJson(item)).toList();

      // 获取伴侣的商品
      final partnerShopsResponse = await ShopApiService.getItems(ownerId: _couple!.partner.id);
      final partnerShopsData = partnerShopsResponse['items'] as List<dynamic>? ?? [];
      final partnerShops = partnerShopsData.map((item) => ShopItem.fromJson(item)).toList();

      // 创建导出页面组件
      final exportWidget = ExportPageWidget(
        rules: rules,
        currentUserShops: currentUserShops,
        partnerShops: partnerShops,
        currentUser: currentUser,
        couple: _couple,
      );

      // 截图
      final Uint8List imageBytes = await _screenshotController.captureFromWidget(
        exportWidget,
        pixelRatio: 2.0, // 高分辨率
      );

      if (imageBytes.isNotEmpty) {
        // 下载图片
        _downloadImage(imageBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('图片已生成并下载！'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        throw Exception('图片生成失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // 下载图片
  Future<void> _downloadImage(Uint8List imageBytes) async {
    try {
      final String fileName = '小小卖部_${DateTime.now().millisecondsSinceEpoch}.png';

      await DownloadUtils.downloadImage(
        imageBytes,
        fileName,
        androidRelativePath: 'Pictures/小小卖部',
      );

      if (mounted) {
        final message = PlatformUtils.isWeb
            ? '图片已下载！'
            : '图片已保存到相册！';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = PlatformUtils.isWeb
            ? '下载图片失败: ${e.toString()}'
            : '保存图片失败: ${e.toString()}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
