package logger

import (
	"os"
	"path/filepath"

	"github.com/sirupsen/logrus"
)

var log *logrus.Logger

// Init 初始化日志系统
func Init() {
	log = logrus.New()

	// 设置日志格式
	log.SetFormatter(&logrus.TextFormatter{
		FullTimestamp: true,
		TimestampFormat: "2006-01-02 15:04:05",
	})

	// 确保日志目录存在
	logDir := "logs"
	if err := os.MkdirAll(logDir, 0755); err != nil {
		log.Fatal("Failed to create log directory:", err)
	}

	// 创建日志文件
	logFile, err := os.OpenFile(
		filepath.Join(logDir, "app.log"),
		os.O_CREATE|os.O_WRONLY|os.O_APPEND,
		0666,
	)
	if err != nil {
		log.Fatal("Failed to open log file:", err)
	}

	// 同时输出到文件和控制台
	log.SetOutput(logFile)
	log.SetLevel(logrus.InfoLevel)
}

// Info 记录信息日志
func Info(msg string) {
	log.Info(msg)
}

// Error 记录错误日志
func Error(msg string) {
	log.Error(msg)
}

// Debug 记录调试日志
func Debug(msg string) {
	log.Debug(msg)
}

// Warn 记录警告日志
func Warn(msg string) {
	log.Warn(msg)
}

// Fatal 记录致命错误日志并退出程序
func Fatal(msg string) {
	log.Fatal(msg)
}
