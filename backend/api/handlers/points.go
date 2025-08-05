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

// HealthCheck 健康检查端点
func HealthCheck(c *gin.Context) {
	// 检查数据库连接
	if err := database.DB.Ping(); err != nil {
		logger.Error("Database health check failed: " + err.Error())
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"status": "unhealthy",
			"error":  "Database connection failed",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "healthy",
		"service": "booonus-backend",
	})
}

// GetPoints 获取用户积分
func GetPoints(c *gin.Context) {
	userID := c.GetInt("user_id")

	var points int
	err := database.DB.QueryRow("SELECT points FROM users WHERE id = ?", userID).Scan(&points)
	if err != nil {
		logger.Error("Failed to get user points: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get points"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"points": points,
	})
}

// GetPointsHistory 获取积分变化历史
func GetPointsHistory(c *gin.Context) {
	userID := c.GetInt("user_id")

	// 获取查询参数
	limitStr := c.DefaultQuery("limit", "50")
	offsetStr := c.DefaultQuery("offset", "0")

	limit, _ := strconv.Atoi(limitStr)
	offset, _ := strconv.Atoi(offsetStr)

	// 查询积分历史
	query := `
		SELECT id, user_id, points, type, reference_id, description,
		       can_revert, is_reverted, created_at
		FROM points_history
		WHERE user_id = ?
		ORDER BY created_at DESC
		LIMIT ? OFFSET ?
	`

	rows, err := database.DB.Query(query, userID, limit, offset)
	if err != nil {
		logger.Error("Failed to get points history: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get points history"})
		return
	}
	defer rows.Close()

	var history []models.PointsHistory
	for rows.Next() {
		var h models.PointsHistory
		var referenceID sql.NullInt64

		err := rows.Scan(
			&h.ID, &h.UserID, &h.Points, &h.Type, &referenceID,
			&h.Description, &h.CanRevert, &h.IsReverted, &h.CreatedAt,
		)
		if err != nil {
			logger.Error("Failed to scan points history: " + err.Error())
			continue
		}

		if referenceID.Valid {
			refID := int(referenceID.Int64)
			h.ReferenceID = &refID
		}

		history = append(history, h)
	}

	// 获取总数
	var total int
	err = database.DB.QueryRow("SELECT COUNT(*) FROM points_history WHERE user_id = ?", userID).Scan(&total)
	if err != nil {
		logger.Error("Failed to get points history count: " + err.Error())
		total = len(history)
	}

	c.JSON(http.StatusOK, gin.H{
		"history": history,
		"total":   total,
		"limit":   limit,
		"offset":  offset,
	})
}

// GetUserPointsHistory 获取指定用户的积分变化历史
func GetUserPointsHistory(c *gin.Context) {
	userID := c.GetInt("user_id")
	targetUserIDStr := c.Param("user_id")

	targetUserID, err := strconv.Atoi(targetUserIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// 检查权限：只能查看自己或情侣的积分历史
	if !canUserRevertHistory(userID, targetUserID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "Permission denied"})
		return
	}

	// 获取查询参数
	limitStr := c.DefaultQuery("limit", "50")
	offsetStr := c.DefaultQuery("offset", "0")

	limit, _ := strconv.Atoi(limitStr)
	offset, _ := strconv.Atoi(offsetStr)

	// 查询积分历史
	query := `
		SELECT id, user_id, points, type, reference_id, description,
		       can_revert, is_reverted, created_at
		FROM points_history
		WHERE user_id = ?
		ORDER BY created_at DESC
		LIMIT ? OFFSET ?
	`

	rows, err := database.DB.Query(query, targetUserID, limit, offset)
	if err != nil {
		logger.Error("Failed to get user points history: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get points history"})
		return
	}
	defer rows.Close()

	var history []models.PointsHistory
	for rows.Next() {
		var h models.PointsHistory
		var referenceID sql.NullInt64

		err := rows.Scan(
			&h.ID, &h.UserID, &h.Points, &h.Type, &referenceID,
			&h.Description, &h.CanRevert, &h.IsReverted, &h.CreatedAt,
		)
		if err != nil {
			logger.Error("Failed to scan user points history: " + err.Error())
			continue
		}

		if referenceID.Valid {
			refID := int(referenceID.Int64)
			h.ReferenceID = &refID
		}

		history = append(history, h)
	}

	// 获取总数
	var total int
	err = database.DB.QueryRow("SELECT COUNT(*) FROM points_history WHERE user_id = ?", targetUserID).Scan(&total)
	if err != nil {
		logger.Error("Failed to get user points history count: " + err.Error())
		total = len(history)
	}

	c.JSON(http.StatusOK, gin.H{
		"history": history,
		"total":   total,
		"limit":   limit,
		"offset":  offset,
	})
}

