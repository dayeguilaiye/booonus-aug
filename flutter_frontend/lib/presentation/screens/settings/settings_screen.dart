import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _baseUrlController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _baseUrlController.text = apiService.getCurrentBaseUrl();
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _updateBaseUrl() async {
    final newUrl = _baseUrlController.text.trim();
    if (newUrl.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await apiService.updateBaseUrl(newUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API 地址更新成功'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新失败：${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetToDefault() {
    _baseUrlController.text = ApiService.defaultBaseUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            _buildHeader(),

            const SizedBox(height: 32),

            // API 配置区域
            _buildApiConfigSection(),

            const SizedBox(height: 32),

            // 关于应用区域
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  // 构建标题栏
  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.onSurface,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          '设置',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.onBackground,
          ),
        ),
      ],
    );
  }

  // 构建API配置区域
  Widget _buildApiConfigSection() {
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
            'API 配置',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 20),
          _buildSettingItem(
            icon: Icons.link,
            iconColor: AppColors.primary,
            title: 'API 基础地址',
            subtitle: _baseUrlController.text.isNotEmpty
                ? _baseUrlController.text
                : '未设置',
            onTap: () => _showApiConfigDialog(),
          ),
        ],
      ),
    );
  }

  // 构建关于应用区域
  Widget _buildAboutSection() {
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
            '关于应用',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 20),
          _buildSettingItem(
            icon: Icons.info,
            iconColor: AppColors.primary,
            title: '版本信息',
            subtitle: '1.0.0',
            onTap: () => _showVersionInfo(),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.code,
            iconColor: AppColors.primary,
            title: '开源许可',
            subtitle: '查看开源许可证',
            onTap: () => _showLicenses(),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.bug_report,
            iconColor: AppColors.primary,
            title: '反馈问题',
            subtitle: '报告问题或建议',
            onTap: () => _showFeedback(),
          ),
        ],
      ),
    );
  }

  // 构建设置项（复用个人资料页面的样式）
  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
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
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  // 显示API配置对话框
  void _showApiConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API 配置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('API 基础地址'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                hintText: 'http://192.168.31.248:8080',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: _resetToDefault,
            child: const Text('重置'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () async {
              final navigator = Navigator.of(context);
              await _updateBaseUrl();
              if (mounted) {
                navigator.pop();
              }
            },
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
    );
  }

  // 显示版本信息
  void _showVersionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('版本信息'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('应用名称：小小卖部'),
            SizedBox(height: 8),
            Text('版本号：1.0.0'),
            SizedBox(height: 8),
            Text('构建日期：2024年8月'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 显示开源许可
  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: '小小卖部',
      applicationVersion: '1.0.0',
    );
  }

  // 显示反馈
  void _showFeedback() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('反馈问题'),
        content: const Text('如果您遇到问题或有建议，请联系开发者。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
