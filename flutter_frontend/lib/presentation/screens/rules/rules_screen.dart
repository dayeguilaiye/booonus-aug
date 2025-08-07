import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/models/rule.dart';
import '../../../core/models/couple.dart';
import '../../../core/services/rules_api_service.dart';
import '../../../core/services/couple_api_service.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/event_bus.dart';

import '../../widgets/points_cards_widget.dart';

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
            return rule.targetType == 'current_user';
          case 'partner':
            return rule.targetType == 'partner';
          case 'both':
            return rule.targetType == 'both';
          default:
            return true;
        }
      }).toList();
    }

    // 应用排序
    filtered.sort((a, b) {
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
    if (error is DioException) {
      return error.response?.data?['error'] ?? error.message ?? '网络错误';
    }
    // 如果是Exception类型，提取其中的消息
    String errorStr = error.toString();
    if (errorStr.startsWith('Exception: ')) {
      return errorStr.substring('Exception: '.length);
    }
    return errorStr;
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
        // 刷新用户数据以更新积分显示
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.loadUserProfile();

        // 重新加载规则页面数据（包括情侣信息）
        await _loadRules();

        // 触发全局刷新事件，通知其他页面更新积分显示
        eventBus.emit(Events.coupleUpdated);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('约定执行成功！'),
              backgroundColor: AppColors.success,
            ),
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

  // 构建适用对象标签
  Widget _buildTargetTypeTags(Rule rule) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    final currentUserName = currentUser?.username ?? '我';
    final partnerName = _couple?.partner.username ?? '对方';

    if (rule.targetType == 'both') {
      // 双方：显示两个标签
      return Row(
        children: [
          // 当前用户标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  currentUserName,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 伴侣标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 4),
                Text(
                  partnerName,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // 单个用户：显示一个标签
      final isCurrentUser = rule.targetType == 'current_user';
      final displayName = isCurrentUser ? currentUserName : partnerName;
      final color = isCurrentUser ? AppColors.primary : AppColors.accent;
      final icon = isCurrentUser ? Icons.person : Icons.person_outline;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              displayName,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildRuleCard(Rule rule) {
    final pointsText = rule.points > 0 ? '+${rule.points}积分' : '${rule.points}积分';
    final pointsColor = rule.points > 0 ? AppColors.success : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Slidable(
        key: ValueKey(rule.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) => _editRule(rule),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              icon: Icons.edit,
              label: '修改',
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
            SlidableAction(
              onPressed: (context) => _deleteRule(rule),
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onPrimary,
              icon: Icons.delete,
              label: '删除',
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: AppColors.gentleShadow,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 主要内容：左右两列布局
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左列：约定名称、描述、标签
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 第一行：约定名称
                          Text(
                            rule.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 第二行：约定描述
                          if (rule.description.isNotEmpty)
                            Text(
                              rule.description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 12),
                          // 第三行：适用对象标签
                          _buildTargetTypeTags(rule),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 右列：积分和执行按钮
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // 第一行：积分显示
                        Text(
                          pointsText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: pointsColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 第二行：执行按钮
                        ElevatedButton(
                          onPressed: () => _executeRule(rule),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          ),
                          child: const Text(
                            '执行',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
