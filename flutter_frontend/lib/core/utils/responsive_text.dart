import 'package:flutter/material.dart';
import 'platform_utils.dart';

/// 响应式文本工具类，确保跨平台一致的文本显示
class ResponsiveText {
  /// 获取屏幕宽度
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// 获取屏幕高度
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// 获取文本缩放因子
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0);
  }

  /// 获取设备像素比
  static double getDevicePixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  /// 根据屏幕宽度计算响应式字体大小
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = getScreenWidth(context);
    final textScaleFactor = getTextScaleFactor(context);
    
    // 基准屏幕宽度 (iPhone 14 Pro: 393pt)
    const double baseScreenWidth = 393.0;
    
    // 计算缩放比例
    double scaleFactor = screenWidth / baseScreenWidth;
    
    // 限制缩放范围，避免过大或过小
    scaleFactor = scaleFactor.clamp(0.8, 1.3);
    
    // 考虑系统文本缩放设置
    double adjustedFontSize = baseFontSize * scaleFactor;
    
    // 如果系统文本缩放过大，适当减小字体以避免溢出
    if (textScaleFactor > 1.2) {
      adjustedFontSize = adjustedFontSize / (textScaleFactor * 0.8);
    }
    
    return adjustedFontSize;
  }

  /// 获取平台特定的字体系列
  static String? getPlatformFontFamily() {
    return PlatformUtils.platformFontFamily;
  }

  /// 创建响应式文本样式
  static TextStyle createResponsiveTextStyle(
    BuildContext context, {
    required double baseFontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontSize: getResponsiveFontSize(context, baseFontSize),
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontFamily: getPlatformFontFamily(),
    );
  }

  /// 计算文本宽度
  static double calculateTextWidth(
    String text,
    TextStyle style,
    BuildContext context,
  ) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.of(context).textScaler,
    );
    textPainter.layout();
    return textPainter.width;
  }

  /// 检查文本是否会溢出指定宽度
  static bool willTextOverflow(
    String text,
    TextStyle style,
    double maxWidth,
    BuildContext context,
  ) {
    final textWidth = calculateTextWidth(text, style, context);
    return textWidth > maxWidth;
  }

  /// 自动调整字体大小以适应容器宽度
  static TextStyle autoFitTextStyle(
    BuildContext context, {
    required String text,
    required double maxWidth,
    required double baseFontSize,
    FontWeight? fontWeight,
    Color? color,
    double minFontSize = 10.0,
  }) {
    double fontSize = getResponsiveFontSize(context, baseFontSize);
    
    TextStyle style = createResponsiveTextStyle(
      context,
      baseFontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );

    // 如果文本溢出，逐步减小字体大小
    while (willTextOverflow(text, style, maxWidth, context) && fontSize > minFontSize) {
      fontSize -= 0.5;
      style = createResponsiveTextStyle(
        context,
        baseFontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }

    return style;
  }
}

/// 响应式文本组件
class ResponsiveTextWidget extends StatelessWidget {
  final String text;
  final double baseFontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? letterSpacing;
  final double? height;

  const ResponsiveTextWidget(
    this.text, {
    super.key,
    required this.baseFontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: ResponsiveText.createResponsiveTextStyle(
        context,
        baseFontSize: baseFontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// 自适应文本组件 - 自动调整字体大小以适应容器
class AutoFitText extends StatelessWidget {
  final String text;
  final double baseFontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final double minFontSize;

  const AutoFitText(
    this.text, {
    super.key,
    required this.baseFontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.minFontSize = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = ResponsiveText.autoFitTextStyle(
          context,
          text: text,
          maxWidth: constraints.maxWidth,
          baseFontSize: baseFontSize,
          fontWeight: fontWeight,
          color: color,
          minFontSize: minFontSize,
        );

        return Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
