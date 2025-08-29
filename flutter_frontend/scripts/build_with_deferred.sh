#!/bin/bash

# Flutter Web 延迟加载构建脚本
# 自动化构建和验证延迟加载配置

set -e  # 遇到错误时退出

echo "🚀 开始构建 Flutter Web 应用（延迟加载模式）"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查 Flutter 环境
echo -e "${BLUE}📋 检查 Flutter 环境...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter 未安装或不在 PATH 中${NC}"
    exit 1
fi

flutter --version

# 清理之前的构建
echo -e "${BLUE}🧹 清理之前的构建...${NC}"
flutter clean
rm -rf build/

# 获取依赖
echo -e "${BLUE}📦 获取依赖...${NC}"
flutter pub get

# 分析代码
#echo -e "${BLUE}🔍 分析代码...${NC}"
#flutter analyze --no-fatal-infos

# 运行测试（如果存在）
#if [ -d "test" ] && [ "$(ls -A test)" ]; then
#    echo -e "${BLUE}🧪 运行测试...${NC}"
#    flutter test
#fi

# 构建 Web 应用
echo -e "${BLUE}🏗️  构建 Web 应用...${NC}"
flutter build web \
    --release \
    --base-href /web/ \
    --source-maps

# 检查构建结果
echo -e "${BLUE}📊 分析构建结果...${NC}"
BUILD_DIR="build/web"

if [ ! -d "$BUILD_DIR" ]; then
    echo -e "${RED}❌ 构建失败：找不到构建目录${NC}"
    exit 1
fi

# 统计文件大小
echo -e "${GREEN}📈 构建统计：${NC}"
echo "构建目录: $BUILD_DIR"

# 主要文件大小
MAIN_JS=$(find $BUILD_DIR -name "main.dart.js" -o -name "main.dart.*.js" | head -1)
if [ -f "$MAIN_JS" ]; then
    MAIN_SIZE=$(du -h "$MAIN_JS" | cut -f1)
    echo "主 JS 文件大小: $MAIN_SIZE"
fi

# 延迟加载文件
DEFERRED_COUNT=$(find $BUILD_DIR -name "*.part.js" | wc -l)
echo "延迟加载文件数量: $DEFERRED_COUNT"

if [ $DEFERRED_COUNT -gt 0 ]; then
    echo -e "${GREEN}✅ 延迟加载文件已生成：${NC}"
    find $BUILD_DIR -name "*.part.js" -exec basename {} \; | sort
else
    echo -e "${YELLOW}⚠️  未检测到延迟加载文件，可能需要检查配置${NC}"
fi

# 总构建大小
TOTAL_SIZE=$(du -sh $BUILD_DIR | cut -f1)
echo "总构建大小: $TOTAL_SIZE"

# 生成部署信息
echo -e "${BLUE}📝 生成部署信息...${NC}"
cat > $BUILD_DIR/build-info.json << EOF
{
  "buildTime": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "flutterVersion": "$(flutter --version | head -1)",
  "deferredComponents": $DEFERRED_COUNT,
  "totalSize": "$TOTAL_SIZE"
}
EOF

# 验证关键文件
echo -e "${BLUE}🔍 验证关键文件...${NC}"
REQUIRED_FILES=("index.html" "flutter.js" "flutter_service_worker.js")

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$BUILD_DIR/$file" ]; then
        echo -e "${GREEN}✅ $file${NC}"
    else
        echo -e "${RED}❌ 缺少 $file${NC}"
        exit 1
    fi
done

# 检查 WASM 文件（如果启用）
if [ -f "$BUILD_DIR/main.dart.wasm" ]; then
    WASM_SIZE=$(du -h "$BUILD_DIR/main.dart.wasm" | cut -f1)
    echo -e "${GREEN}✅ WASM 文件: $WASM_SIZE${NC}"
fi

# 生成性能报告
echo -e "${BLUE}📊 生成性能报告...${NC}"
cat > $BUILD_DIR/performance-report.md << EOF
# 构建性能报告

## 构建信息
- 构建时间: $(date)
- Flutter 版本: $(flutter --version | head -1)
- 构建模式: Release

## 文件统计
- 延迟加载组件数量: $DEFERRED_COUNT
- 总构建大小: $TOTAL_SIZE
- 主 JS 文件大小: ${MAIN_SIZE:-"未知"}

## 延迟加载文件
$(find $BUILD_DIR -name "*.part.js" -exec echo "- {}" \; | sed 's|'$BUILD_DIR'/||g')

## 优化建议
1. 监控首屏加载时间
2. 根据用户行为调整预加载策略
3. 定期检查组件大小和加载性能
EOF

echo -e "${GREEN}🎉 构建完成！${NC}"
echo -e "${GREEN}📁 构建文件位于: $BUILD_DIR${NC}"
echo -e "${GREEN}📊 性能报告: $BUILD_DIR/performance-report.md${NC}"

# 提供下一步建议
echo -e "${YELLOW}💡 下一步：${NC}"
echo "1. 测试构建结果: cd $BUILD_DIR && python3 -m http.server 8000"
echo "2. 检查延迟加载: 打开浏览器开发者工具查看网络请求"
echo "3. 部署到服务器: 将 $BUILD_DIR 内容上传到 Web 服务器"

exit 0
