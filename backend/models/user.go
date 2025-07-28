package models

import (
	"time"
)

// User 用户模型
type User struct {
	ID        int       `json:"id" db:"id"`
	Username  string    `json:"username" db:"username"`
	Password  string    `json:"-" db:"password"` // 不在JSON中显示密码
	Points    int       `json:"points" db:"points"`
	CoupleID  *int      `json:"couple_id" db:"couple_id"` // 情侣ID，可为空
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

// Couple 情侣关系模型
type Couple struct {
	ID        int       `json:"id" db:"id"`
	User1ID   int       `json:"user1_id" db:"user1_id"`
	User2ID   int       `json:"user2_id" db:"user2_id"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

// Shop 小卖部商品模型
type Shop struct {
	ID          int       `json:"id" db:"id"`
	UserID      int       `json:"user_id" db:"user_id"`
	Name        string    `json:"name" db:"name"`
	Description string    `json:"description" db:"description"`
	Price       int       `json:"price" db:"price"`
	IsActive    bool      `json:"is_active" db:"is_active"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
}

// Rule 规则模型
type Rule struct {
	ID          int       `json:"id" db:"id"`
	CoupleID    int       `json:"couple_id" db:"couple_id"`
	Name        string    `json:"name" db:"name"`
	Description string    `json:"description" db:"description"`
	Points      int       `json:"points" db:"points"` // 正数为奖励，负数为惩罚
	TargetType  string    `json:"target_type" db:"target_type"` // "user1", "user2", "both"
	IsActive    bool      `json:"is_active" db:"is_active"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
}

// Event 事件模型
type Event struct {
	ID          int       `json:"id" db:"id"`
	CoupleID    int       `json:"couple_id" db:"couple_id"`
	CreatorID   int       `json:"creator_id" db:"creator_id"`
	TargetID    int       `json:"target_id" db:"target_id"`
	Name        string    `json:"name" db:"name"`
	Description string    `json:"description" db:"description"`
	Points      int       `json:"points" db:"points"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
}

// Transaction 交易记录模型
type Transaction struct {
	ID          int       `json:"id" db:"id"`
	BuyerID     int       `json:"buyer_id" db:"buyer_id"`
	SellerID    int       `json:"seller_id" db:"seller_id"`
	ShopItemID  int       `json:"shop_item_id" db:"shop_item_id"`
	Points      int       `json:"points" db:"points"`
	Status      string    `json:"status" db:"status"` // "completed", "cancelled"
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
}

// PointsHistory 积分变化历史
type PointsHistory struct {
	ID            int       `json:"id" db:"id"`
	UserID        int       `json:"user_id" db:"user_id"`
	Points        int       `json:"points" db:"points"` // 变化的积分数量
	Type          string    `json:"type" db:"type"`     // "transaction", "rule", "event"
	ReferenceID   *int      `json:"reference_id" db:"reference_id"` // 关联的记录ID
	Description   string    `json:"description" db:"description"`
	CanRevert     bool      `json:"can_revert" db:"can_revert"`
	IsReverted    bool      `json:"is_reverted" db:"is_reverted"`
	CreatedAt     time.Time `json:"created_at" db:"created_at"`
}
