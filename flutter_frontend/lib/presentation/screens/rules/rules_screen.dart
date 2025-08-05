import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../../core/models/rule.dart';
import '../../../core/models/couple.dart';
import '../../../core/services/rules_api_service.dart';
import '../../../core/services/couple_api_service.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/points_cards_widget.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  List<Rule> _rules = [];
  bool _isLoading = true;
  Couple? _couple;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 延迟到下一帧执行，避免在build过程中调用ScaffoldMessenger
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRules();
    });
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
      final response = await RulesApiService.getRules();
      final rulesData = response['rules'] as List<dynamic>? ?? [];
      _rules = rulesData.map((rule) => Rule.fromJson(rule)).toList();
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

  Future<void> _showCreateRuleDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final pointsController = TextEditingController();
    String targetType = 'both';

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
                      title: const Text('用户1'),
                      value: 'user1',
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
                      title: const Text('用户2'),
                      value: 'user2',
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
        SnackBar(
          content: const Text('请填写约定名称和积分'),
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
      await RulesApiService.createRule(
        name: name,
        description: description,
        points: points,
        targetType: targetType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('约定创建成功！'),
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
    final confirmed = await showDialog<bool>(
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

    if (confirmed != true) return;

    try {
      await RulesApiService.executeRule(rule.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('约定执行成功！'),
            backgroundColor: AppColors.success,
          ),
        );
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
        onPressed: _showCreateRuleDialog,
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
        const Text(
          '所有约定',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.onBackground, // 深棕色
          ),
        ),
        const SizedBox(height: 16),
        _rules.isEmpty
            ? _buildEmptyRulesState()
            : Column(
                children: _rules.map((rule) => _buildRuleCard(rule)).toList(),
              ),
      ],
    );
  }

  // 构建空约定状态
  Widget _buildEmptyRulesState() {
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

  Widget _buildRuleCard(Rule rule) {
    final pointsText = rule.points > 0 ? '+${rule.points}积分' : '${rule.points}积分';
    final pointsColor = rule.points > 0 ? AppColors.success : AppColors.error;

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
                // 左列：约定名称和描述
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (rule.description.isNotEmpty)
                        Text(
                          rule.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // 右列：积分和执行按钮
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 积分显示
                    Text(
                      pointsText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: pointsColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 执行按钮
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
            // 底部：适用对象标签
            if (rule.targetType != 'both') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentWithOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rule.getTargetTypeText(),
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
}
