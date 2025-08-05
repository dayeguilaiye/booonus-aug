#!/bin/bash

# 生成GitHub Actions专用的kubeconfig文件
# 使用方法: ./generate-kubeconfig.sh

set -e

NAMESPACE="default"
SERVICE_ACCOUNT="github-actions"
SECRET_NAME="github-actions-token"
CONTEXT_NAME="github-actions-context"

echo "🚀 开始生成GitHub Actions kubeconfig..."

# 1. 应用RBAC配置
echo "📝 应用RBAC配置..."
kubectl apply -f k8s/github-actions-rbac.yaml

# 2. 等待Secret创建
echo "⏳ 等待Secret创建..."
kubectl wait --for=condition=Ready secret/${SECRET_NAME} -n ${NAMESPACE} --timeout=60s

# 3. 获取必要信息
echo "🔍 获取集群信息..."

# 获取集群信息
CLUSTER_NAME=$(kubectl config current-context)
CLUSTER_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CLUSTER_CA=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o jsonpath='{.data.ca\.crt}')

# 获取token
TOKEN=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o jsonpath='{.data.token}' | base64 -d)

echo "📋 集群信息:"
echo "  - 集群名称: ${CLUSTER_NAME}"
echo "  - 集群地址: ${CLUSTER_SERVER}"
echo "  - Namespace: ${NAMESPACE}"
echo "  - ServiceAccount: ${SERVICE_ACCOUNT}"

# 4. 生成kubeconfig
echo "🔧 生成kubeconfig文件..."

cat > github-actions-kubeconfig.yaml << EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: ${CLUSTER_CA}
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
echo "2. 在GitHub仓库设置中添加以下Secrets:"
echo "   - KUBE_CONFIG_DATA: (上面命令的输出)"
echo "   - DOCKER_REGISTRY: (你的Docker镜像仓库地址)"
echo "   - DOCKER_USERNAME: (Docker仓库用户名)"
echo "   - DOCKER_PASSWORD: (Docker仓库密码)"
echo ""
echo "3. 测试kubeconfig:"
echo "   export KUBECONFIG=./github-actions-kubeconfig.yaml"
echo "   kubectl get pods"
echo ""
echo "⚠️  安全提醒:"
echo "   - 请妥善保管生成的kubeconfig文件"
echo "   - 建议定期轮换ServiceAccount token"
echo "   - 删除本地kubeconfig文件: rm github-actions-kubeconfig.yaml"
