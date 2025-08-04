# 使用官方 Go 镜像作为构建环境
FROM golang:1.24.5-alpine AS builder

# 设置工作目录
WORKDIR /app

# 复制 go mod 文件
COPY go.mod go.sum ./

# 添加 go mod 代理和构建优化
RUN go env -w GOPROXY=https://goproxy.cn,direct && \
    go env -w GOSUMDB=sum.golang.org && \
    go env -w CGO_ENABLED=0

# 下载依赖（利用 Docker 层缓存）
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

# 复制源代码
COPY . .

# 构建应用（使用构建缓存和优化参数）
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    GOOS=linux go build -ldflags="-w -s" -o main ./cmd/main.go

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
