#!/bin/bash

# Booonus 快速启动脚本

echo "🎀 欢迎使用 Booonus - 情侣积分管理应用 🎀"
echo ""

# 检查系统要求
check_requirements() {
    echo "📋 检查系统要求..."
    
    # 检查Go
    if ! command -v go &> /dev/null; then
        echo "❌ Go 未安装。请先安装 Go 1.21 或更高版本"
        echo "   下载地址: https://golang.org/dl/"
        exit 1
    fi
    
    GO_VERSION=$(go version | grep -o 'go[0-9]\+\.[0-9]\+' | sed 's/go//')
    echo "✅ Go 版本: $GO_VERSION"
    
    # 检查Node.js
    if ! command -v node &> /dev/null; then
        echo "❌ Node.js 未安装。请先安装 Node.js 16 或更高版本"
        echo "   下载地址: https://nodejs.org/"
        exit 1
    fi
    
    NODE_VERSION=$(node --version)
    echo "✅ Node.js 版本: $NODE_VERSION"
    
    # 检查npm
    if ! command -v npm &> /dev/null; then
        echo "❌ npm 未安装"
        exit 1
    fi
    
    NPM_VERSION=$(npm --version)
    echo "✅ npm 版本: $NPM_VERSION"
    
    echo ""
}

# 安装后端依赖
setup_backend() {
    echo "🔧 设置后端..."
    cd backend
    
    if [ ! -f "go.mod" ]; then
        echo "❌ go.mod 文件不存在"
        exit 1
    fi
    
    echo "📦 安装 Go 依赖..."
    go mod tidy
    
    if [ $? -ne 0 ]; then
        echo "❌ Go 依赖安装失败"
        exit 1
    fi
    
    echo "✅ 后端依赖安装完成"
    cd ..
    echo ""
}

# 安装前端依赖
setup_frontend() {
    echo "🔧 设置前端..."
    cd frontend
    
    if [ ! -f "package.json" ]; then
        echo "❌ package.json 文件不存在"
        exit 1
    fi
    
    echo "📦 安装 npm 依赖..."
    npm install
    
    if [ $? -ne 0 ]; then
        echo "❌ npm 依赖安装失败"
        exit 1
    fi
    
    # 检查是否安装了 Expo CLI
    if ! command -v expo &> /dev/null; then
        echo "📱 安装 Expo CLI..."
        npm install -g @expo/cli
    fi
    
    echo "✅ 前端依赖安装完成"
    cd ..
    echo ""
}

# 启动后端服务
start_backend() {
    echo "🚀 启动后端服务..."
    cd backend
    
    # 检查端口是否被占用
    if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null ; then
        echo "⚠️  端口 8080 已被占用，尝试终止现有进程..."
        lsof -ti:8080 | xargs kill -9 2>/dev/null || true
        sleep 2
    fi
    
    # 启动后端服务（后台运行）
    echo "🔄 启动 Go 服务器..."
    nohup go run cmd/main.go > ../logs/backend.log 2>&1 &
    BACKEND_PID=$!
    
    # 等待服务启动
    echo "⏳ 等待后端服务启动..."
    for i in {1..10}; do
        if curl -s http://localhost:8080/api/v1/health >/dev/null 2>&1; then
            echo "✅ 后端服务启动成功 (PID: $BACKEND_PID)"
            echo $BACKEND_PID > ../backend.pid
            break
        fi
        if [ $i -eq 10 ]; then
            echo "❌ 后端服务启动失败"
            exit 1
        fi
        sleep 2
    done
    
    cd ..
    echo ""
}

# 启动前端服务
start_frontend() {
    echo "📱 启动前端服务..."
    cd frontend
    
    echo "🔄 启动 Expo 开发服务器..."
    echo "📱 请在手机上安装 Expo Go 应用，然后扫描二维码"
    echo "🌐 或者在浏览器中打开 http://localhost:19006"
    echo ""
    echo "💡 提示："
    echo "   - 按 'a' 在 Android 模拟器中打开"
    echo "   - 按 'i' 在 iOS 模拟器中打开"
    echo "   - 按 'w' 在浏览器中打开"
    echo "   - 按 'r' 重新加载应用"
    echo "   - 按 'q' 退出"
    echo ""
    
    # 启动 Expo
    npx expo start --clear
    
    cd ..
}

# 停止服务
stop_services() {
    echo ""
    echo "🛑 停止服务..."
    
    # 停止后端服务
    if [ -f "backend.pid" ]; then
        BACKEND_PID=$(cat backend.pid)
        if kill -0 $BACKEND_PID 2>/dev/null; then
            kill $BACKEND_PID
            echo "✅ 后端服务已停止"
        fi
        rm backend.pid
    fi
    
    # 停止可能占用端口的进程
    lsof -ti:8080 | xargs kill -9 2>/dev/null || true
    lsof -ti:19000 | xargs kill -9 2>/dev/null || true
    lsof -ti:19001 | xargs kill -9 2>/dev/null || true
    lsof -ti:19002 | xargs kill -9 2>/dev/null || true
    lsof -ti:19006 | xargs kill -9 2>/dev/null || true
    
    echo "🎉 所有服务已停止"
}

# 创建日志目录
mkdir -p logs

# 设置信号处理
trap stop_services EXIT INT TERM

# 主流程
case "${1:-start}" in
    "start")
        check_requirements
        setup_backend
        setup_frontend
        start_backend
        start_frontend
        ;;
    "backend")
        check_requirements
        setup_backend
        start_backend
        echo "🎉 后端服务已启动在 http://localhost:8080"
        echo "📋 API 文档: docs/api.md"
        echo "🔍 查看日志: tail -f logs/backend.log"
        echo "⏹️  停止服务: kill $(cat backend.pid)"
        wait
        ;;
    "frontend")
        check_requirements
        setup_frontend
        cd frontend
        start_frontend
        ;;
    "test")
        echo "🧪 运行 API 测试..."
        cd backend
        if [ -f "test_api.sh" ]; then
            chmod +x test_api.sh
            ./test_api.sh
        else
            echo "❌ 测试脚本不存在"
            exit 1
        fi
        ;;
    "stop")
        stop_services
        ;;
    "help"|"-h"|"--help")
        echo "用法: $0 [命令]"
        echo ""
        echo "命令:"
        echo "  start     启动完整应用 (默认)"
        echo "  backend   仅启动后端服务"
        echo "  frontend  仅启动前端服务"
        echo "  test      运行 API 测试"
        echo "  stop      停止所有服务"
        echo "  help      显示此帮助信息"
        echo ""
        echo "示例:"
        echo "  $0              # 启动完整应用"
        echo "  $0 backend      # 仅启动后端"
        echo "  $0 test         # 运行测试"
        ;;
    *)
        echo "❌ 未知命令: $1"
        echo "使用 '$0 help' 查看可用命令"
        exit 1
        ;;
esac
