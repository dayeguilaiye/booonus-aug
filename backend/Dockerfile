# 使用官方 Go 镜像作为构建环境
FROM golang:1.24.5-alpine AS builder

# 设置工作目录
WORKDIR /app

# 复制 go mod 文件
COPY go.mod go.sum ./

# 添加 go mod 代理
RUN go env -w GOPROXY=https://goproxy.cn
RUN go env -w GOARCH=amd64

# 下载依赖
RUN go mod download

# 复制源代码
COPY . .

# 构建应用
RUN CGO_ENABLED=0 GOOS=linux go build -o main ./cmd/main.go

# 使用轻量级的 alpine 镜像作为运行环境
FROM alpine:latest

# 安装运行时依赖
RUN apk --no-cache add ca-certificates sqlite

# 设置工作目录
WORKDIR /root/

# 从构建阶段复制二进制文件
COPY --from=builder /app/main .

# 创建必要的目录
RUN mkdir -p /root/database /root/logs

# 注意：数据库文件应该通过挂载卷或环境变量在运行时提供
# 不在构建时复制数据库文件，因为它们不应该包含在镜像中

# 设置环境变量
ENV GIN_MODE=release
ENV PORT=8080

# 暴露端口
EXPOSE 8080

# 运行应用
CMD ["./main"]
