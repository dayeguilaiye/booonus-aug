import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/models/rule.dart';
import '../../../core/services/rules_api_service.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/dialog_utils.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/points_chip.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  List<Rule> _rules = [];
  bool _isLoading = true;

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
    });

    try {
      final response = await RulesApiService.getRules();
      final rulesData = response['rules'] as List<dynamic>? ?? [];

      setState(() {
        _rules = rulesData.map((rule) => Rule.fromJson(rule)).toList();
      });
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, '加载规则失败: ${_getErrorMessage(e)}');
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

  Future<void> _showCreateRuleDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final pointsController = TextEditingController();
    String targetType = 'both';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('创建规则'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '规则名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '规则描述',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pointsController,
                  decoration: const InputDecoration(
                    labelText: '积分变化（正数为奖励，负数为惩罚）',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Text('适用对象:', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('用户1'),
                      value: 'user1',
                      groupValue: targetType,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
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
      SnackbarUtils.showError(context, '请填写规则名称和积分');
      return;
    }

    final points = int.tryParse(pointsStr);
    if (points == null) {
      SnackbarUtils.showError(context, '请输入有效的积分值');
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
        SnackbarUtils.showSuccess(context, '规则创建成功！');
      }
      _loadRules();
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, '创建规则失败: ${_getErrorMessage(e)}');
      }
    }
  }

  Future<void> _executeRule(Rule rule) async {
    final pointsText = rule.points > 0 ? '+${rule.points}' : '${rule.points}';
    final confirmed = await DialogUtils.showConfirmDialog(
      context,
      title: '执行规则',
      content: '确定要执行规则 "${rule.name}" 吗？\n积分变化：$pointsText',
      confirmText: '执行',
      confirmColor: Theme.of(context).colorScheme.primary,
    );

    if (confirmed != true) return;

    try {
      await RulesApiService.executeRule(rule.id);

      if (mounted) {
        SnackbarUtils.showSuccess(context, '规则执行成功！');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, '执行规则失败: ${_getErrorMessage(e)}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('规则管理'),
      ),
      body: _isLoading
          ? const LoadingWidget(message: '加载中...')
          : _rules.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.rule_outlined,
                  title: '还没有规则',
                  subtitle: '创建一些积分规则吧！',
                  action: ElevatedButton.icon(
                    onPressed: _showCreateRuleDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('创建规则'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRules,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rules.length,
                    itemBuilder: (context, index) {
                      final rule = _rules[index];
                      return _buildRuleCard(rule);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRuleDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRuleCard(Rule rule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    rule.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PointsChip(points: rule.points),
              ],
            ),
            if (rule.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                rule.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rule.getTargetTypeText(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onTertiaryContainer,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _executeRule(rule),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: const Text('执行'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
