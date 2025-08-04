#!/bin/bash

# 构建和推送 Docker 镜像的脚本
# 使用方法:
#   ./build.sh [tag] [--push] [--no-cache]
# 示例:
#   ./build.sh latest --push
#   ./build.sh v1.0.0 --push --no-cache

set -e

alias docker="sudo docker"

# 配置
DOCKER_USERNAME="dayeguilaiye"
IMAGE_NAME="booonus-backend"
DEFAULT_TAG="latest"

# 解析命令行参数
TAG="$DEFAULT_TAG"
PUSH=false
NO_CACHE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --push)
            PUSH=true
            shift
            ;;
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        -*)
            echo "未知选项: $1"
            exit 1
            ;;
        *)
            TAG="$1"
            shift
            ;;
    esac
done

FULL_IMAGE_NAME="$DOCKER_USERNAME/$IMAGE_NAME:$TAG"

echo "🚀 开始构建 Docker 镜像..."
echo "镜像名称: $FULL_IMAGE_NAME"
echo "推送模式: $([ "$PUSH" = true ] && echo "是" || echo "否")"
echo "缓存模式: $([ -n "$NO_CACHE" ] && echo "禁用缓存" || echo "使用缓存")"

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker 未运行，请先启动 Docker"
    exit 1
fi

# 构建镜像
echo "📦 构建镜像中..."
docker build $NO_CACHE -t $FULL_IMAGE_NAME .

echo "✅ 镜像构建完成!"

# 如果指定了 --push 参数，直接推送
if [ "$PUSH" = true ]; then
    echo "🔐 登录 Docker Hub..."
    docker login

    echo "📤 推送镜像到 Docker Hub..."
    docker push $FULL_IMAGE_NAME

    echo "🎉 镜像推送完成!"
    echo "镜像地址: https://hub.docker.com/r/$DOCKER_USERNAME/$IMAGE_NAME"
    echo "拉取命令: docker pull $FULL_IMAGE_NAME"
else
    # 询问是否推送到 Docker Hub
    read -p "是否要推送镜像到 Docker Hub? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔐 登录 Docker Hub..."
        docker login

        echo "📤 推送镜像到 Docker Hub..."
        docker push $FULL_IMAGE_NAME

        echo "🎉 镜像推送完成!"
        echo "镜像地址: https://hub.docker.com/r/$DOCKER_USERNAME/$IMAGE_NAME"
        echo "拉取命令: docker pull $FULL_IMAGE_NAME"
    else
        echo "⏭️  跳过推送步骤"
    fi
fi

echo "🏁 构建脚本执行完成!"

# 显示本地镜像信息
echo ""
echo "📋 本地镜像信息:"
docker images | grep $IMAGE_NAME || echo "未找到相关镜像"

# 显示运行命令示例
echo ""
echo "🔧 运行命令示例:"
echo "docker run -d -p 8080:8080 --name booonus-backend $FULL_IMAGE_NAME"
echo "docker run -d -p 8080:8080 -e PORT=3000 --name booonus-backend $FULL_IMAGE_NAME"
