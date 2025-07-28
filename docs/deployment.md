# Booonus 部署指南

## 系统要求

### 后端
- Go 1.21 或更高版本
- SQLite3

### 前端
- Node.js 16 或更高版本
- npm 或 yarn
- Expo CLI

## 后端部署

### 1. 安装依赖

```bash
cd backend
go mod tidy
```

### 2. 环境变量配置

创建 `.env` 文件（可选）：

```bash
# JWT密钥（生产环境请使用强密钥）
JWT_SECRET=your-super-secret-jwt-key-here

# 服务器端口
PORT=8080

# Gin模式（development/production）
GIN_MODE=release
```

### 3. 启动后端服务

```bash
# 开发模式
go run cmd/main.go

# 或者编译后运行
go build -o booonus-server cmd/main.go
./booonus-server
```

服务器将在 `http://localhost:8080` 启动。

### 4. 测试后端API

```bash
# 运行API测试脚本
./test_api.sh
```

## 前端部署

### 1. 安装依赖

```bash
cd frontend
npm install
```

### 2. 配置API地址

编辑 `src/services/api.js`，修改 `BASE_URL`：

```javascript
// 开发环境
const BASE_URL = 'http://localhost:8080/api/v1';

// 生产环境（替换为实际的服务器地址）
const BASE_URL = 'https://your-server.com/api/v1';
```

### 3. 启动开发服务器

```bash
# 启动Expo开发服务器
npm start

# 或者直接在特定平台启动
npm run ios     # iOS模拟器
npm run android # Android模拟器
npm run web     # Web浏览器
```

### 4. 在手机上测试

1. 安装 Expo Go 应用
2. 扫描终端中显示的二维码
3. 应用将在手机上启动

## 生产环境部署

### 后端生产部署

1. **编译应用**：
```bash
cd backend
CGO_ENABLED=1 go build -o booonus-server cmd/main.go
```

2. **使用systemd服务**（Linux）：
```ini
# /etc/systemd/system/booonus.service
[Unit]
Description=Booonus Backend Server
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/path/to/booonus/backend
ExecStart=/path/to/booonus/backend/booonus-server
Restart=always
Environment=GIN_MODE=release
Environment=JWT_SECRET=your-production-jwt-secret

[Install]
WantedBy=multi-user.target
```

3. **启动服务**：
```bash
sudo systemctl enable booonus
sudo systemctl start booonus
```

### 前端生产部署

1. **构建应用**：
```bash
cd frontend
expo build:android  # Android APK
expo build:ios      # iOS IPA
```

2. **发布到应用商店**：
   - 按照 Expo 文档发布到 Google Play Store 和 Apple App Store

## 数据库管理

### 备份数据库

```bash
# 备份SQLite数据库
cp backend/database/booonus.db backup/booonus_$(date +%Y%m%d_%H%M%S).db
```

### 查看数据库

```bash
# 使用sqlite3命令行工具
sqlite3 backend/database/booonus.db

# 查看所有表
.tables

# 查看用户数据
SELECT * FROM users;

# 退出
.quit
```

## 监控和日志

### 查看日志

```bash
# 查看应用日志
tail -f backend/logs/app.log

# 查看系统服务日志
sudo journalctl -u booonus -f
```

### 健康检查

创建健康检查脚本：

```bash
#!/bin/bash
# health_check.sh

response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/v1/health)

if [ $response -eq 200 ]; then
    echo "Service is healthy"
    exit 0
else
    echo "Service is unhealthy (HTTP $response)"
    exit 1
fi
```

## 故障排除

### 常见问题

1. **后端启动失败**：
   - 检查端口是否被占用：`lsof -i :8080`
   - 检查Go版本：`go version`
   - 查看错误日志

2. **前端连接失败**：
   - 确认后端服务正在运行
   - 检查API地址配置
   - 确认网络连接

3. **数据库问题**：
   - 检查数据库文件权限
   - 确认SQLite3已安装
   - 查看数据库日志

### 性能优化

1. **后端优化**：
   - 启用Gin的release模式
   - 配置适当的日志级别
   - 使用连接池

2. **前端优化**：
   - 启用生产构建
   - 压缩图片资源
   - 实现适当的缓存策略

## 安全建议

1. **JWT密钥**：使用强随机密钥
2. **HTTPS**：生产环境必须使用HTTPS
3. **防火墙**：只开放必要的端口
4. **定期备份**：设置自动备份计划
5. **更新依赖**：定期更新依赖包

## 扩展功能

### 添加新功能的步骤

1. **后端**：
   - 在 `models/` 中定义数据模型
   - 在 `api/handlers/` 中添加处理器
   - 在 `api/routes/` 中添加路由
   - 更新数据库迁移

2. **前端**：
   - 在 `src/services/` 中添加API调用
   - 在 `src/screens/` 中创建新页面
   - 更新导航配置
   - 添加相应的样式

### 推荐的扩展功能

- 推送通知
- 数据同步
- 主题切换
- 多语言支持
- 数据导出
- 社交分享
