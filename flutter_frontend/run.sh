#!/bin/bash

# Booonus Flutter Frontend Run Script

# 配置国内镜像源环境变量
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

echo "🚀 Starting Booonus Flutter Frontend..."
echo "🌏 Using China mirrors for faster downloads..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    echo "Visit: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Check Flutter version
echo "📋 Flutter version:"
flutter --version

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Check for any issues
echo "🔍 Running Flutter doctor..."
flutter doctor

# Ask user which platform to run
echo ""
echo "🎯 Select platform to run:"
echo "1) Android"
echo "2) iOS"
echo "3) Web"
echo "4) Desktop (macOS)"
echo "5) Desktop (Windows)"
echo "6) Desktop (Linux)"

read -p "Enter your choice (1-6): " choice

case $choice in
    1)
        echo "🤖 Running on Android..."
        flutter run
        ;;
    2)
        echo "🍎 Running on iOS..."
        flutter run
        ;;
    3)
        echo "🌐 Running on Web..."
        flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8081
        ;;
    4)
        echo "🖥️ Running on macOS..."
        flutter run -d macos
        ;;
    5)
        echo "🖥️ Running on Windows..."
        flutter run -d windows
        ;;
    6)
        echo "🖥️ Running on Linux..."
        flutter run -d linux
        ;;
    *)
        echo "❌ Invalid choice. Running default (first available device)..."
        flutter run
        ;;
esac
