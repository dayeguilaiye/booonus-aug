import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/rule.dart';
import '../../../core/models/couple.dart';
import '../../../core/services/rules_api_service.dart';
import '../../../core/services/couple_api_service.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/event_bus.dart';
import '../../../core/utils/undoable_snackbar_utils.dart';
import '../../../core/utils/error_message_utils.dart';

import '../../widgets/points_cards_widget.dart';
import '../../widgets/rule_split_button.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  List<Rule> _rules = [];
  List<Rule> _filteredRules = [];
  bool _isLoading = true;
  Couple? _couple;
  String? _error;

  // 排序和筛选状态
  String _sortOrder = 'time_desc'; // time_asc, time_desc, points_asc, points_desc
  String _filterType = 'all'; // all, current_user, partner, both

  @override
  void initState() {
    super.initState();
    // 延迟到下一帧执行，避免在build过程中调用ScaffoldMessenger
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRules();
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
      _loadRules(); // 重新加载规则数据
    }
  }

  Future<void> _loadRules() async {
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
        } else {
          _couple = null;
        }
      } catch (e) {
        if (e.toString().contains('暂无情侣关系')) {
          _couple = null;
        } else {
          print('Unexpected error loading couple info: $e');
        }
      }

      // Load rules
      try {
        final response = await RulesApiService.getRules();
        final rulesData = response['rules'] as List<dynamic>? ?? [];
        _rules = rulesData.map((rule) => Rule.fromJson(rule)).toList();
      } catch (e) {
        // 如果是没有情侣关系的错误，不设置错误状态，而是显示空状态
        if (e.toString().contains('需要先添加情侣才能使用规则功能')) {
          _rules = [];
        } else {
          setState(() {
            _error = _getErrorMessage(e);
          });
          return;
        }
      }
    } catch (e) {
      setState(() {
        _error = _getErrorMessage(e);
      });
    } finally {
      setState(() {
        _isLoading = false;
        _applyFilterAndSort();
      });
    }
  }

  // 应用筛选和排序
  void _applyFilterAndSort() {
    List<Rule> filtered = List.from(_rules);

    // 应用筛选
    if (_filterType != 'all') {
      filtered = filtered.where((rule) {
        switch (_filterType) {
          case 'current_user':
            // 筛选对我生效的约定：包括只对我生效的和对双方生效的
            return rule.targetType == 'current_user' || rule.targetType == 'both';
          case 'partner':
            // 筛选对对方生效的约定：包括只对对方生效的和对双方生效的
            return rule.targetType == 'partner' || rule.targetType == 'both';
          case 'both':
            // 筛选只对双方生效的约定
            return rule.targetType == 'both';
          default:
            return true;
        }
      }).toList();
    }

    // 应用排序，置顶的约定始终在最前面
    filtered.sort((a, b) {
      // 首先按置顶状态排序，置顶的在前
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      // 如果都是置顶的，按置顶时间降序排列（最近置顶的在前）
      if (a.isPinned && b.isPinned) {
        if (a.pinnedAt != null && b.pinnedAt != null) {
          return b.pinnedAt!.compareTo(a.pinnedAt!);
        }
        // 如果置顶时间为空，按创建时间排序
        return b.createdAt.compareTo(a.createdAt);
      }

      // 如果都不是置顶的，按用户选择的排序方式排序
      switch (_sortOrder) {
        case 'time_asc':
          return a.createdAt.compareTo(b.createdAt);
        case 'time_desc':
          return b.createdAt.compareTo(a.createdAt);
        case 'points_asc':
          return a.points.compareTo(b.points);
        case 'points_desc':
          return b.points.compareTo(a.points);
        default:
          return b.createdAt.compareTo(a.createdAt); // 默认时间倒序
      }
    });

    _filteredRules = filtered;
  }

  String _getErrorMessage(dynamic error) {
    return ErrorMessageUtils.getErrorMessage(error);
  }

  // 显示没有情侣关系的提示对话框
  void _showNoCoupleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要邀请情侣'),
        content: const Text('创建约定需要先邀请你的情侣建立关系。\n\n你可以在主页面点击"邀请伴侣"来邀请你的情侣。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateRuleDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final pointsController = TextEditingController();
    String targetType = 'both';

    // 获取当前用户信息
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    final currentUserName = currentUser?.username ?? '我';
    final partnerName = _couple?.partner.username ?? '对方';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('创建约定'),
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
                    labelText: '约定名称',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.rule),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: '约定描述',
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
                  '适用对象:',
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
                    RadioListTile<String>(
                      title: Text(currentUserName),
                      value: 'current_user',
                      groupValue: targetType,
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onChanged: (value) {
                        setDialogState(() {
                          targetType = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: Text(partnerName),
                      value: 'partner',
                      groupValue: targetType,
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onChanged: (value) {
                        setDialogState(() {
                          targetType = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('双方'),
                      value: 'both',
                      groupValue: targetType,
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onChanged: (value) {
                        setDialogState(() {
                          targetType = value!;
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
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _createRule(
        nameController.text.trim(),
        descriptionController.text.trim(),
        pointsController.text.trim(),
        targetType,
      );
    }
  }

  Future<void> _createRule(String name, String description, String pointsStr, String targetType) async {
    if (name.isEmpty || pointsStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请填写约定名称和积分'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final points = int.tryParse(pointsStr);
    if (points == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入有效的积分值'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      await RulesApiService.createRule(
        name: name,
        description: description,
        points: points,
        targetType: targetType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('约定创建成功！'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      _loadRules();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建约定失败: ${_getErrorMessage(e)}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _executeRule(Rule rule) async {
    final pointsText = rule.points > 0 ? '+${rule.points}' : '${rule.points}';

    // 对于"both"类型的规则，需要选择目标用户
    int? targetUserId;
    if (rule.targetType == 'both') {
      targetUserId = await _showTargetUserSelectionDialog(rule, pointsText);
      if (targetUserId == null) return; // 用户取消了选择
    } else {
      // 对于单个用户的规则，显示确认对话框
      final confirmed = await _showExecuteConfirmationDialog(rule, pointsText);
      if (confirmed != true) return;
    }

    try {
      await RulesApiService.executeRule(rule.id, targetUserId: targetUserId);

      if (mounted) {
        // 获取用户提供者引用（在异步操作前）
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        // 刷新用户数据以更新积分显示
        await userProvider.loadUserProfile();

        // 重新加载规则页面数据（包括情侣信息）
        await _loadRules();

        // 触发全局刷新事件，通知其他页面更新积分显示
        eventBus.emit(Events.coupleUpdated);

        if (mounted) {
          // 确定用于撤销功能的用户ID
          int? undoTargetUserId;
          if (rule.targetType == 'both') {
            // 对于both类型的规则，使用选择的targetUserId
            undoTargetUserId = targetUserId;
          } else if (rule.targetType == 'current_user') {
            // 对于针对当前用户的规则，使用当前用户的ID
            undoTargetUserId = userProvider.user?.id;
          } else if (rule.targetType == 'partner') {
            // 对于针对伴侣的规则，使用伴侣的ID
            undoTargetUserId = _couple?.partner.id;
          }

          // 显示带撤销功能的成功提醒
          await UndoableSnackbarUtils.showUndoableSuccess(
            context,
            '约定执行成功！',
            targetUserId: undoTargetUserId,
            onRefresh: () {
              // 刷新数据
              _loadRules();
              // 重新加载用户信息以更新积分显示
              userProvider.loadUserProfile();
              // 触发全局刷新事件
              eventBus.emit(Events.coupleUpdated);
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('执行约定失败: ${_getErrorMessage(e)}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // 显示执行确认对话框（单个用户规则）
  Future<bool?> _showExecuteConfirmationDialog(Rule rule, String pointsText) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('执行约定'),
        content: Text('确定要执行约定 "${rule.name}" 吗？\n积分变化：$pointsText'),
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
            child: const Text('执行'),
          ),
        ],
      ),
    );
  }

  // 显示目标用户选择对话框（双方规则）
  Future<int?> _showTargetUserSelectionDialog(Rule rule, String pointsText) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    final currentUserName = currentUser?.username ?? '我';
    final partnerName = _couple?.partner.username ?? '对方';

    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('执行约定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('约定："${rule.name}"'),
            Text('积分变化：$pointsText'),
            const SizedBox(height: 16),
            const Text('请选择执行对象：', style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(
              '取消',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(currentUser?.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: Text(currentUserName),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_couple?.partner.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.onPrimary,
            ),
            child: Text(partnerName),
          ),
        ],
      ),
    );
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
                        onPressed: _loadRules,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRules,
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
                        _buildRulesSection(),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _couple != null ? _showCreateRuleDialog : _showNoCoupleDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  // 构建标题
  Widget _buildTitle() {
    return const Center(
      child: Text(
        '我们的约定',
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



  // 构建约定部分
  Widget _buildRulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和操作按钮行
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '所有约定',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.onBackground,
              ),
            ),
            Row(
              children: [
                // 排序按钮
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.sort,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  tooltip: '排序',
                  onSelected: (value) {
                    setState(() {
                      _sortOrder = value;
                      _applyFilterAndSort();
                    });
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'time_desc',
                      child: Row(
                        children: [
                          Icon(
                            _sortOrder == 'time_desc' ? Icons.check : null,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text('时间倒序'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'time_asc',
                      child: Row(
                        children: [
                          Icon(
                            _sortOrder == 'time_asc' ? Icons.check : null,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text('时间顺序'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'points_desc',
                      child: Row(
                        children: [
                          Icon(
                            _sortOrder == 'points_desc' ? Icons.check : null,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text('分数倒序'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'points_asc',
                      child: Row(
                        children: [
                          Icon(
                            _sortOrder == 'points_asc' ? Icons.check : null,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text('分数顺序'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // 筛选按钮
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.filter_list,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  tooltip: '筛选',
                  onSelected: (value) {
                    setState(() {
                      _filterType = value;
                      _applyFilterAndSort();
                    });
                  },
                  itemBuilder: (context) {
                    // 获取当前用户信息
                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                    final currentUser = userProvider.user;
                    final currentUserName = currentUser?.username ?? '我';
                    final partnerName = _couple?.partner.username ?? '对方';

                    return [
                      PopupMenuItem(
                        value: 'all',
                        child: Row(
                          children: [
                            Icon(
                              _filterType == 'all' ? Icons.check : null,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text('全部'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'current_user',
                        child: Row(
                          children: [
                            Icon(
                              _filterType == 'current_user' ? Icons.check : null,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(currentUserName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'partner',
                        child: Row(
                          children: [
                            Icon(
                              _filterType == 'partner' ? Icons.check : null,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(partnerName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'both',
                        child: Row(
                          children: [
                            Icon(
                              _filterType == 'both' ? Icons.check : null,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text('共同'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _rules.isEmpty
            ? _buildEmptyRulesState()
            : Column(
                children: _filteredRules.map((rule) => _buildRuleCard(rule)).toList(),
              ),
      ],
    );
  }

  // 构建空约定状态
  Widget _buildEmptyRulesState() {
    // 如果没有情侣关系，显示需要邀请情侣的提示
    if (_couple == null) {
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
                Icons.person_add_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '需要邀请情侣',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '邀请你的情侣后就可以一起创建约定了！',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // 有情侣关系但没有约定
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
              Icons.rule_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '还没有约定',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击右下角的 + 号创建第一个约定吧！',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 构建适用对象圆点标识
  Widget _buildTargetTypeDots(Rule rule) {
    if (rule.targetType == 'both') {
      // 双方：显示两个小圆点上下并列
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      );
    } else {
      // 单个用户：显示一个圆点
      final isCurrentUser = rule.targetType == 'current_user';
      final color = isCurrentUser ? AppColors.primary : AppColors.accent;

      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );
    }
  }

  Widget _buildRuleCard(Rule rule) {
    final pointsText = rule.points > 0 ? '+${rule.points}积分' : '${rule.points}积分';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rule.isPinned ? AppColors.primaryContainer.withValues(alpha: 0.3) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: rule.isPinned
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题行：标签圆点 + 约定名称
                Row(
                  children: [
                    _buildTargetTypeDots(rule),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rule.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onBackground,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // 描述
                Text(
                  rule.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Split Button
          RuleSplitButton(
            mainButtonText: pointsText,
            onMainButtonPressed: () => _executeRule(rule),
            menuItems: RuleMenuItems.buildMenuItems(isPinned: rule.isPinned),
            onMenuItemSelected: (value) => _handleMenuAction(rule, value),
            isPinned: rule.isPinned,
          ),
        ],
      ),
    );
  }

  // 处理菜单操作
  Future<void> _handleMenuAction(Rule rule, String action) async {
    switch (action) {
      case 'pin':
        await _pinRule(rule);
        break;
      case 'unpin':
        await _unpinRule(rule);
        break;
      case 'edit':
        await _editRule(rule);
        break;
      case 'delete':
        await _deleteRule(rule);
        break;
    }
  }

  // 置顶规则
  Future<void> _pinRule(Rule rule) async {
    try {
      await RulesApiService.pinRule(rule.id);

      if (mounted) {
        final message = rule.isPinned ? '置顶时间已刷新' : '约定已置顶';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.primary,
          ),
        );
        _loadRules(); // 重新加载规则列表
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('置顶失败: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // 取消置顶规则
  Future<void> _unpinRule(Rule rule) async {
    try {
      await RulesApiService.unpinRule(rule.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已取消置顶'),
            backgroundColor: AppColors.primary,
          ),
        );
        _loadRules(); // 重新加载规则列表
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('取消置顶失败: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // 编辑规则
  Future<void> _editRule(Rule rule) async {
    final nameController = TextEditingController(text: rule.name);
    final descriptionController = TextEditingController(text: rule.description);
    final pointsController = TextEditingController(text: rule.points.toString());
    String targetType = rule.targetType;

    // 获取当前用户信息
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    final currentUserName = currentUser?.username ?? '我';
    final partnerName = _couple?.partner.username ?? '对方';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('修改约定'),
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
                    labelText: '约定名称',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.rule),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: '约定描述',
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
                const Text(
                  '适用对象:',
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
                    RadioListTile<String>(
                      title: Text(currentUserName),
                      value: 'current_user',
                      groupValue: targetType,
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onChanged: (value) {
                        setDialogState(() {
                          targetType = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: Text(partnerName),
                      value: 'partner',
                      groupValue: targetType,
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onChanged: (value) {
                        setDialogState(() {
                          targetType = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('双方'),
                      value: 'both',
                      groupValue: targetType,
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onChanged: (value) {
                        setDialogState(() {
                          targetType = value!;
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
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final name = nameController.text.trim();
      final description = descriptionController.text.trim();
      final pointsText = pointsController.text.trim();

      if (name.isEmpty || pointsText.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('请填写约定名称和积分'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final points = int.tryParse(pointsText);
      if (points == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('积分必须是数字'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      try {
        await RulesApiService.updateRule(
          rule.id,
          name: name,
          description: description,
          points: points,
          targetType: targetType,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('约定修改成功！'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadRules();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('修改约定失败: ${_getErrorMessage(e)}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    // 不手动dispose controllers，让它们自然被垃圾回收
    // 这样可以避免在StatefulBuilder重建时出现"disposed controller"错误
  }

  // 删除规则
  Future<void> _deleteRule(Rule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除约定'),
        content: Text('确定要删除约定 "${rule.name}" 吗？\n此操作不可撤销。'),
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
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onPrimary,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await RulesApiService.deleteRule(rule.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('约定删除成功！'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadRules();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('删除约定失败: ${_getErrorMessage(e)}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
