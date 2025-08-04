import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/user_api_service.dart';
import '../../widgets/user_avatar.dart';

class AvatarSelectionScreen extends StatefulWidget {
  const AvatarSelectionScreen({super.key});

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  String? _selectedAvatar;
  bool _isLoading = false;

  // 可用的头像列表
  final List<String> _availableAvatars = [
    'avatar_01.png',
    'avatar_02.png',
    'avatar_03.png',
    'avatar_04.png',
    'avatar_05.png',
    'avatar_06.png',
  ];

  @override
  void initState() {
    super.initState();
    // 初始化当前用户的头像
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _selectedAvatar = userProvider.user?.avatar;
  }

  Future<void> _updateAvatar() async {
    if (_selectedAvatar == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await UserApiService.updateProfile(avatar: _selectedAvatar);

      // 更新本地用户信息
      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.loadUserProfile();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('头像更新成功！'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('头像更新失败：${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.onSurface,
          ),
        ),
        title: const Text(
          '选择头像',
          style: TextStyle(
            color: AppColors.onBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_selectedAvatar != null)
            TextButton(
              onPressed: _isLoading ? null : _updateAvatar,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : const Text(
                      '保存',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前头像预览
            _buildCurrentAvatarPreview(),
            const SizedBox(height: 32),
            // 头像选择网格
            const Text(
              '选择新头像',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildAvatarGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentAvatarPreview() {
    return Center(
      child: Column(
        children: [
          const Text(
            '当前头像',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          UserAvatar(
            avatar: _selectedAvatar,
            size: 120,
            borderColor: AppColors.primary,
            borderWidth: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: _availableAvatars.length,
      itemBuilder: (context, index) {
        final avatarName = _availableAvatars[index];
        final isSelected = _selectedAvatar == avatarName;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedAvatar = avatarName;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.outline,
                width: isSelected ? 3 : 1,
              ),
              color: isSelected 
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surface,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableSize = constraints.maxWidth.isFinite
                      ? constraints.maxWidth
                      : constraints.maxHeight.isFinite
                          ? constraints.maxHeight
                          : 100.0;
                  return UserAvatar(
                    avatar: avatarName,
                    size: availableSize,
                    borderColor: Colors.transparent,
                    borderWidth: 0,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