// addPointsHistory 添加积分历史记录（内部函数）
func addPointsHistory(tx *sql.Tx, userID, points int, historyType string, referenceID *int, description string, canRevert bool) error {
	var refID interface{}
	if referenceID != nil {
		refID = *referenceID
	}

	_, err := tx.Exec(
		"INSERT INTO points_history (user_id, points, type, reference_id, description, can_revert) VALUES (?, ?, ?, ?, ?, ?)",
		userID, points, historyType, refID, description, canRevert,
	)
	return err
}

// updateUserPoints 更新用户积分（内部函数）
func updateUserPoints(tx *sql.Tx, userID, pointsChange int) error {
	_, err := tx.Exec("UPDATE users SET points = points + ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?", pointsChange, userID)
	return err
}

// RevertOperation 撤销操作
func RevertOperation(c *gin.Context) {
	userID := c.GetInt("user_id")
	historyIDStr := c.Param("id")

	historyID, err := strconv.Atoi(historyIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid history ID"})
		return
	}

	// 获取历史记录
	var history models.PointsHistory
	var referenceID sql.NullInt64

	err = database.DB.QueryRow(
		"SELECT id, user_id, points, type, reference_id, description, can_revert, is_reverted FROM points_history WHERE id = ?",
		historyID,
	).Scan(&history.ID, &history.UserID, &history.Points, &history.Type, &referenceID, &history.Description, &history.CanRevert, &history.IsReverted)

	if err != nil {
		if err == sql.ErrNoRows {
			c.JSON(http.StatusNotFound, gin.H{"error": "History record not found"})
			return
		}
		logger.Error("Failed to get history record: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get history record"})
		return
	}

	// 检查权限（只能撤销自己相关的记录或情侣的记录）
	if !canUserRevertHistory(userID, history.UserID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "Permission denied"})
		return
	}

	// 检查是否可以撤销
	if !history.CanRevert {
		c.JSON(http.StatusBadRequest, gin.H{"error": "This operation cannot be reverted"})
		return
	}

	if history.IsReverted {
		c.JSON(http.StatusBadRequest, gin.H{"error": "This operation has already been reverted"})
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

	// 撤销积分变化
	err = updateUserPoints(tx, history.UserID, -history.Points)
	if err != nil {
		logger.Error("Failed to revert points: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to revert operation"})
		return
	}

	// 标记为已撤销
	_, err = tx.Exec("UPDATE points_history SET is_reverted = TRUE WHERE id = ?", historyID)
	if err != nil {
		logger.Error("Failed to mark as reverted: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to revert operation"})
		return
	}

	// 添加撤销记录
	revertDescription := "撤销操作: " + history.Description
	err = addPointsHistory(tx, history.UserID, -history.Points, "revert", &historyID, revertDescription, false)
	if err != nil {
		logger.Error("Failed to add revert history: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to revert operation"})
		return
	}

	// 提交事务
	if err = tx.Commit(); err != nil {
		logger.Error("Failed to commit transaction: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to revert operation"})
		return
	}

	logger.Info("Operation reverted: " + strconv.Itoa(historyID) + " by user " + strconv.Itoa(userID))
	c.JSON(http.StatusOK, gin.H{"message": "Operation reverted successfully"})
}

// canUserRevertHistory 检查用户是否可以撤销某个历史记录
func canUserRevertHistory(userID, targetUserID int) bool {
	// 可以撤销自己的记录
	if userID == targetUserID {
		return true
	}

	// 检查是否是情侣关系
	var count int
	query := `
		SELECT COUNT(*) FROM couples c
		JOIN users u1 ON (c.user1_id = u1.id OR c.user2_id = u1.id)
		JOIN users u2 ON (c.user1_id = u2.id OR c.user2_id = u2.id)
		WHERE u1.id = ? AND u2.id = ?
	`
	err := database.DB.QueryRow(query, userID, targetUserID).Scan(&count)
	return err == nil && count > 0
}
