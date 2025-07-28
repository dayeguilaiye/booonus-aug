package handlers

import (
	"net/http"
	"strconv"

	"booonus-backend/internal/auth"
	"booonus-backend/internal/database"
	"booonus-backend/models"
	"booonus-backend/pkg/logger"

	"github.com/gin-gonic/gin"
)

// RegisterRequest 注册请求结构
type RegisterRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required,min=6"`
}

// LoginRequest 登录请求结构
type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// Register 用户注册
func Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 检查用户名是否已存在
	var existingUser models.User
	err := database.DB.QueryRow("SELECT id FROM users WHERE username = ?", req.Username).Scan(&existingUser.ID)
	if err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Username already exists"})
		return
	}

	// 加密密码
	hashedPassword, err := auth.HashPassword(req.Password)
	if err != nil {
		logger.Error("Failed to hash password: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}

	// 创建用户
	result, err := database.DB.Exec(
		"INSERT INTO users (username, password, points) VALUES (?, ?, ?)",
		req.Username, hashedPassword, 0,
	)
	if err != nil {
		logger.Error("Failed to create user: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
		return
	}

	userID, _ := result.LastInsertId()
	
	// 生成token
	token, err := auth.GenerateToken(int(userID))
	if err != nil {
		logger.Error("Failed to generate token: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	logger.Info("User registered successfully: " + req.Username)
	c.JSON(http.StatusCreated, gin.H{
		"message": "User created successfully",
		"token":   token,
		"user": gin.H{
			"id":       userID,
			"username": req.Username,
			"points":   0,
		},
	})
}

// Login 用户登录
func Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 查找用户
	var user models.User
	err := database.DB.QueryRow(
		"SELECT id, username, password, points, couple_id FROM users WHERE username = ?",
		req.Username,
	).Scan(&user.ID, &user.Username, &user.Password, &user.Points, &user.CoupleID)
	
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid username or password"})
		return
	}

	// 验证密码
	if !auth.CheckPassword(req.Password, user.Password) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid username or password"})
		return
	}

	// 生成token
	token, err := auth.GenerateToken(user.ID)
	if err != nil {
		logger.Error("Failed to generate token: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	logger.Info("User logged in successfully: " + user.Username)
	c.JSON(http.StatusOK, gin.H{
		"message": "Login successful",
		"token":   token,
		"user": gin.H{
			"id":        user.ID,
			"username":  user.Username,
			"points":    user.Points,
			"couple_id": user.CoupleID,
		},
	})
}

// GetProfile 获取用户资料
func GetProfile(c *gin.Context) {
	userID := c.GetInt("user_id")

	var user models.User
	err := database.DB.QueryRow(
		"SELECT id, username, points, couple_id FROM users WHERE id = ?",
		userID,
	).Scan(&user.ID, &user.Username, &user.Points, &user.CoupleID)

	if err != nil {
		logger.Error("Failed to get user profile: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get profile"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"user": gin.H{
			"id":        user.ID,
			"username":  user.Username,
			"points":    user.Points,
			"couple_id": user.CoupleID,
		},
	})
}

// UpdateProfile 更新用户资料
func UpdateProfile(c *gin.Context) {
	userID := c.GetInt("user_id")
	
	var req struct {
		Username string `json:"username"`
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 检查用户名是否已被其他用户使用
	var existingUserID int
	err := database.DB.QueryRow("SELECT id FROM users WHERE username = ? AND id != ?", req.Username, userID).Scan(&existingUserID)
	if err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Username already exists"})
		return
	}

	// 更新用户名
	_, err = database.DB.Exec("UPDATE users SET username = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?", req.Username, userID)
	if err != nil {
		logger.Error("Failed to update profile: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update profile"})
		return
	}

	logger.Info("User profile updated: " + strconv.Itoa(userID))
	c.JSON(http.StatusOK, gin.H{"message": "Profile updated successfully"})
}
