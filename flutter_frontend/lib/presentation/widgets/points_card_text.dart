import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_text.dart';
import '../../core/utils/number_formatter.dart';

/// 积分卡片专用文本组件，简化显示用户名
class PointsCardText extends StatelessWidget {
  final String name;
  final int maxLines;
  final TextAlign textAlign;

  const PointsCardText({
    super.key,
    required this.name,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    // 简化：直接显示用户名，使用普通的Text组件
    return Text(
      name,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.onBackground,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }


}

/// 积分数值显示组件
class PointsValueText extends StatelessWidget {
  final int points;
  final Color? color;
  final TextAlign textAlign;

  const PointsValueText({
    super.key,
    required this.points,
    this.color,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      NumberFormatter.formatPoints(points),
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: color ?? AppColors.onBackground,
      ),
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// 完整的积分卡片文本区域组件
class PointsCardTextArea extends StatelessWidget {
  final String name;
  final int points;

  const PointsCardTextArea({
    super.key,
    required this.name,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PointsCardText(name: name),
        const SizedBox(height: 4),
        PointsValueText(points: points),
      ],
    );
  }
}
