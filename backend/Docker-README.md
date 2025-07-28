# Booonus Backend Docker 部署指南

## 文件说明

- `Dockerfile`: Docker 镜像构建文件
- `build.sh`: 自动化构建和推送脚本
- `docker-compose.yml`: 本地开发和部署配置
- `.dockerignore`: Docker 构建时忽略的文件

## 快速开始

### 1. 构建镜像

```bash
# 基本构建
./build.sh

# 构建并推送到 Docker Hub
./build.sh latest --push

# 构建特定版本并推送（不使用缓存）
./build.sh v1.0.0 --push --no-cache
```

### 2. 使用 Docker Compose 运行

```bash
# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 3. 直接运行 Docker 容器

```bash
# 基本运行
docker run -d -p 8080:8080 --name booonus-backend dayeguilaiye/booonus-backend:latest

# 自定义端口
docker run -d -p 3000:3000 -e PORT=3000 --name booonus-backend dayeguilaiye/booonus-backend:latest

# 挂载数据卷（持久化数据）
docker run -d -p 8080:8080 \
  -v $(pwd)/database:/root/database \
  -v $(pwd)/logs:/root/logs \
  --name booonus-backend \
  dayeguilaiye/booonus-backend:latest
```

## 环境变量

- `PORT`: 服务端口（默认: 8080）
- `GIN_MODE`: Gin 运行模式（默认: release）

## 数据持久化

容器内的重要目录：
- `/root/database/`: SQLite 数据库文件
- `/root/logs/`: 应用日志文件

建议在生产环境中挂载这些目录到宿主机，确保数据持久化。

## 镜像信息

- **Docker Hub**: `dayeguilaiye/booonus-backend`
- **基础镜像**: `golang:1.21-alpine` (构建阶段) + `alpine:latest` (运行阶段)
- **暴露端口**: 8080

## 常用命令

```bash
# 查看容器状态
docker ps

# 查看容器日志
docker logs booonus-backend

# 进入容器
docker exec -it booonus-backend sh

# 停止容器
docker stop booonus-backend

# 删除容器
docker rm booonus-backend

# 删除镜像
docker rmi dayeguilaiye/booonus-backend:latest
```

## 故障排除

1. **构建失败**: 检查 Go 版本和依赖是否正确
2. **容器启动失败**: 检查端口是否被占用
3. **数据库问题**: 确保数据库文件权限正确
4. **推送失败**: 确保已登录 Docker Hub (`docker login`)

## 生产部署建议

1. 使用具体的版本标签而不是 `latest`
2. 配置健康检查
3. 设置资源限制
4. 使用 Docker Swarm 或 Kubernetes 进行编排
5. 配置日志收集和监控
