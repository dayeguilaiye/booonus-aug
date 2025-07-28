#!/bin/bash

# Flutter 国内镜像源配置脚本
# 解决在中国大陆网络环境下Flutter编译慢的问题

echo "🌏 配置Flutter国内镜像源..."

# 设置Flutter镜像源环境变量
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 显示当前配置
echo "✅ Flutter镜像源配置完成："
echo "   PUB_HOSTED_URL=$PUB_HOSTED_URL"
echo "   FLUTTER_STORAGE_BASE_URL=$FLUTTER_STORAGE_BASE_URL"

# 清理之前的构建缓存
echo "🧹 清理构建缓存..."
flutter clean

# 清理Gradle缓存
echo "🧹 清理Gradle缓存..."
cd android
./gradlew clean
cd ..

# 重新获取依赖
echo "📦 重新获取依赖..."
flutter pub get

echo "🎉 配置完成！现在可以尝试编译了。"
echo ""
echo "💡 使用方法："
echo "   source ./setup_china_mirrors.sh  # 设置环境变量"
echo "   flutter run                      # 运行项目"
echo ""
echo "或者直接运行："
echo "   ./run.sh                         # 使用配置好的运行脚本"
echo ""
echo "⚠️  如果遇到 NDK 相关错误，运行："
echo "   chmod +x fix_ndk_issue.sh && ./fix_ndk_issue.sh"
