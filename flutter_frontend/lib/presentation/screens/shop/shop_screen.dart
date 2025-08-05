import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../../core/models/shop_item.dart';
import '../../../core/models/couple.dart';
import '../../../core/services/shop_api_service.dart';
import '../../../core/services/couple_api_service.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/points_cards_widget.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  List<ShopItem> _partnerItems = [];
  bool _isLoading = true;
  Couple? _couple;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
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

      // Load couple info
      try {
        final coupleResponse = await CoupleApiService.getCouple();
        if (coupleResponse['couple'] != null) {
          _couple = Couple.fromJson(coupleResponse['couple']);

          // 获取对方的商品
          final partnerResponse = await ShopApiService.getItems(ownerId: _couple!.partner.id);
          final partnerItemsData = partnerResponse['items'] as List<dynamic>? ?? [];
          _partnerItems = partnerItemsData.map((item) => ShopItem.fromJson(item)).toList();
        } else {
          _couple = null;
          _partnerItems = [];
        }
      } catch (e) {
        if (e.toString().contains('暂无情侣关系')) {
          _couple = null;
          _partnerItems = [];
        } else {
          print('Unexpected error loading couple info: $e');
        }
      }
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

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      return error.response?.data?['error'] ?? error.message ?? '网络错误';
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // 与home_screen相同的温暖白色背景
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
                        _buildShopSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  // 构建标题
  Widget _buildTitle() {
    return Center(
      child: Text(
        _couple != null ? '${_couple!.partner.username}的小卖部' : '对方的小卖部',
        style: const TextStyle(
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



  // 构建商品部分
  Widget _buildShopSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '所有商品',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.onBackground, // 深棕色
          ),
        ),
        const SizedBox(height: 16),
        _partnerItems.isEmpty
            ? _buildEmptyShopState()
            : Column(
                children: _partnerItems.map((item) => _buildItemCard(item)).toList(),
              ),
      ],
    );
  }

  // 构建空商品状态
  Widget _buildEmptyShopState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '还没有商品',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _couple != null
                ? '${_couple!.partner.username} 还没有添加商品哦~'
                : '对方还没有添加商品哦~',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(ShopItem item) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentPoints = userProvider.user?.points ?? 0;
    final canAfford = currentPoints >= item.price;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.gentleShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主要内容：两列布局
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左列：商品名称和描述
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (item.description.isNotEmpty)
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // 右列：积分和购买按钮
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 积分显示
                    Text(
                      '${item.price}积分',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 购买按钮
                    ElevatedButton(
                      onPressed: canAfford ? () => _buyItem(item) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canAfford ? AppColors.primary : AppColors.onSurfaceVariant,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      ),
                      child: Text(
                        canAfford ? '购买' : '积分不足',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (!canAfford) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningWithOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warningWithOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '还需要 ${item.price - currentPoints} 积分',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }



  // 购买商品
  Future<void> _buyItem(ShopItem item) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentPoints = userProvider.user?.points ?? 0;

    if (currentPoints < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('积分不足，需要 ${item.price} 积分'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认购买'),
        content: Text('确定要花费 ${item.price} 积分购买 "${item.name}" 吗？\n\n当前积分：$currentPoints'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
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
            child: const Text('购买'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ShopApiService.buyItem(item.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('购买成功！享受你的服务吧 💕'),
            backgroundColor: AppColors.success,
          ),
        );
        // 更新用户积分
        userProvider.updateUserPoints(currentPoints - item.price);
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('购买失败: ${_getErrorMessage(e)}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
