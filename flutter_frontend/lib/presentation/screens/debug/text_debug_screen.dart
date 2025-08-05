import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_text.dart';
import '../../widgets/points_card_text.dart';
import '../../widgets/user_avatar.dart';

/// 文本调试页面 - 用于测试跨平台文本显示一致性
class TextDebugScreen extends StatelessWidget {
  const TextDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文本显示调试'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeviceInfo(context),
            const SizedBox(height: 24),
            _buildTextSamples(context),
            const SizedBox(height: 24),
            _buildPointsCardSamples(context),
            const SizedBox(height: 24),
            _buildResponsiveTextSamples(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfo(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '设备信息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text('屏幕宽度: ${mediaQuery.size.width.toStringAsFixed(1)}'),
            Text('屏幕高度: ${mediaQuery.size.height.toStringAsFixed(1)}'),
            Text('像素比: ${mediaQuery.devicePixelRatio.toStringAsFixed(2)}'),
            Text('文本缩放: ${mediaQuery.textScaler.scale(1.0).toStringAsFixed(2)}'),
            Text('平台字体: ${ResponsiveText.getPlatformFontFamily() ?? "默认"}'),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSamples(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '文本样本',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildTextSample('固定字体 15px', 15, FontWeight.bold),
            _buildTextSample('固定字体 13px', 13, FontWeight.normal),
            const SizedBox(height: 8),
            ResponsiveTextWidget(
              '响应式字体 15px',
              baseFontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            ResponsiveTextWidget(
              '响应式字体 13px',
              baseFontSize: 13,
              fontWeight: FontWeight.normal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSample(String text, double fontSize, FontWeight fontWeight) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }

  Widget _buildPointsCardSamples(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '积分卡片样本',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // 短用户名测试
            _buildSamplePointsCard('小明', 1234),
            const SizedBox(height: 12),
            // 长用户名测试
            _buildSamplePointsCard('非常长的用户名测试', 5678),
            const SizedBox(height: 12),
            // 超长用户名测试
            _buildSamplePointsCard('这是一个超级超级长的用户名用来测试文本溢出', 9999),
          ],
        ),
      ),
    );
  }

  Widget _buildSamplePointsCard(String name, int points) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const UserAvatar(
            avatar: null,
            size: 60,
            borderColor: AppColors.primary,
            borderWidth: 3,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: PointsCardTextArea(
              name: name,
              points: points,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveTextSamples(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '自适应文本测试',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // 不同宽度容器中的自适应文本
            _buildAutoFitContainer('短文本', 150),
            const SizedBox(height: 8),
            _buildAutoFitContainer('中等长度的文本内容', 200),
            const SizedBox(height: 8),
            _buildAutoFitContainer('这是一段很长很长的文本内容用来测试自适应功能', 250),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoFitContainer(String text, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AutoFitText(
        text,
        baseFontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.onBackground,
      ),
    );
  }
}
