import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/user_provider.dart';
import '../../../core/services/couple_api_service.dart';
import '../../../core/services/shop_api_service.dart';
import '../../../core/models/couple.dart';
import '../../../core/services/events_api_service.dart';
import '../../../core/utils/event_bus.dart';
import '../../../core/utils/undoable_snackbar_utils.dart';
import '../../widgets/points_cards_widget.dart';
import '../../../core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Couple? _couple;
  bool _isLoading = true;
  String? _error;
  int _myItemCount = 0;
  int _partnerItemCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });

    // 监听情侣关系更新事件
    eventBus.on(Events.coupleUpdated, _onCoupleUpdated);
  }

  @override
  void dispose() {
    // 移除事件监听
    eventBus.off(Events.coupleUpdated, _onCoupleUpdated);
    super.dispose();
  }

  // 处理情侣关系更新事件
  void _onCoupleUpdated() {
    if (mounted) {
      _loadData(); // 重新加载所有数据
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load user profile
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUserProfile();
      final user = userProvider.user;

      // Load couple info
      Couple? couple;
      try {
        final coupleResponse = await CoupleApiService.getCouple();
        if (coupleResponse['couple'] != null) {
          couple = Couple.fromJson(coupleResponse['couple']);
        }
      } catch (e) {
        if (!e.toString().contains('暂无情侣关系')) {
          print('Unexpected error loading couple info: $e');
        }
      }

      // Load my shop items count
      int myItemCount = 0;
      if (user != null) {
        try {
          final myItemsResponse = await ShopApiService.getItems(ownerId: user.id);
          final myItems = myItemsResponse['items'] as List<dynamic>? ?? [];
          myItemCount = myItems.length;
        } catch (e) {
          print('Error loading my items: $e');
        }
      }

      // Load partner's shop items count
      int partnerItemCount = 0;
      if (couple != null) {
        try {
          final partnerItemsResponse = await ShopApiService.getItems(ownerId: couple.partner.id);
          final partnerItems = partnerItemsResponse['items'] as List<dynamic>? ?? [];
          partnerItemCount = partnerItems.length;
        } catch (e) {
          print('Error loading partner items: $e');
        }
      }

      setState(() {
        _couple = couple;
        _myItemCount = myItemCount;
        _partnerItemCount = partnerItemCount;
      });
    } catch (e) {
      setState(() {
        _error = '加载数据失败：${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // 温暖的白色背景
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitle(),
                        const SizedBox(height: 24),
                        _buildPointsCards(),
                        const SizedBox(height: 32),
                        _buildShopsSection(),
                        const SizedBox(height: 32),
                        _buildQuickActions(),
                      ],
                    ),
                  ),
                ),
    );
  }

  // 构建标题
  Widget _buildTitle() {
    return const Center(
      child: Text(
        '小小卖部',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.onBackground, // 深棕色
        ),
      ),
    );
  }

  // 构建积分卡片
  Widget _buildPointsCards() {
    return PointsCardsWidget(couple: _couple);
  }



  // 构建小卖部部分
  Widget _buildShopsSection() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        if (user == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '我们的小卖部',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.onBackground, // 深棕色
              ),
            ),
            const SizedBox(height: 16),
            _buildShopCard(
              '${user.username}的小卖部',
              '${user.username}的小卖部',
              '$_myItemCount 件商品',
              '管理',
              AppColors.primaryContainer, // 非常浅的桃色
              AppColors.primary, // 温暖桃粉色
              () => context.push('/my-shop'),
            ),
            const SizedBox(height: 12),
            _couple != null
                ? _buildShopCard(
                    '${_couple!.partner.username}的小卖部',
                    '${_couple!.partner.username}的小卖部',
                    '$_partnerItemCount 件商品',
                    '逛逛',
                    AppColors.accentContainer, // 浅薄荷绿
                    AppColors.accent, // 薄荷绿
                    () => context.go('/shop'),
                  )
                : _buildEmptyShopCard(),
          ],
        );
      },
    );
  }

  // 构建小卖部卡片
  Widget _buildShopCard(String title, String subtitle, String itemCount, String buttonText, Color bgColor, Color iconColor, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.store,
              color: iconColor,
              size: 24,
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
                    fontWeight: FontWeight.bold,
                    color: AppColors.onBackground, // 深棕色
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.onBackground, // 深棕色
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  itemCount,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建空的小卖部卡片
  Widget _buildEmptyShopCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.disabled,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.disabledContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.store_outlined,
              color: AppColors.onDisabled,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '等待情侣的小卖部',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onDisabled,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '邀请情侣后可查看',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.onDisabled,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '-- 件商品',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onDisabled,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.disabledContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '等待',
              style: TextStyle(
                color: AppColors.onDisabled,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建快捷操作
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快捷操作',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.onBackground, // 深棕色
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                '创建约定',
                Icons.add,
                AppColors.primaryContainer, // 非常浅的桃色
                AppColors.primary, // 温暖桃粉色
                () => context.go('/rules'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                '特殊事件',
                Icons.card_giftcard,
                AppColors.accentContainer, // 浅薄荷绿
                AppColors.accent, // 薄荷绿
                () => _showCreateEventDialog(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 构建快捷操作按钮
  Widget _buildQuickActionButton(String title, IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.onBackground, // 深棕色
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 显示创建事件对话框
  Future<void> _showCreateEventDialog() async {
    if (_couple == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('需要先添加情侣才能使用事件功能'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    if (currentUser == null) return;

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final pointsController = TextEditingController();
    int targetId = currentUser.id;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('创建特殊事件'),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: '事件名称',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.event),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: '事件描述',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pointsController,
                    decoration: InputDecoration(
                      labelText: '积分变化（正数为奖励，负数为惩罚）',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.diamond),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '目标对象:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 紧凑的单选按钮布局
                  Column(
                    children: [
                      RadioListTile<int>(
                        title: const Text('对我'),
                        value: currentUser.id,
                        groupValue: targetId,
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onChanged: (value) {
                          setDialogState(() {
                            targetId = value!;
                          });
                        },
                      ),
                      RadioListTile<int>(
                        title: Text('对${_couple!.partner.username}'),
                        value: _couple!.partner.id,
                        groupValue: targetId,
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onChanged: (value) {
                          setDialogState(() {
                            targetId = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                '取消',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _createEvent(
        targetId,
        nameController.text.trim(),
        descriptionController.text.trim(),
        pointsController.text.trim(),
      );
    }
  }

  // 创建事件
  Future<void> _createEvent(int targetId, String name, String description, String pointsStr) async {
    if (name.isEmpty || pointsStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请填写事件名称和积分'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final points = int.tryParse(pointsStr);
    if (points == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请输入有效的积分值'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      await EventsApiService.createEvent(
        targetId: targetId,
        name: name,
        description: description,
        points: points,
      );

      if (mounted) {
        // 获取用户提供者引用（在异步操作前）
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        // 显示带撤销功能的成功提醒
        await UndoableSnackbarUtils.showUndoableSuccess(
          context,
          '事件创建成功！',
          targetUserId: targetId,
          onRefresh: () {
            // 刷新数据
            _loadData();
            // 如果目标是当前用户，重新加载用户信息以更新积分显示
            if (targetId == userProvider.user?.id) {
              userProvider.loadUserProfile();
            }
          },
        );

        // 如果目标是当前用户，更新积分显示
        if (mounted && targetId == userProvider.user?.id) {
          userProvider.updateUserPoints((userProvider.user?.points ?? 0) + points);
        }

        // 重新加载数据以更新显示
        if (mounted) {
          _loadData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建事件失败: ${_getErrorMessage(e)}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // 获取错误信息
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('需要先添加情侣')) {
      return '需要先添加情侣才能使用事件功能';
    }
    if (error.toString().contains('只能为自己或情侣创建事件')) {
      return '只能为自己或情侣创建事件';
    }
    return error.toString().replaceAll('Exception: ', '');
  }

}
