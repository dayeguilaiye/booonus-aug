import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/user_provider.dart';
import '../../../core/services/couple_api_service.dart';
import '../../../core/services/points_api_service.dart';
import '../../../core/models/couple.dart';
import '../../../core/models/points_history.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/invite_couple_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Couple? _couple;
  List<PointsHistory> _recentHistory = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 延迟到下一帧执行，避免在build过程中调用setState
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
        print('Couple API Response: $coupleResponse'); // 调试信息

        if (coupleResponse['couple'] != null) {
          print('Parsing couple data: ${coupleResponse['couple']}'); // 调试信息
          _couple = Couple.fromJson(coupleResponse['couple']);
          print('Successfully parsed couple: ${_couple?.partner.username}'); // 调试信息
        } else {
          print('No couple data in response'); // 调试信息
          _couple = null;
        }
      } catch (e, stackTrace) {
        // 打印详细错误信息用于调试
        print('Failed to load couple info: $e');
        print('Stack trace: $stackTrace');

        // 如果是404错误（没有情侣关系），这是正常的
        if (e.toString().contains('暂无情侣关系')) {
          print('No couple relationship found (404)');
          _couple = null;
        } else {
          // 其他错误，可能是网络问题等，保持当前状态不变
          print('Unexpected error loading couple info: $e');
        }
      }

      // Load recent history
      try {
        final historyResponse = await PointsApiService.getHistory(limit: 5);
        if (historyResponse['history'] != null) {
          _recentHistory = (historyResponse['history'] as List)
              .map((item) => PointsHistory.fromJson(item))
              .toList();
        }
      } catch (e) {
        print('Failed to load history: $e');
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

  Future<void> _showInviteDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const InviteCoupleDialog(),
    );

    if (result != null && result.isNotEmpty) {
      await _inviteCouple(result);
    }
  }

  Future<void> _inviteCouple(String username) async {
    try {
      await CoupleApiService.invite(username);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('邀请发送成功！'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadData(); // Reload data
      }
    } catch (e) {
      if (mounted) {
        // 提取错误信息，去掉"Exception: "前缀
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MM-dd HH:mm').format(date);
  }

  Color _getPointsColor(int points) {
    if (points > 0) return AppColors.success;
    if (points < 0) return AppColors.error;
    return AppColors.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: AppTextStyles.error),
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUserCard(),
                        const SizedBox(height: 16),
                        _buildCoupleCard(),
                        const SizedBox(height: 16),
                        if (_recentHistory.isNotEmpty) _buildRecentActivity(),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: _couple != null
          ? FloatingActionButton(
              onPressed: () {
                // Show quick actions menu
                showModalBottomSheet(
                  context: context,
                  builder: (context) => _buildQuickActionsSheet(),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildUserCard() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        if (user == null) return const SizedBox.shrink();

        return Card(
          color: AppColors.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary,
                  child: const Icon(
                    Icons.person,
                    size: 30,
                    color: AppColors.onPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: AppTextStyles.username,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.diamond,
                            size: 20,
                            color: AppColors.coin,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${user.points} 积分',
                            style: AppTextStyles.points,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoupleCard() {
    if (_couple != null) {
      return Card(
        color: AppColors.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.favorite,
                    color: AppColors.heart,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '我的情侣',
                    style: AppTextStyles.coupleTitle,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.secondary,
                    child: const Icon(
                      Icons.favorite,
                      color: AppColors.onSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _couple!.partner.username,
                          style: AppTextStyles.partnerName,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.diamond,
                              size: 16,
                              color: AppColors.coin,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_couple!.partner.points} 积分',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        color: AppColors.surfaceVariant,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                Icons.favorite_border,
                size: 48,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              const Text(
                '还没有情侣',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 4),
              const Text(
                '邀请你的另一半加入吧！',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showInviteDialog,
                icon: const Icon(Icons.favorite_border),
                label: const Text('邀请情侣'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '最近活动',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 12),
            ...(_recentHistory.map((item) => _buildHistoryItem(item))),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(PointsHistory item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: AppTextStyles.historyDescription,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(item.createdAt),
                  style: AppTextStyles.historyDate,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPointsColor(item.points).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${item.points > 0 ? '+' : ''}${item.points}',
              style: TextStyle(
                color: _getPointsColor(item.points),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '快速操作',
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('创建事件'),
            onTap: () {
              Navigator.pop(context);
              context.go('/events');
            },
          ),
          ListTile(
            leading: const Icon(Icons.rule),
            title: const Text('执行规则'),
            onTap: () {
              Navigator.pop(context);
              context.go('/rules');
            },
          ),
          ListTile(
            leading: const Icon(Icons.store),
            title: const Text('购买商品'),
            onTap: () {
              Navigator.pop(context);
              context.go('/shop');
            },
          ),
        ],
      ),
    );
  }
}
