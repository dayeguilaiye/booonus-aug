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

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<ShopItem> _partnerItems = [];
  List<ShopItem> _myItems = [];
  bool _isLoading = true;
  String? _partnerName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      if (user != null) {
        // 获取情侣信息
        try {
          final coupleResponse = await CoupleApiService.getCouple();
          final partner = coupleResponse['couple']?['partner'];

          if (partner != null) {
            _partnerName = partner['username'];

            // 获取对方的商品
            final partnerResponse = await ShopApiService.getItems(ownerId: partner['id']);
            final partnerItemsData = partnerResponse['items'] as List<dynamic>? ?? [];
            _partnerItems = partnerItemsData.map((item) => ShopItem.fromJson(item)).toList();
          }
        } catch (e) {
          // 如果没有情侣关系，对方商品为空
          _partnerItems = [];
        }

        // 获取自己的商品
        final myResponse = await ShopApiService.getItems(ownerId: user.id);
        final myItemsData = myResponse['items'] as List<dynamic>? ?? [];
        _myItems = myItemsData.map((item) => ShopItem.fromJson(item)).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('小卖部'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.shopping_cart),
              text: _partnerName != null ? '${_partnerName}的小卖部' : '对方的小卖部',
            ),
            const Tab(
              icon: Icon(Icons.inventory_2),
              text: '我的小卖部',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingWidget(message: '加载中...')
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPartnerShop(),
                _buildMyShop(),
              ],
            ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          // 只在"我的小卖部"标签页显示浮动按钮
          return _tabController.index == 1
              ? FloatingActionButton(
                  onPressed: _showCreateItemDialog,
                  backgroundColor: AppColors.secondary,
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : const SizedBox.shrink();
        },
      ),
    );
  }

  // 构建对方的小卖部界面
  Widget _buildPartnerShop() {
    return Container(
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
      child: _partnerItems.isEmpty
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
                itemCount: _partnerItems.length,
                itemBuilder: (context, index) {
                  final item = _partnerItems[index];
                  return _buildPartnerItemCard(item);
                },
              ),
            ),
    );
  }

  // 构建我的小卖部界面
  Widget _buildMyShop() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.secondary.withOpacity(0.1),
            AppColors.background,
          ],
        ),
      ),
      child: _myItems.isEmpty
          ? EmptyStateWidget(
              icon: Icons.inventory_2_outlined,
              title: '还没有商品',
              subtitle: '添加一些服务商品吧！',
              action: ElevatedButton.icon(
                onPressed: _showCreateItemDialog,
                icon: const Icon(Icons.add),
                label: const Text('添加商品'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _myItems.length,
                itemBuilder: (context, index) {
                  final item = _myItems[index];
                  return _buildMyItemCard(item);
                },
              ),
            ),
    );
  }

  // 购买商品
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

  // 显示创建商品对话框
  Future<void> _showCreateItemDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.add_shopping_cart, color: AppColors.secondary),
            const SizedBox(width: 8),
            const Text('添加商品'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '商品名称',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.shopping_bag),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: '商品描述',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: '价格（积分）',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.diamond),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
            ),
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _createItem(
        nameController.text.trim(),
        descriptionController.text.trim(),
        priceController.text.trim(),
      );
    }
  }

  // 创建商品
  Future<void> _createItem(String name, String description, String priceStr) async {
    if (name.isEmpty || priceStr.isEmpty) {
      SnackbarUtils.showError(context, '请填写商品名称和价格');
      return;
    }

    final price = int.tryParse(priceStr);
    if (price == null || price <= 0) {
      SnackbarUtils.showError(context, '请输入有效的价格');
      return;
    }

    try {
      await ShopApiService.createItem(
        name: name,
        description: description,
        price: price,
      );

      if (mounted) {
        SnackbarUtils.showSuccess(context, '商品创建成功！');
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, '创建商品失败: ${_getErrorMessage(e)}');
      }
    }
  }

  // 删除商品
  Future<void> _deleteItem(ShopItem item) async {
    final confirmed = await DialogUtils.showConfirmDialog(
      context,
      title: '确认删除',
      content: '确定要删除商品 "${item.name}" 吗？此操作不可撤销。',
      confirmText: '删除',
      confirmColor: Colors.red,
    );

    if (confirmed != true) return;

    try {
      await ShopApiService.deleteItem(item.id);

      if (mounted) {
        SnackbarUtils.showSuccess(context, '商品删除成功！');
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, '删除商品失败: ${_getErrorMessage(e)}');
      }
    }
  }

  // 构建对方商品卡片
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
                                Icons.diamond,
                                size: 16,
                                color: AppColors.tertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.price}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.tertiary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
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

  // 构建我的商品卡片
  Widget _buildMyItemCard(ShopItem item) {
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
              AppColors.secondary.withOpacity(0.05),
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
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      Icons.shopping_bag,
                      color: AppColors.secondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.diamond,
                                size: 16,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.price}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditItemDialog(item);
                      } else if (value == 'delete') {
                        _deleteItem(item);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('编辑'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.more_vert,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.secondary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    item.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '创建于 ${_formatDate(item.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.store,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '我的商品',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 显示编辑商品对话框
  Future<void> _showEditItemDialog(ShopItem item) async {
    final nameController = TextEditingController(text: item.name);
    final descriptionController = TextEditingController(text: item.description);
    final priceController = TextEditingController(text: item.price.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: AppColors.secondary),
            const SizedBox(width: 8),
            const Text('编辑商品'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '商品名称',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.shopping_bag),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: '商品描述',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: '价格（积分）',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.diamond),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _updateItem(
        item.id,
        nameController.text.trim(),
        descriptionController.text.trim(),
        priceController.text.trim(),
      );
    }
  }

  // 更新商品
  Future<void> _updateItem(int itemId, String name, String description, String priceStr) async {
    if (name.isEmpty || priceStr.isEmpty) {
      SnackbarUtils.showError(context, '请填写商品名称和价格');
      return;
    }

    final price = int.tryParse(priceStr);
    if (price == null || price <= 0) {
      SnackbarUtils.showError(context, '请输入有效的价格');
      return;
    }

    try {
      await ShopApiService.updateItem(itemId, {
        'name': name,
        'description': description,
        'price': price,
      });

      if (mounted) {
        SnackbarUtils.showSuccess(context, '商品更新成功！');
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, '更新商品失败: ${_getErrorMessage(e)}');
      }
    }
  }

  // 格式化日期
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
