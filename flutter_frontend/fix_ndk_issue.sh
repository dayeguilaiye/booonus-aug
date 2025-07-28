#!/bin/bash

# NDK 问题修复脚本
# 解决 "NDK did not have a source.properties file" 错误

echo "🔧 修复 Android NDK 问题..."

# 检查当前NDK状态
echo "📋 检查当前NDK状态..."
NDK_PATH="/Users/ziyuanhe/Library/Android/sdk/ndk"

if [ -d "$NDK_PATH" ]; then
    echo "NDK 目录存在: $NDK_PATH"
    ls -la "$NDK_PATH"
    
    # 检查是否有完整的NDK安装
    for ndk_dir in "$NDK_PATH"/*; do
        if [ -d "$ndk_dir" ]; then
            echo "检查 NDK 目录: $ndk_dir"
            if [ -f "$ndk_dir/source.properties" ]; then
                echo "✅ 找到完整的NDK: $ndk_dir"
                cat "$ndk_dir/source.properties"
            else
                echo "❌ NDK 不完整: $ndk_dir (缺少 source.properties)"
            fi
        fi
    done
else
    echo "❌ NDK 目录不存在: $NDK_PATH"
fi

echo ""
echo "🛠️ 解决方案："
echo "1. 使用 Android Studio SDK Manager 重新安装 NDK"
echo "2. 或者使用命令行工具安装："
echo "   sdkmanager --install 'ndk;25.1.8937393'"
echo "3. 或者暂时禁用 NDK（已在 build.gradle.kts 中注释）"

echo ""
echo "💡 当前已暂时禁用 NDK 版本检查，尝试编译："
echo "   flutter clean"
echo "   flutter pub get" 
echo "   flutter run"

echo ""
echo "如果项目不需要 NDK（大多数 Flutter 项目不需要），"
echo "当前的配置应该可以正常工作。"
