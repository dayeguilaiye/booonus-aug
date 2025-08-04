package database

import (
	"booonus-backend/pkg/logger"
	"database/sql"
	"os"
	"path/filepath"

	_ "github.com/ncruces/go-sqlite3/driver"
	_ "github.com/ncruces/go-sqlite3/embed"
)

var DB *sql.DB

// Init 初始化数据库连接
func Init() error {
	// 确保数据库目录存在
	dbDir := "database"
	if err := os.MkdirAll(dbDir, 0755); err != nil {
		return err
	}

	// 连接数据库
	dbPath := filepath.Join(dbDir, "booonus.db")
	var err error
	DB, err = sql.Open("sqlite3", dbPath)
	if err != nil {
		return err
	}

	// 测试连接
	if err = DB.Ping(); err != nil {
		return err
	}

	logger.Info("Database connected successfully")

	// 创建表
	if err = createTables(); err != nil {
		return err
	}

	// 运行数据库迁移
	if err = runMigrations(); err != nil {
		return err
	}

	logger.Info("Database tables created successfully")
	return nil
}

// createTables 创建数据库表
func createTables() error {
	queries := []string{
		`CREATE TABLE IF NOT EXISTS users (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			username TEXT UNIQUE NOT NULL,
			password TEXT NOT NULL,
			points INTEGER DEFAULT 0,
			avatar TEXT,
			couple_id INTEGER,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
		)`,

		`CREATE TABLE IF NOT EXISTS couples (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user1_id INTEGER NOT NULL,
			user2_id INTEGER NOT NULL,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY (user1_id) REFERENCES users(id),
			FOREIGN KEY (user2_id) REFERENCES users(id)
		)`,

		`CREATE TABLE IF NOT EXISTS shop_items (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id INTEGER NOT NULL,
			name TEXT NOT NULL,
			description TEXT,
			price INTEGER NOT NULL,
			is_active BOOLEAN DEFAULT TRUE,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY (user_id) REFERENCES users(id)
		)`,

		`CREATE TABLE IF NOT EXISTS rules (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			couple_id INTEGER NOT NULL,
			name TEXT NOT NULL,
			description TEXT,
			points INTEGER NOT NULL,
			target_type TEXT NOT NULL CHECK (target_type IN ('user1', 'user2', 'both')),
			is_active BOOLEAN DEFAULT TRUE,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY (couple_id) REFERENCES couples(id)
		)`,

		`CREATE TABLE IF NOT EXISTS events (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			couple_id INTEGER NOT NULL,
			creator_id INTEGER NOT NULL,
			target_id INTEGER NOT NULL,
			name TEXT NOT NULL,
			description TEXT,
			points INTEGER NOT NULL,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY (couple_id) REFERENCES couples(id),
			FOREIGN KEY (creator_id) REFERENCES users(id),
			FOREIGN KEY (target_id) REFERENCES users(id)
		)`,

		`CREATE TABLE IF NOT EXISTS transactions (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			buyer_id INTEGER NOT NULL,
			seller_id INTEGER NOT NULL,
			shop_item_id INTEGER NOT NULL,
			points INTEGER NOT NULL,
			status TEXT DEFAULT 'completed' CHECK (status IN ('completed', 'cancelled')),
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY (buyer_id) REFERENCES users(id),
			FOREIGN KEY (seller_id) REFERENCES users(id),
			FOREIGN KEY (shop_item_id) REFERENCES shop_items(id)
		)`,

		`CREATE TABLE IF NOT EXISTS points_history (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id INTEGER NOT NULL,
			points INTEGER NOT NULL,
			type TEXT NOT NULL CHECK (type IN ('transaction', 'rule', 'event')),
			reference_id INTEGER,
			description TEXT NOT NULL,
			can_revert BOOLEAN DEFAULT FALSE,
			is_reverted BOOLEAN DEFAULT FALSE,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY (user_id) REFERENCES users(id)
		)`,
	}

	for _, query := range queries {
		if _, err := DB.Exec(query); err != nil {
			logger.Error("Failed to create table: " + err.Error())
			return err
		}
	}

	return nil
}

// runMigrations 运行数据库迁移
func runMigrations() error {
	// 检查avatar字段是否存在，如果不存在则添加
	var columnExists bool
	err := DB.QueryRow("PRAGMA table_info(users)").Scan()
	if err != nil {
		// 检查avatar列是否存在
		rows, err := DB.Query("PRAGMA table_info(users)")
		if err != nil {
			return err
		}
		defer rows.Close()

		for rows.Next() {
			var cid int
			var name, dataType string
			var notNull, pk int
			var defaultValue interface{}

			err := rows.Scan(&cid, &name, &dataType, &notNull, &defaultValue, &pk)
			if err != nil {
				return err
			}

			if name == "avatar" {
				columnExists = true
				break
			}
		}

		if !columnExists {
			// 添加avatar字段
			_, err = DB.Exec("ALTER TABLE users ADD COLUMN avatar TEXT")
			if err != nil {
				logger.Error("Failed to add avatar column: " + err.Error())
				return err
			}
			logger.Info("Added avatar column to users table")
		}
	}

	return nil
}
