import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String? avatar;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final bool showEditIcon;

  const UserAvatar({
    super.key,
    this.avatar,
    this.size = 60,
    this.borderColor,
    this.borderWidth = 3,
    this.onTap,
    this.showEditIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    // 确保size是有限的
    final safeSize = size.isFinite ? size : 60.0;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: safeSize,
            height: safeSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(safeSize / 2),
              border: borderColor != null
                  ? Border.all(
                      color: borderColor!,
                      width: borderWidth,
                    )
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular((safeSize - borderWidth * 2) / 2),
              child: _buildAvatarImage(),
            ),
          ),
          if (showEditIcon)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: safeSize * 0.3,
                height: safeSize * 0.3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(safeSize * 0.15),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: safeSize * 0.15,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage() {
    // 确保size是有限的
    final safeSize = size.isFinite ? size : 60.0;

    // 如果有自定义头像，使用自定义头像
    if (avatar != null && avatar!.isNotEmpty) {
      return Image.asset(
        'assets/images/avatars/$avatar',
        width: safeSize - borderWidth * 2,
        height: safeSize - borderWidth * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // 如果自定义头像加载失败，使用默认头像
          return _buildDefaultAvatar();
        },
      );
    }

    // 使用默认头像
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    // 确保size是有限的
    final safeSize = size.isFinite ? size : 60.0;

    return Image.asset(
      'assets/images/avatars/avatar_default.png',
      width: safeSize - borderWidth * 2,
      height: safeSize - borderWidth * 2,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // 如果默认头像也加载失败，显示图标
        return Container(
          decoration: BoxDecoration(
            color: (borderColor ?? AppColors.primary).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular((safeSize - borderWidth * 2) / 2),
          ),
          child: Icon(
            Icons.person,
            color: borderColor ?? AppColors.primary,
            size: (safeSize - borderWidth * 2) * 0.6,
          ),
        );
      },
    );
  }
}
