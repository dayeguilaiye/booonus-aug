import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Material Design 3 风格的分割按钮组件
/// 左半边是主要操作按钮，右半边是更多操作的下拉菜单
class RuleSplitButton extends StatelessWidget {
  final String mainButtonText;
  final VoidCallback onMainButtonPressed;
  final List<PopupMenuEntry<String>> menuItems;
  final Function(String) onMenuItemSelected;
  final bool isPinned;

  const RuleSplitButton({
    super.key,
    required this.mainButtonText,
    required this.onMainButtonPressed,
    required this.menuItems,
    required this.onMenuItemSelected,
    this.isPinned = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.gentleShadow,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 左半边：主要操作按钮
          _buildMainButton(),
          // 分割线
          Container(
            width: 1,
            height: 20,
            color: AppColors.onPrimary.withValues(alpha: 0.3),
          ),
          // 右半边：更多操作按钮
          _buildMenuButton(),
        ],
      ),
    );
  }

  Widget _buildMainButton() {
    return Container(
      height: 32,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onMainButtonPressed,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              mainButtonText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton() {
    return Container(
      height: 32,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: PopupMenuButton<String>(
        onSelected: onMenuItemSelected,
        itemBuilder: (context) => menuItems,
        offset: const Offset(0, 35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 24,
          height: 32,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 创建置顶相关的菜单项
class RuleMenuItems {
  static List<PopupMenuEntry<String>> buildMenuItems({
    required bool isPinned,
  }) {
    final List<PopupMenuEntry<String>> items = [];

    // 置顶选项 - 始终显示
    items.add(
      PopupMenuItem<String>(
        value: 'pin',
        child: Row(
          children: [
            const Icon(
              Icons.push_pin,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(isPinned ? '刷新置顶' : '置顶'),
          ],
        ),
      ),
    );

    // 如果已置顶，添加取消置顶选项
    if (isPinned) {
      items.add(
        const PopupMenuItem<String>(
          value: 'unpin',
          child: Row(
            children: [
              Icon(
                Icons.push_pin_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Text('取消置顶'),
            ],
          ),
        ),
      );
    }

    // 修改选项
    items.add(
      const PopupMenuItem<String>(
        value: 'edit',
        child: Row(
          children: [
            Icon(
              Icons.edit,
              size: 16,
              color: AppColors.primary,
            ),
            SizedBox(width: 8),
            Text('修改'),
          ],
        ),
      ),
    );

    // 删除选项
    items.add(
      const PopupMenuItem<String>(
        value: 'delete',
        child: Row(
          children: [
            Icon(
              Icons.delete,
              size: 16,
              color: AppColors.error,
            ),
            SizedBox(width: 8),
            Text('删除'),
          ],
        ),
      ),
    );

    return items;
  }
}
