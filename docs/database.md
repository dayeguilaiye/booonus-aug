# Booonus 数据库设计

## 概述

Booonus 使用 SQLite 作为数据库，包含以下主要表：

- `users` - 用户信息
- `couples` - 情侣关系
- `shop_items` - 小卖部商品
- `rules` - 积分规则
- `events` - 积分事件
- `transactions` - 交易记录
- `points_history` - 积分变化历史

## 表结构

### users (用户表)

存储用户基本信息和积分。

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    points INTEGER DEFAULT 0,
    couple_id INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

**字段说明**:
- `id`: 用户唯一标识
- `username`: 用户名，全局唯一
- `password`: 加密后的密码
- `points`: 当前积分
- `couple_id`: 关联的情侣关系ID，可为空
- `created_at`: 创建时间
- `updated_at`: 更新时间

### couples (情侣关系表)

存储情侣关系信息。

```sql
CREATE TABLE couples (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user1_id INTEGER NOT NULL,
    user2_id INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user1_id) REFERENCES users(id),
    FOREIGN KEY (user2_id) REFERENCES users(id)
);
```

**字段说明**:
- `id`: 情侣关系唯一标识
- `user1_id`: 第一个用户ID
- `user2_id`: 第二个用户ID
- `created_at`: 建立关系时间

**约束**:
- 一个用户只能有一个情侣关系
- 不能与自己建立情侣关系

### shop_items (小卖部商品表)

存储用户发布的服务商品。

```sql
CREATE TABLE shop_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    price INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**字段说明**:
- `id`: 商品唯一标识
- `user_id`: 商品发布者ID
- `name`: 商品名称
- `description`: 商品描述
- `price`: 商品价格（积分）
- `is_active`: 是否激活
- `created_at`: 创建时间
- `updated_at`: 更新时间

### rules (规则表)

存储情侣间的积分规则。

```sql
CREATE TABLE rules (
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
);
```

**字段说明**:
- `id`: 规则唯一标识
- `couple_id`: 所属情侣关系ID
- `name`: 规则名称
- `description`: 规则描述
- `points`: 积分变化（正数为奖励，负数为惩罚）
- `target_type`: 适用对象（user1/user2/both）
- `is_active`: 是否激活
- `created_at`: 创建时间
- `updated_at`: 更新时间

### events (事件表)

存储手动创建的积分事件。

```sql
CREATE TABLE events (
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
);
```

**字段说明**:
- `id`: 事件唯一标识
- `couple_id`: 所属情侣关系ID
- `creator_id`: 事件创建者ID
- `target_id`: 事件目标用户ID
- `name`: 事件名称
- `description`: 事件描述
- `points`: 积分变化
- `created_at`: 创建时间

### transactions (交易表)

存储小卖部商品交易记录。

```sql
CREATE TABLE transactions (
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
);
```

**字段说明**:
- `id`: 交易唯一标识
- `buyer_id`: 买家用户ID
- `seller_id`: 卖家用户ID
- `shop_item_id`: 商品ID
- `points`: 交易积分
- `status`: 交易状态
- `created_at`: 交易时间

### points_history (积分历史表)

记录所有积分变化的详细历史。

```sql
CREATE TABLE points_history (
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
);
```

**字段说明**:
- `id`: 历史记录唯一标识
- `user_id`: 用户ID
- `points`: 积分变化量
- `type`: 变化类型（transaction/rule/event/revert）
- `reference_id`: 关联记录ID
- `description`: 变化描述
- `can_revert`: 是否可撤销
- `is_reverted`: 是否已撤销
- `created_at`: 记录时间

## 关系图

```
users (1) ←→ (1) couples (1) ←→ (1) users
  ↓                              ↓
  (1)                            (1)
  ↓                              ↓
shop_items                     rules
  ↓                              ↓
  (1)                            (1)
  ↓                              ↓
transactions                   events
  ↓                              ↓
  (1)                            (1)
  ↓                              ↓
points_history ←←←←←←←←←←←←←←←←←←←←←
```

## 索引建议

为了提高查询性能，建议创建以下索引：

```sql
-- 用户表索引
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_couple_id ON users(couple_id);

-- 情侣关系表索引
CREATE INDEX idx_couples_user1_id ON couples(user1_id);
CREATE INDEX idx_couples_user2_id ON couples(user2_id);

-- 商品表索引
CREATE INDEX idx_shop_items_user_id ON shop_items(user_id);
CREATE INDEX idx_shop_items_is_active ON shop_items(is_active);

-- 规则表索引
CREATE INDEX idx_rules_couple_id ON rules(couple_id);
CREATE INDEX idx_rules_is_active ON rules(is_active);

-- 事件表索引
CREATE INDEX idx_events_couple_id ON events(couple_id);
CREATE INDEX idx_events_creator_id ON events(creator_id);
CREATE INDEX idx_events_target_id ON events(target_id);

-- 交易表索引
CREATE INDEX idx_transactions_buyer_id ON transactions(buyer_id);
CREATE INDEX idx_transactions_seller_id ON transactions(seller_id);

-- 积分历史表索引
CREATE INDEX idx_points_history_user_id ON points_history(user_id);
CREATE INDEX idx_points_history_type ON points_history(type);
CREATE INDEX idx_points_history_created_at ON points_history(created_at);
```

## 数据完整性

### 外键约束

所有外键关系都已在表定义中声明，确保数据的引用完整性。

### 检查约束

- `rules.target_type`: 只能是 'user1', 'user2', 'both'
- `transactions.status`: 只能是 'completed', 'cancelled'
- `points_history.type`: 只能是 'transaction', 'rule', 'event'

### 业务逻辑约束

- 用户不能与自己建立情侣关系
- 用户只能有一个活跃的情侣关系
- 用户不能购买自己的商品
- 只有情侣间才能进行交易和创建规则/事件

## 数据迁移

如果需要修改表结构，建议使用以下步骤：

1. 创建新表结构
2. 迁移现有数据
3. 删除旧表
4. 重命名新表
5. 重建索引

## 备份策略

建议定期备份数据库：

```bash
# 每日备份
sqlite3 booonus.db ".backup backup/booonus_$(date +%Y%m%d).db"

# 压缩备份
sqlite3 booonus.db ".backup - | gzip > backup/booonus_$(date +%Y%m%d).db.gz"
```
