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

// GetRules 获取规则列表
func GetRules(c *gin.Context) {
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

	// 获取情侣关系信息以确定用户位置
	var user1ID, user2ID int
	err = database.DB.QueryRow("SELECT user1_id, user2_id FROM couples WHERE id = ?", coupleID.Int64).Scan(&user1ID, &user2ID)
	if err != nil {
		logger.Error("Failed to get couple users: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}

	// 确定当前用户是user1还是user2
	isCurrentUserUser1 := (userID == user1ID)

	// 获取规则列表
	query := `
		SELECT id, couple_id, name, description, points, target_type, is_active, created_at, updated_at
		FROM rules
		WHERE couple_id = ? AND is_active = TRUE
		ORDER BY created_at DESC
	`

	rows, err := database.DB.Query(query, coupleID.Int64)
	if err != nil {
		logger.Error("Failed to get rules: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get rules"})
		return
	}
	defer rows.Close()

	var rules []gin.H
	for rows.Next() {
		var rule models.Rule

		err := rows.Scan(
			&rule.ID, &rule.CoupleID, &rule.Name, &rule.Description, &rule.Points,
			&rule.TargetType, &rule.IsActive, &rule.CreatedAt, &rule.UpdatedAt,
		)
		if err != nil {
			logger.Error("Failed to scan rule: " + err.Error())
			continue
		}

		// 转换target_type为前端友好的格式
		var targetTypeForFrontend string
		switch rule.TargetType {
		case "user1":
			if isCurrentUserUser1 {
				targetTypeForFrontend = "current_user"
			} else {
				targetTypeForFrontend = "partner"
			}
		case "user2":
			if isCurrentUserUser1 {
				targetTypeForFrontend = "partner"
			} else {
				targetTypeForFrontend = "current_user"
			}
		case "both":
			targetTypeForFrontend = "both"
		default:
			targetTypeForFrontend = rule.TargetType
		}

		rules = append(rules, gin.H{
			"id":          rule.ID,
			"couple_id":   rule.CoupleID,
			"name":        rule.Name,
			"description": rule.Description,
			"points":      rule.Points,
			"target_type": targetTypeForFrontend,
			"is_active":   rule.IsActive,
			"created_at":  rule.CreatedAt,
			"updated_at":  rule.UpdatedAt,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"rules": rules,
	})
}

// CreateRule 创建规则
func CreateRule(c *gin.Context) {
	userID := c.GetInt("user_id")

	var req struct {
		Name        string `json:"name" binding:"required"`
		Description string `json:"description"`
		Points      int    `json:"points" binding:"required"`
		TargetType  string `json:"target_type" binding:"required,oneof=current_user partner both"`
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

	// 获取情侣关系信息以确定用户位置
	var user1ID, user2ID int
	err = database.DB.QueryRow("SELECT user1_id, user2_id FROM couples WHERE id = ?", coupleID.Int64).Scan(&user1ID, &user2ID)
	if err != nil {
		logger.Error("Failed to get couple users: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}

	// 转换前端的target_type为数据库格式
	var dbTargetType string
	switch req.TargetType {
	case "current_user":
		if userID == user1ID {
			dbTargetType = "user1"
		} else {
			dbTargetType = "user2"
		}
	case "partner":
		if userID == user1ID {
			dbTargetType = "user2"
		} else {
			dbTargetType = "user1"
		}
	case "both":
		dbTargetType = "both"
	default:
		dbTargetType = req.TargetType
	}

	// 创建规则
	result, err := database.DB.Exec(
		"INSERT INTO rules (couple_id, name, description, points, target_type) VALUES (?, ?, ?, ?, ?)",
		coupleID.Int64, req.Name, req.Description, req.Points, dbTargetType,
	)
	if err != nil {
		logger.Error("Failed to create rule: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create rule"})
		return
	}

	ruleID, _ := result.LastInsertId()

	logger.Info("Rule created: " + strconv.FormatInt(ruleID, 10) + " by user " + strconv.Itoa(userID))
	c.JSON(http.StatusCreated, gin.H{
		"message": "Rule created successfully",
		"rule_id": ruleID,
	})
}

// UpdateRule 更新规则
func UpdateRule(c *gin.Context) {
	userID := c.GetInt("user_id")
	ruleIDStr := c.Param("id")

	ruleID, err := strconv.Atoi(ruleIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid rule ID"})
		return
	}

	var req struct {
		Name        string `json:"name"`
		Description string `json:"description"`
		Points      int    `json:"points"`
		TargetType  string `json:"target_type" binding:"omitempty,oneof=user1 user2 both"`
		IsActive    *bool  `json:"is_active"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 检查规则权限
	if !canUserAccessRule(userID, ruleID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "Permission denied"})
		return
	}

	// 构建更新查询
	updates := []string{}
	args := []interface{}{}

	if req.Name != "" {
		updates = append(updates, "name = ?")
		args = append(args, req.Name)
	}
	if req.Description != "" {
		updates = append(updates, "description = ?")
		args = append(args, req.Description)
	}
	if req.Points != 0 {
		updates = append(updates, "points = ?")
		args = append(args, req.Points)
	}
	if req.TargetType != "" {
		updates = append(updates, "target_type = ?")
		args = append(args, req.TargetType)
	}
	if req.IsActive != nil {
		updates = append(updates, "is_active = ?")
		args = append(args, *req.IsActive)
	}

	if len(updates) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No fields to update"})
		return
	}

	updates = append(updates, "updated_at = CURRENT_TIMESTAMP")
	args = append(args, ruleID)

	query := "UPDATE rules SET " + joinStrings(updates, ", ") + " WHERE id = ?"

	_, err = database.DB.Exec(query, args...)
	if err != nil {
		logger.Error("Failed to update rule: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update rule"})
		return
	}

	logger.Info("Rule updated: " + strconv.Itoa(ruleID) + " by user " + strconv.Itoa(userID))
	c.JSON(http.StatusOK, gin.H{"message": "Rule updated successfully"})
}

// DeleteRule 删除规则
func DeleteRule(c *gin.Context) {
	userID := c.GetInt("user_id")
	ruleIDStr := c.Param("id")

	ruleID, err := strconv.Atoi(ruleIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid rule ID"})
		return
	}

	// 检查规则权限
	if !canUserAccessRule(userID, ruleID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "Permission denied"})
		return
	}

	// 软删除（设置为不活跃）
	_, err = database.DB.Exec("UPDATE rules SET is_active = FALSE, updated_at = CURRENT_TIMESTAMP WHERE id = ?", ruleID)
	if err != nil {
		logger.Error("Failed to delete rule: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete rule"})
		return
	}

	logger.Info("Rule deleted: " + strconv.Itoa(ruleID) + " by user " + strconv.Itoa(userID))
	c.JSON(http.StatusOK, gin.H{"message": "Rule deleted successfully"})
}

// ExecuteRule 执行规则
func ExecuteRule(c *gin.Context) {
	userID := c.GetInt("user_id")
	ruleIDStr := c.Param("id")

	ruleID, err := strconv.Atoi(ruleIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid rule ID"})
		return
	}

	// 获取请求体中的目标用户ID（可选，用于"both"类型的规则）
	var req struct {
		TargetUserID *int `json:"target_user_id"`
	}
	c.ShouldBindJSON(&req)

	// 获取规则信息
	var rule models.Rule
	err = database.DB.QueryRow(
		"SELECT id, couple_id, name, description, points, target_type, is_active FROM rules WHERE id = ?",
		ruleID,
	).Scan(&rule.ID, &rule.CoupleID, &rule.Name, &rule.Description, &rule.Points, &rule.TargetType, &rule.IsActive)

	if err != nil {
		if err == sql.ErrNoRows {
			c.JSON(http.StatusNotFound, gin.H{"error": "Rule not found"})
			return
		}
		logger.Error("Failed to get rule: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}

	if !rule.IsActive {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Rule is not active"})
		return
	}

	// 检查权限
	if !canUserAccessRule(userID, ruleID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "Permission denied"})
		return
	}

	// 获取情侣双方的用户ID
	var user1ID, user2ID int
	err = database.DB.QueryRow("SELECT user1_id, user2_id FROM couples WHERE id = ?", rule.CoupleID).Scan(&user1ID, &user2ID)
	if err != nil {
		logger.Error("Failed to get couple users: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}

	// 确定目标用户
	var targetUsers []int
	switch rule.TargetType {
	case "user1":
		targetUsers = []int{user1ID}
	case "user2":
		targetUsers = []int{user2ID}
	case "both":
		// 对于"both"类型的规则，需要指定具体的目标用户
		if req.TargetUserID == nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Target user ID is required for 'both' type rules"})
			return
		}

		// 验证目标用户ID是否有效（必须是情侣中的一方）
		if *req.TargetUserID != user1ID && *req.TargetUserID != user2ID {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid target user ID"})
			return
		}

		targetUsers = []int{*req.TargetUserID}
	}

	// 开始事务
	tx, err := database.DB.Begin()
	if err != nil {
		logger.Error("Failed to begin transaction: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}
	defer tx.Rollback()

	// 为每个目标用户执行规则
	for _, targetUserID := range targetUsers {
		// 更新用户积分
		err = updateUserPoints(tx, targetUserID, rule.Points)
		if err != nil {
			logger.Error("Failed to update user points: " + err.Error())
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to execute rule"})
			return
		}

		// 添加积分历史记录
		description := "执行规则: " + rule.Name
		err = addPointsHistory(tx, targetUserID, rule.Points, "rule", &ruleID, description, true)
		if err != nil {
			logger.Error("Failed to add points history: " + err.Error())
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to execute rule"})
			return
		}
	}

	// 提交事务
	if err = tx.Commit(); err != nil {
		logger.Error("Failed to commit transaction: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to execute rule"})
		return
	}

	logger.Info("Rule executed: " + strconv.Itoa(ruleID) + " by user " + strconv.Itoa(userID))
	c.JSON(http.StatusOK, gin.H{
		"message":        "Rule executed successfully",
		"affected_users": len(targetUsers),
	})
}

// canUserAccessRule 检查用户是否可以访问某个规则
func canUserAccessRule(userID, ruleID int) bool {
	var count int
	query := `
		SELECT COUNT(*) FROM rules r
		JOIN couples c ON r.couple_id = c.id
		JOIN users u ON (c.user1_id = u.id OR c.user2_id = u.id)
		WHERE r.id = ? AND u.id = ?
	`
	err := database.DB.QueryRow(query, ruleID, userID).Scan(&count)
	return err == nil && count > 0
}
