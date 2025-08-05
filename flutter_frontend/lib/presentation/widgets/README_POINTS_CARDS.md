# 积分卡片组件使用指南

## 概述

`PointsCardsWidget` 是一个统一的积分卡片组件，用于在多个页面中显示用户和伴侣的积分信息。该组件解决了跨平台文本显示一致性问题，并提供了可复用的积分卡片界面。

## 主要特性

- ✅ **跨平台文本一致性** - 自动适配 iOS 和 Android 的字体差异
- ✅ **响应式设计** - 根据屏幕尺寸自动调整字体大小
- ✅ **智能文本布局** - 自动处理长用户名的溢出问题
- ✅ **统一管理** - 一处修改，全局生效
- ✅ **多种样式** - 支持标准卡片、紧凑卡片等多种样式

## 组件结构

```
PointsCardsWidget (主组件)
├── PointsCard (单个积分卡片)
├── EmptyPointsCard (空卡片)
├── CompactPointsCard (紧凑卡片)
└── PointsCardBuilder (构建器)
```

## 基本使用

### 1. 标准积分卡片组

```dart
import '../../widgets/points_cards_widget.dart';

class MyScreen extends StatelessWidget {
  final Couple? couple;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 基本使用
        PointsCardsWidget(couple: couple),
        
        // 带自定义间距和内边距
        PointsCardsWidget(
          couple: couple,
          spacing: 16,
          padding: EdgeInsets.symmetric(horizontal: 20),
        ),
      ],
    );
  }
}
```

### 2. 单个积分卡片

```dart
PointsCard(
  name: "用户名",
  points: 1234,
  avatar: "avatar_url",
  backgroundColor: AppColors.primaryContainer,
  borderColor: AppColors.primary,
  isCurrentUser: true,
  onTap: () {
    // 点击事件处理
  },
)
```

### 3. 空积分卡片

```dart
EmptyPointsCard(
  text: "邀请伴侣",
  onTap: () {
    // 邀请伴侣逻辑
  },
)
```

### 4. 紧凑积分卡片

```dart
CompactPointsCard(
  name: "用户名",
  points: 1234,
  avatar: "avatar_url",
  backgroundColor: AppColors.primaryContainer,
  borderColor: AppColors.primary,
  isCurrentUser: true,
)
```

## 高级使用

### 使用构建器模式

```dart
// 标准卡片
Widget standardCard = PointsCardBuilder.buildStandardCard(
  name: "用户名",
  points: 1234,
  avatar: "avatar_url",
  backgroundColor: AppColors.primaryContainer,
  borderColor: AppColors.primary,
  isCurrentUser: true,
  onTap: () => print("点击了卡片"),
);

// 紧凑卡片
Widget compactCard = PointsCardBuilder.buildCompactCard(
  name: "用户名",
  points: 1234,
  avatar: "avatar_url",
  backgroundColor: AppColors.primaryContainer,
  borderColor: AppColors.primary,
  isCurrentUser: true,
);

// 空卡片
Widget emptyCard = PointsCardBuilder.buildEmptyCard(
  text: "自定义文本",
  onTap: () => print("点击了空卡片"),
);
```

## 替换现有代码

### 之前的代码（需要删除）

```dart
// ❌ 旧的重复代码
Widget _buildPointsCards() {
  return Consumer<UserProvider>(
    builder: (context, userProvider, child) {
      final user = userProvider.user;
      if (user == null) return const SizedBox.shrink();

      return Row(
        children: [
          Expanded(
            child: _buildPointCard(
              user.username,
              user.points,
              user.avatar,
              AppColors.primaryContainer,
              AppColors.primary,
              Icons.favorite,
              true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _couple != null
                ? _buildPointCard(/* ... */)
                : _buildEmptyPointCard(),
          ),
        ],
      );
    },
  );
}
```

### 现在的代码（推荐）

```dart
// ✅ 新的统一组件
Widget _buildPointsCards() {
  return PointsCardsWidget(couple: _couple);
}
```

## 自定义样式

### 颜色配置

组件使用 `AppColors` 中定义的颜色：

- `AppColors.primaryContainer` - 当前用户卡片背景
- `AppColors.primary` - 当前用户卡片边框
- `AppColors.accentContainer` - 伴侣卡片背景
- `AppColors.accent` - 伴侣卡片边框
- `AppColors.disabled` - 空卡片背景

### 响应式文本

组件内部使用 `ResponsiveText` 工具类确保跨平台一致性：

- 自动根据屏幕宽度调整字体大小
- 支持平台特定字体（iOS: SF Pro Text, Android: Roboto）
- 智能处理文本溢出

## 已更新的页面

以下页面已经更新使用新的积分卡片组件：

- ✅ `HomeScreen` - 首页
- ✅ `ShopScreen` - 商店页面
- ✅ `MyShopScreen` - 我的商店页面
- ✅ `RulesScreen` - 规则页面

## 注意事项

1. **导入依赖** - 确保导入 `points_cards_widget.dart`
2. **删除旧代码** - 删除页面中的 `_buildPointCard` 和 `_buildEmptyPointCard` 方法
3. **Couple 参数** - 确保传入正确的 `Couple` 对象
4. **状态管理** - 组件内部使用 `Consumer<UserProvider>` 自动获取用户信息

## 故障排除

### 常见问题

1. **文本溢出** - 组件已自动处理，使用多级适配策略
2. **字体不一致** - 组件已配置平台特定字体
3. **点击无响应** - 检查是否正确传入 `onTap` 回调

### 调试工具

可以使用 `TextDebugScreen` 来测试文本显示效果：

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => TextDebugScreen()),
);
```

## 更新日志

- **v1.0.0** - 初始版本，支持基本积分卡片显示
- **v1.1.0** - 添加响应式文本支持
- **v1.2.0** - 添加多种卡片样式和构建器模式
