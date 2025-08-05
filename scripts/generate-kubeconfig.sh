#!/bin/bash

# 生成GitHub Actions专用的kubeconfig文件
# 使用方法: ./generate-kubeconfig.sh <CLUSTER_SERVER>
# 示例: ./generate-kubeconfig.sh https://43.136.135.35:6443

set -e

# 检查参数
if [ $# -ne 1 ]; then
    echo "❌ 错误: 缺少集群地址参数"
    echo ""
    echo "使用方法: $0 <CLUSTER_SERVER>"
    echo "示例: $0 https://43.136.135.35:6443"
    echo ""
    echo "说明:"
    echo "  CLUSTER_SERVER - k3s集群的外网访问地址"
    echo "  格式: https://IP:PORT 或 https://DOMAIN:PORT"
    exit 1
fi

CLUSTER_SERVER="$1"

# 验证集群地址格式
if [[ ! "$CLUSTER_SERVER" =~ ^https?:// ]]; then
    echo "❌ 错误: 集群地址必须以 http:// 或 https:// 开头"
    echo "示例: https://x.x.x.x:6443"
    exit 1
fi

NAMESPACE="default"
SERVICE_ACCOUNT="github-actions"
SECRET_NAME="github-actions-token"
CONTEXT_NAME="github-actions-context"

echo "🚀 开始生成GitHub Actions kubeconfig..."
echo "📋 配置信息:"
echo "  - 集群地址: ${CLUSTER_SERVER}"
echo "  - Namespace: ${NAMESPACE}"
echo "  - ServiceAccount: ${SERVICE_ACCOUNT}"

# 1. 应用RBAC配置
echo "📝 应用RBAC配置..."
kubectl apply -f k8s/github-actions-rbac.yaml

# 2. 等待Secret创建
echo "⏳ 等待Secret创建..."
kubectl wait --for=condition=Ready secret/${SECRET_NAME} -n ${NAMESPACE} --timeout=60s

# 3. 获取必要信息
echo "🔍 获取集群信息..."

# 获取集群名称（用于kubeconfig中的cluster名称）
CLUSTER_NAME=$(kubectl config current-context)

# 获取token
TOKEN=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o jsonpath='{.data.token}' | base64 -d)

echo "📋 获取到的信息:"
echo "  - 集群名称: ${CLUSTER_NAME}"
echo "  - Token长度: ${#TOKEN} 字符"

# 4. 生成kubeconfig
echo "🔧 生成kubeconfig文件..."

cat > github-actions-kubeconfig.yaml << EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: ${CLUSTER_SERVER}
    insecure-skip-tls-verify: true
  name: ${CLUSTER_NAME}
contexts:
- context:
    cluster: ${CLUSTER_NAME}
    namespace: ${NAMESPACE}
    user: ${SERVICE_ACCOUNT}
  name: ${CONTEXT_NAME}
current-context: ${CONTEXT_NAME}
users:
- name: ${SERVICE_ACCOUNT}
  user:
    token: ${TOKEN}
EOF

echo "✅ kubeconfig文件已生成: github-actions-kubeconfig.yaml"
echo ""
echo "🔐 接下来的步骤:"
echo "1. 将kubeconfig内容复制到GitHub Secrets:"
echo "   cat github-actions-kubeconfig.yaml | base64 -w 0"
echo ""
echo "2. 在GitHub仓库设置中更新KUBE_CONFIG_DATA Secret:"
echo "   - 进入仓库 → Settings → Secrets and variables → Actions"
echo "   - 更新 KUBE_CONFIG_DATA 为上面命令的输出"
echo ""
echo "3. 测试kubeconfig:"
echo "   export KUBECONFIG=./github-actions-kubeconfig.yaml"
echo "   kubectl get pods"
echo ""
echo "📊 配置摘要:"
echo "   - 集群地址: ${CLUSTER_SERVER}"
echo "   - 跳过TLS验证: 是 (用于外网IP访问)"
echo "   - ServiceAccount: ${SERVICE_ACCOUNT}"
echo "   - Namespace: ${NAMESPACE}"
echo ""
echo "⚠️  重要说明:"
echo "   - 此kubeconfig跳过TLS验证以支持外部IP访问"
echo "   - 仅用于GitHub Actions自动部署"
echo "   - 生产环境建议配置正确的TLS证书"
echo ""
echo "🔒 安全提醒:"
echo "   - 请妥善保管生成的kubeconfig文件"
echo "   - 建议定期轮换ServiceAccount token"
echo "   - 删除本地kubeconfig文件: rm github-actions-kubeconfig.yaml"
