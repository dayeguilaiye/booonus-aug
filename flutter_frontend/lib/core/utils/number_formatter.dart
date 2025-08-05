/// 数字格式化工具类
class NumberFormatter {
  /// 格式化积分数字
  /// 规则：
  /// - 小于 10,000: 显示完整数字 (如: 1234)
  /// - 10,000 及以上: 显示为 xxk 格式 (如: 12k)
  static String formatPoints(int points) {
    if (points < 10000) {
      return points.toString();
    } else {
      // 转换为k格式，保留一位小数（如果需要）
      double kValue = points / 1000.0;
      
      // 如果是整数k，不显示小数点
      if (kValue == kValue.floor()) {
        return '${kValue.floor()}k';
      } else {
        // 保留一位小数
        return '${kValue.toStringAsFixed(1)}k';
      }
    }
  }

  /// 格式化大数字（通用）
  /// 支持 k (千), m (百万), b (十亿) 等单位
  static String formatLargeNumber(int number) {
    if (number < 1000) {
      return number.toString();
    } else if (number < 1000000) {
      double kValue = number / 1000.0;
      if (kValue == kValue.floor()) {
        return '${kValue.floor()}k';
      } else {
        return '${kValue.toStringAsFixed(1)}k';
      }
    } else if (number < 1000000000) {
      double mValue = number / 1000000.0;
      if (mValue == mValue.floor()) {
        return '${mValue.floor()}m';
      } else {
        return '${mValue.toStringAsFixed(1)}m';
      }
    } else {
      double bValue = number / 1000000000.0;
      if (bValue == bValue.floor()) {
        return '${bValue.floor()}b';
      } else {
        return '${bValue.toStringAsFixed(1)}b';
      }
    }
  }

  /// 格式化带千分位分隔符的数字
  static String formatWithCommas(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
  }

  /// 格式化价格（积分商店使用）
  static String formatPrice(int price) {
    return formatPoints(price);
  }

  /// 获取数字的完整显示（用于详情页面）
  static String formatFullNumber(int number) {
    return formatWithCommas(number);
  }
}

/// 数字格式化扩展方法
extension NumberFormatterExtension on int {
  /// 格式化为积分显示
  String get formattedPoints => NumberFormatter.formatPoints(this);
  
  /// 格式化为大数字显示
  String get formattedLarge => NumberFormatter.formatLargeNumber(this);
  
  /// 格式化为带逗号的完整数字
  String get formattedWithCommas => NumberFormatter.formatWithCommas(this);
  
  /// 格式化为价格显示
  String get formattedPrice => NumberFormatter.formatPrice(this);
  
  /// 格式化为完整数字显示
  String get formattedFull => NumberFormatter.formatFullNumber(this);
}
