package handlers

import (
	"database/sql"
	"net/http"
	"strconv"

	"booonus-backend/internal/database"
	"booonus-backend/models"
	"booonus-backend/pkg/logger"

	"github.com/gin-gonic/gin"
)

// InviteCouple 邀请成为情侣
func InviteCouple(c *gin.Context) {
	userID := c.GetInt("user_id")

	var req struct {
		Username string `json:"username" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 检查当前用户是否已有情侣
	var currentCoupleID sql.NullInt64
	err := database.DB.QueryRow("SELECT couple_id FROM users WHERE id = ?", userID).Scan(&currentCoupleID)
	if err != nil {
		logger.Error("Failed to check current user couple status: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}

	if currentCoupleID.Valid {
		c.JSON(http.StatusBadRequest, gin.H{"error": "You already have a couple"})
		return
	}

	// 查找目标用户
	var targetUser models.User
	err = database.DB.QueryRow(
		"SELECT id, username, couple_id FROM users WHERE username = ?",
		req.Username,
	).Scan(&targetUser.ID, &targetUser.Username, &targetUser.CoupleID)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// 检查目标用户是否已有情侣
	if targetUser.CoupleID != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Target user already has a couple"})
		return
	}

	// 不能邀请自己
	if targetUser.ID == userID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot invite yourself"})
		return
	}

	// 创建情侣关系
	result, err := database.DB.Exec(
		"INSERT INTO couples (user1_id, user2_id) VALUES (?, ?)",
		userID, targetUser.ID,
	)
	if err != nil {
		logger.Error("Failed to create couple relationship: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create couple relationship"})
		return
	}

	coupleID, _ := result.LastInsertId()

	// 更新两个用户的couple_id
	_, err = database.DB.Exec("UPDATE users SET couple_id = ? WHERE id IN (?, ?)", coupleID, userID, targetUser.ID)
	if err != nil {
		logger.Error("Failed to update users couple_id: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update couple relationship"})
		return
	}

	logger.Info("Couple relationship created: " + strconv.Itoa(userID) + " and " + strconv.Itoa(targetUser.ID))
	c.JSON(http.StatusCreated, gin.H{
		"message":   "Couple relationship created successfully",
		"couple_id": coupleID,
		"partner": gin.H{
			"id":       targetUser.ID,
			"username": targetUser.Username,
		},
	})
}

// AcceptCouple 接受情侣邀请（这里简化为直接邀请即建立关系）
func AcceptCouple(c *gin.Context) {
	// 在这个简化版本中，邀请即自动建立关系
	// 如果需要邀请-接受流程，可以添加pending_couples表
	c.JSON(http.StatusOK, gin.H{"message": "This feature is automatically handled in invite"})
}

// RemoveCouple 解除情侣关系
func RemoveCouple(c *gin.Context) {
	userID := c.GetInt("user_id")

	// 获取当前用户的情侣关系
	var coupleID sql.NullInt64
	err := database.DB.QueryRow("SELECT couple_id FROM users WHERE id = ?", userID).Scan(&coupleID)
	if err != nil {
		logger.Error("Failed to get user couple info: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}

	if !coupleID.Valid {
		c.JSON(http.StatusBadRequest, gin.H{"error": "You don't have a couple relationship"})
		return
	}

	// 开始事务
	tx, err := database.DB.Begin()
	if err != nil {
		logger.Error("Failed to begin transaction: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}
	defer tx.Rollback()

	// 清除用户的couple_id
	_, err = tx.Exec("UPDATE users SET couple_id = NULL WHERE couple_id = ?", coupleID.Int64)
	if err != nil {
		logger.Error("Failed to update users: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to remove couple relationship"})
		return
	}

	// 删除情侣关系记录
	_, err = tx.Exec("DELETE FROM couples WHERE id = ?", coupleID.Int64)
	if err != nil {
		logger.Error("Failed to delete couple record: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to remove couple relationship"})
		return
	}

	// 提交事务
	if err = tx.Commit(); err != nil {
		logger.Error("Failed to commit transaction: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to remove couple relationship"})
		return
	}

	logger.Info("Couple relationship removed for user: " + strconv.Itoa(userID))
	c.JSON(http.StatusOK, gin.H{"message": "Couple relationship removed successfully"})
}

// GetCouple 获取情侣信息
func GetCouple(c *gin.Context) {
	userID := c.GetInt("user_id")

	// 获取情侣信息
	var couple models.Couple
	var partnerUser models.User

	// 首先获取情侣关系信息
	query := `
		SELECT c.id, c.user1_id, c.user2_id, c.created_at
		FROM couples c
		WHERE c.user1_id = ? OR c.user2_id = ?
	`

	err := database.DB.QueryRow(query, userID, userID).Scan(
		&couple.ID, &couple.User1ID, &couple.User2ID, &couple.CreatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			c.JSON(http.StatusNotFound, gin.H{"error": "No couple relationship found"})
			return
		}
		logger.Error("Failed to get couple info: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get couple info"})
		return
	}

	// 确定伴侣的ID
	var partnerID int
	if couple.User1ID == userID {
		partnerID = couple.User2ID
	} else {
		partnerID = couple.User1ID
	}

	// 获取伴侣的用户信息
	partnerQuery := `
		SELECT id, username, points, created_at, updated_at
		FROM users
		WHERE id = ?
	`

	err = database.DB.QueryRow(partnerQuery, partnerID).Scan(
		&partnerUser.ID, &partnerUser.Username, &partnerUser.Points,
		&partnerUser.CreatedAt, &partnerUser.UpdatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			c.JSON(http.StatusNotFound, gin.H{"error": "No couple relationship found"})
			return
		}
		logger.Error("Failed to get couple info: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get couple info"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"couple": gin.H{
			"id":         couple.ID,
			"created_at": couple.CreatedAt,
			"partner": gin.H{
				"id":         partnerUser.ID,
				"username":   partnerUser.Username,
				"points":     partnerUser.Points,
				"created_at": partnerUser.CreatedAt,
				"updated_at": partnerUser.UpdatedAt,
			},
		},
	})
}
