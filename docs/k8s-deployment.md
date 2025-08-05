# Kubernetes 自动部署指南

本指南将帮你设置GitHub Actions自动部署到k3s集群。

## 前置条件

- 运行中的k3s集群
- kubectl已配置并能访问集群
- GitHub仓库的管理员权限

## 步骤1: 创建ServiceAccount和RBAC

在你的k3s集群上执行以下命令：

```bash
# 应用RBAC配置
kubectl apply -f k8s/github-actions-rbac.yaml

# 验证ServiceAccount创建成功
kubectl get serviceaccount github-actions -n default
kubectl get secret github-actions-token -n default
```

## 步骤2: 生成kubeconfig

运行脚本生成专用的kubeconfig：

```bash
# 确保脚本有执行权限
chmod +x scripts/generate-kubeconfig.sh

# 生成kubeconfig
./scripts/generate-kubeconfig.sh
```

脚本会生成 `github-actions-kubeconfig.yaml` 文件。

## 步骤3: 配置GitHub Secrets

1. 将kubeconfig编码为base64：
```bash
cat github-actions-kubeconfig.yaml | base64 -w 0
```

2. 在GitHub仓库中添加以下Secrets：
   - 进入仓库 → Settings → Secrets and variables → Actions
   - 添加以下Repository secrets：

| Secret名称 | 值 | 说明 |
|-----------|---|------|
| `KUBE_CONFIG_DATA` | 上面base64命令的输出 | k8s集群访问配置 |

## 步骤4: 修改部署配置

编辑 `k8s/backend-deployment.yaml`，确保镜像地址正确：

```yaml
# 修改为你的实际镜像地址
image: ghcr.io/YOUR_USERNAME/YOUR_REPO/backend:latest
```

如果需要外部访问，修改Ingress配置：

```yaml
# 修改为你的域名
host: booonus-api.your-domain.com
```

## 步骤5: 测试部署

1. 推送代码到main分支触发构建：
```bash
git add .
git commit -m "feat: add k8s auto deployment"
git push origin main
```

2. 在GitHub Actions页面查看构建和部署状态

3. 验证部署：
```bash
# 检查pods状态
kubectl get pods -l app=booonus-backend -n default

# 检查服务状态
kubectl get services -l app=booonus-backend -n default

# 查看部署日志
kubectl logs -l app=booonus-backend -n default --tail=50
```

## 步骤6: 验证健康检查

```bash
# 端口转发测试
kubectl port-forward service/booonus-backend-service 8080:80 -n default

# 在另一个终端测试健康检查
curl http://localhost:8080/api/v1/health
```

应该返回：
```json
{
  "status": "healthy",
  "service": "booonus-backend"
}
```

## 故障排除

### 1. 权限问题
```bash
# 检查ServiceAccount权限
kubectl auth can-i get deployments --as=system:serviceaccount:default:github-actions

# 查看RBAC配置
kubectl describe clusterrolebinding github-actions-deployer
```

### 2. 镜像拉取失败
```bash
# 检查镜像是否存在
docker pull ghcr.io/YOUR_USERNAME/YOUR_REPO/backend:latest

# 检查pod事件
kubectl describe pod POD_NAME -n default
```

### 3. 健康检查失败
```bash
# 查看pod日志
kubectl logs -l app=booonus-backend -n default

# 检查端口配置
kubectl get service booonus-backend-service -n default -o yaml
```

### 4. 部署超时
```bash
# 检查deployment状态
kubectl rollout status deployment/booonus-backend -n default

# 查看deployment事件
kubectl describe deployment booonus-backend -n default
```

## 安全建议

1. **定期轮换ServiceAccount token**：
```bash
# 删除旧token
kubectl delete secret github-actions-token -n default

# 重新应用RBAC配置
kubectl apply -f k8s/github-actions-rbac.yaml

# 重新生成kubeconfig
./scripts/generate-kubeconfig.sh
```

2. **限制权限范围**：
   - 只给予必要的权限
   - 考虑使用namespace隔离

3. **监控部署活动**：
   - 启用k8s审计日志
   - 监控deployment变更

## 清理

如果需要清理资源：

```bash
# 删除deployment和service
kubectl delete -f k8s/backend-deployment.yaml

# 删除RBAC资源
kubectl delete -f k8s/github-actions-rbac.yaml

# 删除本地kubeconfig文件
rm github-actions-kubeconfig.yaml
```
