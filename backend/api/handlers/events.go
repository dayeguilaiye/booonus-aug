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

// GetEvents 获取事件列表
func GetEvents(c *gin.Context) {
	userID := c.GetInt("user_id")

	// 获取用户的情侣关系
	var coupleID sql.NullInt64
	err := database.DB.QueryRow("SELECT couple_id FROM users WHERE id = ?", userID).Scan(&coupleID)
	if err != nil {
		logger.Error("Failed to get user couple info: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}

	if !coupleID.Valid {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No couple relationship found"})
		return
	}

	// 获取查询参数
	limitStr := c.DefaultQuery("limit", "50")
	offsetStr := c.DefaultQuery("offset", "0")
	
	limit, _ := strconv.Atoi(limitStr)
	offset, _ := strconv.Atoi(offsetStr)

	// 获取事件列表
	query := `
		SELECT e.id, e.couple_id, e.creator_id, e.target_id, e.name, e.description, e.points, e.created_at,
		       u1.username as creator_name, u2.username as target_name
		FROM events e
		JOIN users u1 ON e.creator_id = u1.id
		JOIN users u2 ON e.target_id = u2.id
		WHERE e.couple_id = ?
		ORDER BY e.created_at DESC
		LIMIT ? OFFSET ?
	`
	
	rows, err := database.DB.Query(query, coupleID.Int64, limit, offset)
	if err != nil {
		logger.Error("Failed to get events: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get events"})
		return
	}
	defer rows.Close()

	var events []gin.H
	for rows.Next() {
		var event models.Event
		var creatorName, targetName string
		
		err := rows.Scan(
			&event.ID, &event.CoupleID, &event.CreatorID, &event.TargetID,
			&event.Name, &event.Description, &event.Points, &event.CreatedAt,
			&creatorName, &targetName,
		)
		if err != nil {
			logger.Error("Failed to scan event: " + err.Error())
			continue
		}
		
		events = append(events, gin.H{
			"id":           event.ID,
			"couple_id":    event.CoupleID,
			"creator_id":   event.CreatorID,
			"creator_name": creatorName,
			"target_id":    event.TargetID,
			"target_name":  targetName,
			"name":         event.Name,
			"description":  event.Description,
			"points":       event.Points,
			"created_at":   event.CreatedAt,
		})
	}

	// 获取总数
	var total int
	err = database.DB.QueryRow("SELECT COUNT(*) FROM events WHERE couple_id = ?", coupleID.Int64).Scan(&total)
	if err != nil {
		logger.Error("Failed to get events count: " + err.Error())
		total = len(events)
	}

	c.JSON(http.StatusOK, gin.H{
		"events": events,
		"total":  total,
		"limit":  limit,
		"offset": offset,
	})
}

// CreateEvent 创建事件
func CreateEvent(c *gin.Context) {
	userID := c.GetInt("user_id")
	
	var req struct {
		TargetID    int    `json:"target_id" binding:"required"`
		Name        string `json:"name" binding:"required"`
		Description string `json:"description"`
		Points      int    `json:"points" binding:"required"`
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 获取用户的情侣关系
	var coupleID sql.NullInt64
	err := database.DB.QueryRow("SELECT couple_id FROM users WHERE id = ?", userID).Scan(&coupleID)
	if err != nil {
		logger.Error("Failed to get user couple info: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}

	if !coupleID.Valid {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No couple relationship found"})
		return
	}

	// 验证目标用户是否是情侣关系中的一员
	if !canUserAccessTarget(userID, req.TargetID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "Target user must be yourself or your couple"})
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

	// 创建事件
	result, err := tx.Exec(
		"INSERT INTO events (couple_id, creator_id, target_id, name, description, points) VALUES (?, ?, ?, ?, ?, ?)",
		coupleID.Int64, userID, req.TargetID, req.Name, req.Description, req.Points,
	)
	if err != nil {
		logger.Error("Failed to create event: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create event"})
		return
	}

	eventID, _ := result.LastInsertId()
	eventIDInt := int(eventID)

	// 更新目标用户积分
	err = updateUserPoints(tx, req.TargetID, req.Points)
	if err != nil {
		logger.Error("Failed to update target user points: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create event"})
		return
	}

	// 添加积分历史记录
	description := "事件: " + req.Name
	err = addPointsHistory(tx, req.TargetID, req.Points, "event", &eventIDInt, description, true)
	if err != nil {
		logger.Error("Failed to add points history: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create event"})
		return
	}

	// 提交事务
	if err = tx.Commit(); err != nil {
		logger.Error("Failed to commit transaction: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create event"})
		return
	}

	logger.Info("Event created: " + strconv.FormatInt(eventID, 10) + " by user " + strconv.Itoa(userID))
	c.JSON(http.StatusCreated, gin.H{
		"message":  "Event created successfully",
		"event_id": eventID,
	})
}

// canUserAccessTarget 检查用户是否可以对目标用户执行操作
func canUserAccessTarget(userID, targetID int) bool {
	// 可以对自己执行操作
	if userID == targetID {
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
	err := database.DB.QueryRow(query, userID, targetID).Scan(&count)
	return err == nil && count > 0
}
