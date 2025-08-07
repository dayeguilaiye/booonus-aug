import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/user_provider.dart';
import '../../core/models/couple.dart';
import '../../core/utils/number_formatter.dart';
import '../../core/services/couple_api_service.dart';
import '../../core/utils/event_bus.dart';
import 'user_avatar.dart';
import 'points_card_text.dart';
import 'invite_couple_dialog.dart';

/// 统一的积分卡片组件 - 在多个页面中复用
class PointsCardsWidget extends StatefulWidget {
  final Couple? couple;
  final EdgeInsets? padding;
  final double? spacing;

  const PointsCardsWidget({
    super.key,
    this.couple,
    this.padding,
    this.spacing = 12,
  });

  @override
  State<PointsCardsWidget> createState() => _PointsCardsWidgetState();
}

class _PointsCardsWidgetState extends State<PointsCardsWidget> {
  // 显示邀请情侣对话框
  Future<void> _showInviteCoupleDialog() async {
    final username = await showDialog<String>(
      context: context,
      builder: (context) => const InviteCoupleDialog(),
    );

    if (username != null && username.isNotEmpty) {
      try {
        // 显示加载状态
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('正在发送邀请...'),
              backgroundColor: AppColors.primary,
            ),
          );
        }

        // 调用邀请API
        await CoupleApiService.invite(username);

        if (mounted) {
          // 隐藏加载提示
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          // 显示成功消息
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('邀请成功！情侣关系已建立'),
              backgroundColor: AppColors.success,
            ),
          );

          // 刷新用户数据
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          await userProvider.loadUserProfile();

          // 触发全局刷新 - 通知所有依赖伴侣状态的页面更新
          _triggerGlobalRefresh();
        }
      } catch (e) {
        if (mounted) {
          // 隐藏加载提示
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          // 显示错误消息
          String errorMessage = e.toString();
          if (errorMessage.startsWith('Exception: ')) {
            errorMessage = errorMessage.substring('Exception: '.length);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('邀请失败: $errorMessage'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  // 触发全局刷新
  void _triggerGlobalRefresh() {
    // 发送情侣关系更新事件，通知所有监听的页面刷新
    eventBus.emit(Events.coupleUpdated);
  }

  // 导航到我的积分历史页面
  void _navigateToMyPointsHistory() {
    context.push('/points-history/my');
  }

  // 导航到对方的积分历史页面
  void _navigateToPartnerPointsHistory() {
    final targetUserId = widget.couple?.partner.id;
    if (targetUserId != null) {
      context.push('/points-history/partner?targetUserId=$targetUserId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        if (user == null) return const SizedBox.shrink();

        return Padding(
          padding: widget.padding ?? EdgeInsets.zero,
          child: Row(
            children: [
              // 当前用户的积分卡片
              Expanded(
                child: PointsCard(
                  name: user.username,
                  points: user.points,
                  avatar: user.avatar,
                  backgroundColor: AppColors.primaryContainer,
                  borderColor: AppColors.primary,
                  isCurrentUser: true,
                  onTap: _navigateToMyPointsHistory,
                ),
              ),
              SizedBox(width: widget.spacing!),
              // 伴侣的积分卡片或空卡片
              Expanded(
                child: widget.couple != null
                    ? PointsCard(
                        name: widget.couple!.partner.username,
                        points: widget.couple!.partner.points,
                        avatar: widget.couple!.partner.avatar,
                        backgroundColor: AppColors.accentContainer,
                        borderColor: AppColors.accent,
                        isCurrentUser: false,
                        onTap: _navigateToPartnerPointsHistory,
                      )
                    : EmptyPointsCard(
                        text: '邀请伴侣',
                        onTap: _showInviteCoupleDialog,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 单个积分卡片组件
class PointsCard extends StatelessWidget {
  final String name;
  final int points;
  final String? avatar;
  final Color backgroundColor;
  final Color borderColor;
  final bool isCurrentUser;
  final EdgeInsets? padding;
  final double? borderRadius;
  final VoidCallback? onTap;

  const PointsCard({
    super.key,
    required this.name,
    required this.points,
    this.avatar,
    required this.backgroundColor,
    required this.borderColor,
    required this.isCurrentUser,
    this.padding,
    this.borderRadius = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius!),
        // 添加轻微的阴影效果
        boxShadow: [
          BoxShadow(
            color: AppColors.gentleShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 左侧：头像
          UserAvatar(
            avatar: avatar,
            size: 60,
            borderColor: borderColor,
            borderWidth: 3,
          ),
          const SizedBox(width: 16),
          // 右侧：文字信息
          Expanded(
            child: PointsCardTextArea(
              name: name,
              points: points,
            ),
          ),
        ],
      ),
    );

    // 如果有点击回调，包装在GestureDetector中
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: cardContent,
      );
    }

    return cardContent;
  }
}

/// 空的积分卡片（当没有伴侣时显示）
class EmptyPointsCard extends StatelessWidget {
  final EdgeInsets? padding;
  final double? borderRadius;
  final String? text;
  final VoidCallback? onTap;

  const EmptyPointsCard({
    super.key,
    this.padding,
    this.borderRadius = 16,
    this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.disabled,
        borderRadius: BorderRadius.circular(borderRadius!),
        border: Border.all(
          color: AppColors.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add_outlined,
            size: 40,
            color: AppColors.onSurfaceVariant.withOpacity(0.6),
          ),
          const SizedBox(height: 8),
          Text(
            text ?? '邀请伴侣',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    // 如果有点击回调，包装在GestureDetector中
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: cardContent,
      );
    }

    return cardContent;
  }
}

/// 积分卡片的变体 - 用于特殊场景
class CompactPointsCard extends StatelessWidget {
  final String name;
  final int points;
  final String? avatar;
  final Color backgroundColor;
  final Color borderColor;
  final bool isCurrentUser;

  const CompactPointsCard({
    super.key,
    required this.name,
    required this.points,
    this.avatar,
    required this.backgroundColor,
    required this.borderColor,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserAvatar(
            avatar: avatar,
            size: 40,
            borderColor: borderColor,
            borderWidth: 2,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onBackground,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                NumberFormatter.formatPoints(points),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onBackground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 积分卡片构建器 - 提供更多自定义选项
class PointsCardBuilder {
  static Widget buildStandardCard({
    required String name,
    required int points,
    String? avatar,
    required Color backgroundColor,
    required Color borderColor,
    required bool isCurrentUser,
    VoidCallback? onTap,
  }) {
    return PointsCard(
      name: name,
      points: points,
      avatar: avatar,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      isCurrentUser: isCurrentUser,
      onTap: onTap,
    );
  }

  static Widget buildCompactCard({
    required String name,
    required int points,
    String? avatar,
    required Color backgroundColor,
    required Color borderColor,
    required bool isCurrentUser,
  }) {
    return CompactPointsCard(
      name: name,
      points: points,
      avatar: avatar,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      isCurrentUser: isCurrentUser,
    );
  }

  static Widget buildEmptyCard({
    String? text,
    VoidCallback? onTap,
  }) {
    return EmptyPointsCard(
      text: text,
      onTap: onTap,
    );
  }
}
