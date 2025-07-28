import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../../core/models/shop_item.dart';
import '../../../core/services/shop_api_service.dart';
import '../../../core/services/couple_api_service.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/dialog_utils.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/points_chip.dart';

class PartnerShopScreen extends StatefulWidget {
  const PartnerShopScreen({super.key});

  @override
  State<PartnerShopScreen> createState() => _PartnerShopScreenState();
}

class _PartnerShopScreenState extends State<PartnerShopScreen> {
  List<ShopItem> _items = [];
  bool _isLoading = true;
  String? _partnerName;

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
    });

    try {
      // 获取情侣信息
      final coupleResponse = await CoupleApiService.getCouple();
      final partner = coupleResponse['couple']?['partner'];
      
      if (partner != null) {
        _partnerName = partner['username'];
        
        // 获取对方的商品
        final response = await ShopApiService.getItems(ownerId: partner['id']);
        final itemsData = response['items'] as List<dynamic>? ?? [];

        setState(() {
          _items = itemsData.map((item) => ShopItem.fromJson(item)).toList();
        });
      } else {
        if (mounted) {
          SnackbarUtils.showError(context, '请先建立情侣关系');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, '加载商品失败: ${_getErrorMessage(e)}');
      }
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

  Future<void> _buyItem(ShopItem item) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentPoints = userProvider.user?.points ?? 0;

    if (currentPoints < item.price) {
      SnackbarUtils.showError(context, '积分不足，需要 ${item.price} 积分');
      return;
    }

    final confirmed = await DialogUtils.showConfirmDialog(
      context,
      title: '确认购买',
      content: '确定要花费 ${item.price} 积分购买 "${item.name}" 吗？\n\n当前积分：$currentPoints',
      confirmText: '购买',
      confirmColor: AppColors.tertiary,
    );

    if (confirmed != true) return;

    try {
      await ShopApiService.buyItem(item.id);

      if (mounted) {
        SnackbarUtils.showSuccess(context, '购买成功！享受你的服务吧 💕');
        // 更新用户积分
        userProvider.updateUserPoints(currentPoints - item.price);
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, '购买失败: ${_getErrorMessage(e)}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shopping_cart, color: Colors.white),
            const SizedBox(width: 8),
            Text(_partnerName != null ? '${_partnerName}的小卖部' : '对方的小卖部'),
          ],
        ),
        backgroundColor: AppColors.tertiary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.tertiary.withOpacity(0.1),
              AppColors.background,
            ],
          ),
        ),
        child: _isLoading
            ? const LoadingWidget(message: '加载中...')
            : _items.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.shopping_cart_outlined,
                    title: '还没有商品',
                    subtitle: _partnerName != null 
                        ? '$_partnerName 还没有添加商品哦~'
                        : '对方还没有添加商品哦~',
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return _buildPartnerItemCard(item);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildPartnerItemCard(ShopItem item) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentPoints = userProvider.user?.points ?? 0;
    final canAfford = currentPoints >= item.price;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.tertiary.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      Icons.card_giftcard,
                      color: AppColors.tertiary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.tertiary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        PriceChip(price: item.price),
                      ],
                    ),
                  ),
                ],
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.tertiary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description,
                            size: 16,
                            color: AppColors.tertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '服务描述',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.tertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: AppColors.tertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'by ${item.username}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.tertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: canAfford ? () => _buyItem(item) : null,
                    icon: Icon(
                      canAfford ? Icons.shopping_cart : Icons.money_off,
                      size: 20,
                    ),
                    label: Text(canAfford ? '购买' : '积分不足'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAfford ? AppColors.tertiary : Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ],
              ),
              if (!canAfford) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '还需要 ${item.price - currentPoints} 积分',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
