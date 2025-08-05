#!/bin/bash

# 修复k3s TLS证书问题
# 使k3s证书包含外部IP地址

set -e

EXTERNAL_IP="43.136.135.35"  # 你的外部IP
K3S_CONFIG_FILE="/etc/rancher/k3s/config.yaml"

echo "🔧 修复k3s TLS证书以支持外部IP访问..."

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请以root用户运行此脚本"
    echo "   sudo $0"
    exit 1
fi

# 备份现有配置
echo "📋 备份现有k3s配置..."
if [ -f "$K3S_CONFIG_FILE" ]; then
    cp "$K3S_CONFIG_FILE" "$K3S_CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
fi

# 创建k3s配置目录
mkdir -p /etc/rancher/k3s

# 创建或更新k3s配置
echo "📝 更新k3s配置..."
cat > "$K3S_CONFIG_FILE" << EOF
# k3s配置文件
# 包含外部IP的TLS证书配置

# TLS SAN (Subject Alternative Names)
tls-san:
  - "$EXTERNAL_IP"
  - "$(hostname -I | awk '{print $1}')"  # 内部IP
  - "127.0.0.1"
  - "localhost"
  - "$(hostname)"

# 集群配置
cluster-init: true
disable:
  - traefik  # 如果你使用其他ingress controller

# API服务器配置
kube-apiserver-arg:
  - "advertise-address=$EXTERNAL_IP"
  - "bind-address=0.0.0.0"
EOF

echo "✅ k3s配置已更新"

# 停止k3s服务
echo "🛑 停止k3s服务..."
systemctl stop k3s

# 删除旧的证书和数据
echo "🗑️  清理旧证书..."
rm -rf /var/lib/rancher/k3s/server/tls/
rm -rf /var/lib/rancher/k3s/server/cred/
rm -f /var/lib/rancher/k3s/server/token

# 重新启动k3s
echo "🚀 重新启动k3s..."
systemctl start k3s
systemctl enable k3s

# 等待k3s启动
echo "⏳ 等待k3s启动..."
sleep 30

# 检查k3s状态
echo "🔍 检查k3s状态..."
systemctl status k3s --no-pager

# 验证节点状态
echo "📊 验证集群状态..."
k3s kubectl get nodes

# 显示新的kubeconfig
echo "📋 新的kubeconfig位置: /etc/rancher/k3s/k3s.yaml"
echo ""
echo "🔧 接下来的步骤:"
echo "1. 重新生成GitHub Actions的kubeconfig:"
echo "   cd /path/to/your/project"
echo "   ./scripts/generate-kubeconfig.sh"
echo ""
echo "2. 更新GitHub Secrets中的KUBE_CONFIG_DATA"
echo ""
echo "3. 验证外部访问:"
echo "   kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml get nodes"
echo ""
echo "⚠️  注意: 所有现有的kubeconfig文件需要重新生成"
