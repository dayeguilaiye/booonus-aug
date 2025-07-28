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

// GetShopItems 获取小卖部商品
func GetShopItems(c *gin.Context) {
	userID := c.GetInt("user_id")

	// 获取查询参数
	ownerIDStr := c.Query("owner_id") // 如果指定，则获取指定用户的商品

	var query string
	var args []interface{}

	if ownerIDStr != "" {
		ownerID, err := strconv.Atoi(ownerIDStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid owner_id"})
			return
		}

		// 检查是否有权限查看（自己或情侣）
		if !canUserAccessShop(userID, ownerID) {
			c.JSON(http.StatusForbidden, gin.H{"error": "Permission denied"})
			return
		}

		query = `
			SELECT s.id, s.user_id, s.name, s.description, s.price, s.is_active, s.created_at, s.updated_at,
			       u.username
			FROM shop_items s
			JOIN users u ON s.user_id = u.id
			WHERE s.user_id = ? AND s.is_active = TRUE
			ORDER BY s.created_at DESC
		`
		args = []interface{}{ownerID}
	} else {
		// 获取情侣的所有商品
		query = `
			SELECT s.id, s.user_id, s.name, s.description, s.price, s.is_active, s.created_at, s.updated_at,
			       u.username
			FROM shop_items s
			JOIN users u ON s.user_id = u.id
			JOIN couples c ON (c.user1_id = u.id OR c.user2_id = u.id)
			JOIN users u2 ON (c.user1_id = u2.id OR c.user2_id = u2.id)
			WHERE u2.id = ? AND s.is_active = TRUE
			ORDER BY s.created_at DESC
		`
		args = []interface{}{userID}
	}

	rows, err := database.DB.Query(query, args...)
	if err != nil {
		logger.Error("Failed to get shop items: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get shop items"})
		return
	}
	defer rows.Close()

	var items []gin.H
	for rows.Next() {
		var item models.Shop
		var username string

		err := rows.Scan(
			&item.ID, &item.UserID, &item.Name, &item.Description, &item.Price,
			&item.IsActive, &item.CreatedAt, &item.UpdatedAt, &username,
		)
		if err != nil {
			logger.Error("Failed to scan shop item: " + err.Error())
			continue
		}

		items = append(items, gin.H{
			"id":          item.ID,
			"user_id":     item.UserID,
			"username":    username,
			"name":        item.Name,
			"description": item.Description,
			"price":       item.Price,
			"is_active":   item.IsActive,
			"created_at":  item.CreatedAt,
			"updated_at":  item.UpdatedAt,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"items": items,
	})
}

