# GitHub Actions 工作流

## Backend Docker 镜像构建

### 工作流文件：`backend-build.yml`

这个工作流会在以下情况下自动触发：
- 当 `backend/` 目录中的任何文件发生变化时
- 推送到 `main` 或 `develop` 分支
- 创建针对 `main` 或 `develop` 分支的 Pull Request

### 功能特性

1. **自动触发**：只有当 backend 代码发生变化时才会构建
2. **多平台支持**：构建 `linux/amd64` 和 `linux/arm64` 架构的镜像
3. **智能标签**：自动生成多种标签格式
4. **缓存优化**：使用 GitHub Actions 缓存加速构建
5. **安全认证**：使用 GitHub Token 自动登录到 GitHub Container Registry

### 镜像标签规则

- `main` 分支：`latest` + `main` + `main-<commit-sha>`
- `develop` 分支：`develop` + `develop-<commit-sha>`
- Pull Request：`pr-<pr-number>`

### 镜像位置

构建的镜像会推送到：
```
ghcr.io/<your-username>/<repository-name>/backend
```

### 使用构建的镜像

```bash
# 拉取最新版本
docker pull ghcr.io/<your-username>/<repository-name>/backend:latest

# 运行容器
docker run -p 8080:8080 ghcr.io/<your-username>/<repository-name>/backend:latest
```

### 权限要求

工作流需要以下权限（已在配置中设置）：
- `contents: read` - 读取仓库内容
- `packages: write` - 推送到 GitHub Container Registry

### 故障排除

如果构建失败，请检查：
1. `backend/Dockerfile` 是否存在且语法正确
2. Go 代码是否能正常编译
3. 是否有足够的权限推送到 GitHub Container Registry

### 手动触发

你也可以在 GitHub 仓库的 Actions 页面手动触发这个工作流。
