package main

import (
	"log"
	"os"

	"booonus-backend/api/routes"
	"booonus-backend/internal/database"
	"booonus-backend/pkg/logger"

	"github.com/gin-gonic/gin"
)

func main() {
	// 初始化日志
	logger.Init()
	
	// 初始化数据库
	if err := database.Init(); err != nil {
		log.Fatal("Failed to initialize database:", err)
	}
	
	// 设置Gin模式
	if os.Getenv("GIN_MODE") == "" {
		gin.SetMode(gin.DebugMode)
	}
	
	// 创建路由
	router := routes.SetupRoutes()
	
	// 启动服务器
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	
	logger.Info("Starting server on port " + port)
	if err := router.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
