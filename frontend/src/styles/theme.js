import { MD3LightTheme } from 'react-native-paper';

// 马卡龙配色方案
export const colors = {
  // 主色调 - 粉色系
  primary: '#FFB6C1',      // 浅粉色
  primaryContainer: '#FFE4E1', // 更浅的粉色
  onPrimary: '#8B4B6B',    // 深粉色文字
  onPrimaryContainer: '#8B4B6B',

  // 次要色调 - 薄荷绿
  secondary: '#98FB98',    // 薄荷绿
  secondaryContainer: '#F0FFF0', // 浅薄荷绿
  onSecondary: '#2E8B57',  // 深绿色文字
  onSecondaryContainer: '#2E8B57',

  // 第三色调 - 薰衣草紫
  tertiary: '#DDA0DD',     // 薰衣草紫
  tertiaryContainer: '#F8F0FF', // 浅紫色
  onTertiary: '#663399',   // 深紫色文字
  onTertiaryContainer: '#663399',

  // 背景色
  background: '#FFFBF7',   // 温暖的白色
  onBackground: '#5D4E75', // 深紫灰色文字
  surface: '#FFFFFF',      // 纯白色
  onSurface: '#5D4E75',
  surfaceVariant: '#F5F5DC', // 米色
  onSurfaceVariant: '#8B7D8B',

  // 轮廓和分割线
  outline: '#E6E6FA',      // 淡紫色轮廓
  outlineVariant: '#F0F8FF',

  // 错误色
  error: '#FFB4AB',        // 柔和的红色
  onError: '#8B0000',
  errorContainer: '#FFEBEE',
  onErrorContainer: '#8B0000',

  // 成功色（自定义）
  success: '#90EE90',      // 浅绿色
  onSuccess: '#006400',
  successContainer: '#F0FFF0',
  onSuccessContainer: '#006400',

  // 警告色（自定义）
  warning: '#FFE4B5',      // 桃色
  onWarning: '#FF8C00',
  warningContainer: '#FFF8DC',
  onWarningContainer: '#FF8C00',

  // 特殊色彩
  heart: '#FF69B4',        // 热粉色
  star: '#FFD700',         // 金色
  coin: '#FFA500',         // 橙色
};

export const theme = {
  ...MD3LightTheme,
  colors: {
    ...MD3LightTheme.colors,
    ...colors,
  },
  fonts: {
    ...MD3LightTheme.fonts,
    // 可以在这里自定义字体
  },
  roundness: 16, // 圆角半径
};

// 常用样式
export const commonStyles = {
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  centerContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.background,
  },
  card: {
    backgroundColor: colors.surface,
    borderRadius: 16,
    padding: 16,
    margin: 8,
    elevation: 2,
    shadowColor: colors.outline,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  button: {
    borderRadius: 24,
    paddingVertical: 8,
  },
  input: {
    backgroundColor: colors.surfaceVariant,
    borderRadius: 12,
    marginVertical: 8,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: colors.onBackground,
    textAlign: 'center',
    marginVertical: 16,
  },
  subtitle: {
    fontSize: 18,
    fontWeight: '600',
    color: colors.onBackground,
    marginVertical: 8,
  },
  text: {
    fontSize: 16,
    color: colors.onBackground,
    lineHeight: 24,
  },
  caption: {
    fontSize: 14,
    color: colors.onSurfaceVariant,
  },
  // 积分相关样式
  pointsContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.primaryContainer,
    borderRadius: 20,
    paddingHorizontal: 12,
    paddingVertical: 6,
  },
  pointsText: {
    fontSize: 16,
    fontWeight: 'bold',
    color: colors.onPrimaryContainer,
    marginLeft: 4,
  },
  // 情侣相关样式
  coupleCard: {
    backgroundColor: colors.secondaryContainer,
    borderRadius: 16,
    padding: 16,
    margin: 8,
    alignItems: 'center',
  },
  heartIcon: {
    color: colors.heart,
  },
};