// CreateShopItem 创建商品
func CreateShopItem(c *gin.Context) {
	userID := c.GetInt("user_id")

	var req struct {
		Name        string `json:"name" binding:"required"`
		Description string `json:"description"`
		Price       int    `json:"price" binding:"required,min=1"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 创建商品
	result, err := database.DB.Exec(
		"INSERT INTO shop_items (user_id, name, description, price) VALUES (?, ?, ?, ?)",
		userID, req.Name, req.Description, req.Price,
	)
	if err != nil {
		logger.Error("Failed to create shop item: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create shop item"})
		return
	}

	itemID, _ := result.LastInsertId()

	logger.Info("Shop item created: " + strconv.FormatInt(itemID, 10) + " by user " + strconv.Itoa(userID))
	c.JSON(http.StatusCreated, gin.H{
		"message": "Shop item created successfully",
		"item_id": itemID,
	})
}

// UpdateShopItem 更新商品
func UpdateShopItem(c *gin.Context) {
	userID := c.GetInt("user_id")
	itemIDStr := c.Param("id")

	itemID, err := strconv.Atoi(itemIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid item ID"})
		return
	}

	var req struct {
		Name        string `json:"name"`
		Description string `json:"description"`
		Price       int    `json:"price" binding:"min=1"`
		IsActive    *bool  `json:"is_active"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 检查商品所有权
	var ownerID int
	err = database.DB.QueryRow("SELECT user_id FROM shop_items WHERE id = ?", itemID).Scan(&ownerID)
	if err != nil {
		if err == sql.ErrNoRows {
			c.JSON(http.StatusNotFound, gin.H{"error": "Shop item not found"})
			return
		}
		logger.Error("Failed to get shop item owner: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}

	if ownerID != userID {
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
	if req.Price > 0 {
		updates = append(updates, "price = ?")
		args = append(args, req.Price)
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
	args = append(args, itemID)

	query := "UPDATE shop_items SET " + joinStrings(updates, ", ") + " WHERE id = ?"

	_, err = database.DB.Exec(query, args...)
	if err != nil {
		logger.Error("Failed to update shop item: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update shop item"})
		return
	}

	logger.Info("Shop item updated: " + strconv.Itoa(itemID) + " by user " + strconv.Itoa(userID))
	c.JSON(http.StatusOK, gin.H{"message": "Shop item updated successfully"})
}

// DeleteShopItem 删除商品
func DeleteShopItem(c *gin.Context) {
	userID := c.GetInt("user_id")
	itemIDStr := c.Param("id")

	itemID, err := strconv.Atoi(itemIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid item ID"})
		return
	}

	// 检查商品所有权
	var ownerID int
	err = database.DB.QueryRow("SELECT user_id FROM shop_items WHERE id = ?", itemID).Scan(&ownerID)
	if err != nil {
		if err == sql.ErrNoRows {
			c.JSON(http.StatusNotFound, gin.H{"error": "Shop item not found"})
			return
		}
		logger.Error("Failed to get shop item owner: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}

	if ownerID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Permission denied"})
		return
	}

	// 软删除（设置为不活跃）
	_, err = database.DB.Exec("UPDATE shop_items SET is_active = FALSE, updated_at = CURRENT_TIMESTAMP WHERE id = ?", itemID)
	if err != nil {
		logger.Error("Failed to delete shop item: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete shop item"})
		return
	}

	logger.Info("Shop item deleted: " + strconv.Itoa(itemID) + " by user " + strconv.Itoa(userID))
	c.JSON(http.StatusOK, gin.H{"message": "Shop item deleted successfully"})
}

// BuyShopItem 购买商品
func BuyShopItem(c *gin.Context) {
	userID := c.GetInt("user_id")
	itemIDStr := c.Param("id")

	itemID, err := strconv.Atoi(itemIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid item ID"})
		return
	}

	// 获取商品信息
	var item models.Shop
	err = database.DB.QueryRow(
		"SELECT id, user_id, name, price, is_active FROM shop_items WHERE id = ?",
		itemID,
	).Scan(&item.ID, &item.UserID, &item.Name, &item.Price, &item.IsActive)

	if err != nil {
		if err == sql.ErrNoRows {
			c.JSON(http.StatusNotFound, gin.H{"error": "Shop item not found"})
			return
		}
		logger.Error("Failed to get shop item: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}

	if !item.IsActive {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Shop item is not available"})
		return
	}

	// 不能购买自己的商品
	if item.UserID == userID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot buy your own item"})
		return
	}

	// 检查是否是情侣关系
	if !canUserAccessShop(userID, item.UserID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "Can only buy from your couple"})
		return
	}

	// 检查买家积分是否足够
	var buyerPoints int
	err = database.DB.QueryRow("SELECT points FROM users WHERE id = ?", userID).Scan(&buyerPoints)
	if err != nil {
		logger.Error("Failed to get buyer points: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}

	if buyerPoints < item.Price {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Insufficient points"})
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

	// 创建交易记录
	result, err := tx.Exec(
		"INSERT INTO transactions (buyer_id, seller_id, shop_item_id, points) VALUES (?, ?, ?, ?)",
		userID, item.UserID, itemID, item.Price,
	)
	if err != nil {
		logger.Error("Failed to create transaction: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create transaction"})
		return
	}

	transactionID, _ := result.LastInsertId()

	// 扣除买家积分
	err = updateUserPoints(tx, userID, -item.Price)
	if err != nil {
		logger.Error("Failed to deduct buyer points: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process transaction"})
		return
	}

	// 增加卖家积分（只能获得五分之一的价格，向下取整）
	sellerPoints := item.Price / 5
	err = updateUserPoints(tx, item.UserID, sellerPoints)
	if err != nil {
		logger.Error("Failed to add seller points: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process transaction"})
		return
	}

	// 添加积分历史记录
	transactionIDInt := int(transactionID)
	buyDescription := "购买商品: " + item.Name
	sellDescription := "出售商品: " + item.Name

	err = addPointsHistory(tx, userID, -item.Price, "transaction", &transactionIDInt, buyDescription, true)
	if err != nil {
		logger.Error("Failed to add buyer history: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process transaction"})
		return
	}

	err = addPointsHistory(tx, item.UserID, sellerPoints, "transaction", &transactionIDInt, sellDescription, true)
	if err != nil {
		logger.Error("Failed to add seller history: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process transaction"})
		return
	}

	// 提交事务
	if err = tx.Commit(); err != nil {
		logger.Error("Failed to commit transaction: " + err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process transaction"})
		return
	}

	logger.Info("Transaction completed: " + strconv.FormatInt(transactionID, 10))
	c.JSON(http.StatusOK, gin.H{
		"message":        "Purchase completed successfully",
		"transaction_id": transactionID,
	})
}

// canUserAccessShop 检查用户是否可以访问某个用户的小卖部
func canUserAccessShop(userID, shopOwnerID int) bool {
	// 可以访问自己的小卖部
	if userID == shopOwnerID {
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
	err := database.DB.QueryRow(query, userID, shopOwnerID).Scan(&count)
	return err == nil && count > 0
}

// joinStrings 连接字符串数组（简单实现）
func joinStrings(strs []string, sep string) string {
	if len(strs) == 0 {
		return ""
	}
	if len(strs) == 1 {
		return strs[0]
	}

	result := strs[0]
	for i := 1; i < len(strs); i++ {
		result += sep + strs[i]
	}
	return result
}
