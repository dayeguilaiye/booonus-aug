# Booonus API 文档

## 基础信息

- **Base URL**: `http://localhost:8080/api/v1`
- **认证方式**: JWT Bearer Token
- **Content-Type**: `application/json`

## 认证

### 注册用户

```http
POST /register
```

**请求体**:
```json
{
  "username": "alice",
  "password": "password123"
}
```

**响应**:
```json
{
  "message": "User created successfully",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "username": "alice",
    "points": 0
  }
}
```

### 用户登录

```http
POST /login
```

**请求体**:
```json
{
  "username": "alice",
  "password": "password123"
}
```

**响应**:
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "username": "alice",
    "points": 100,
    "couple_id": 1
  }
}
```

## 用户管理

### 获取用户资料

```http
GET /profile
Authorization: Bearer <token>
```

**响应**:
```json
{
  "user": {
    "id": 1,
    "username": "alice",
    "points": 100,
    "couple_id": 1
  }
}
```

### 更新用户资料

```http
PUT /profile
Authorization: Bearer <token>
```

**请求体**:
```json
{
  "username": "alice_new"
}
```

## 情侣关系

### 邀请情侣

```http
POST /couple/invite
Authorization: Bearer <token>
```

**请求体**:
```json
{
  "username": "bob"
}
```

**响应**:
```json
{
  "message": "Couple relationship created successfully",
  "couple_id": 1,
  "partner": {
    "id": 2,
    "username": "bob"
  }
}
```

### 获取情侣信息

```http
GET /couple
Authorization: Bearer <token>
```

**响应**:
```json
{
  "couple": {
    "id": 1,
    "created_at": "2023-12-01T10:00:00Z",
    "partner": {
      "id": 2,
      "username": "bob",
      "points": 80
    }
  }
}
```

### 解除情侣关系

```http
DELETE /couple
Authorization: Bearer <token>
```

## 积分管理

### 获取积分

```http
GET /points
Authorization: Bearer <token>
```

**响应**:
```json
{
  "points": 100
}
```

### 获取积分历史

```http
GET /points/history?limit=10&offset=0
Authorization: Bearer <token>
```

**响应**:
```json
{
  "history": [
    {
      "id": 1,
      "user_id": 1,
      "points": 10,
      "type": "event",
      "reference_id": 1,
      "description": "事件: 做家务",
      "can_revert": true,
      "is_reverted": false,
      "created_at": "2023-12-01T10:00:00Z"
    }
  ],
  "total": 25,
  "limit": 10,
  "offset": 0
}
```

### 撤销操作

```http
POST /revert/{history_id}
Authorization: Bearer <token>
```

## 小卖部

### 获取商品列表

```http
GET /shop
Authorization: Bearer <token>
```

**响应**:
```json
{
  "items": [
    {
      "id": 1,
      "user_id": 2,
      "username": "bob",
      "name": "做饭服务",
      "description": "为你做一顿美味的晚餐",
      "price": 50,
      "is_active": true,
      "created_at": "2023-12-01T10:00:00Z"
    }
  ]
}
```

### 创建商品

```http
POST /shop
Authorization: Bearer <token>
```

**请求体**:
```json
{
  "name": "做饭服务",
  "description": "为你做一顿美味的晚餐",
  "price": 50
}
```

### 更新商品

```http
PUT /shop/{item_id}
Authorization: Bearer <token>
```

**请求体**:
```json
{
  "name": "高级做饭服务",
  "price": 80,
  "is_active": true
}
```

### 删除商品

```http
DELETE /shop/{item_id}
Authorization: Bearer <token>
```

### 购买商品

```http
POST /shop/{item_id}/buy
Authorization: Bearer <token>
```

**响应**:
```json
{
  "message": "Purchase completed successfully",
  "transaction_id": 1
}
```

## 规则管理

### 获取规则列表

```http
GET /rules
Authorization: Bearer <token>
```

**响应**:
```json
{
  "rules": [
    {
      "id": 1,
      "couple_id": 1,
      "name": "忘记吃药",
      "description": "忘记按时吃药的惩罚",
      "points": -5,
      "target_type": "both",
      "is_active": true,
      "created_at": "2023-12-01T10:00:00Z"
    }
  ]
}
```

### 创建规则

```http
POST /rules
Authorization: Bearer <token>
```

**请求体**:
```json
{
  "name": "忘记吃药",
  "description": "忘记按时吃药的惩罚",
  "points": -5,
  "target_type": "both"
}
```

### 更新规则

```http
PUT /rules/{rule_id}
Authorization: Bearer <token>
```

### 删除规则

```http
DELETE /rules/{rule_id}
Authorization: Bearer <token>
```

### 执行规则

```http
POST /rules/{rule_id}/execute
Authorization: Bearer <token>
```

**响应**:
```json
{
  "message": "Rule executed successfully",
  "affected_users": 2
}
```

## 事件管理

### 获取事件列表

```http
GET /events?limit=10&offset=0
Authorization: Bearer <token>
```

**响应**:
```json
{
  "events": [
    {
      "id": 1,
      "couple_id": 1,
      "creator_id": 1,
      "creator_name": "alice",
      "target_id": 2,
      "target_name": "bob",
      "name": "做家务",
      "description": "今天主动做了家务",
      "points": 10,
      "created_at": "2023-12-01T10:00:00Z"
    }
  ],
  "total": 15,
  "limit": 10,
  "offset": 0
}
```

### 创建事件

```http
POST /events
Authorization: Bearer <token>
```

**请求体**:
```json
{
  "target_id": 2,
  "name": "做家务",
  "description": "今天主动做了家务",
  "points": 10
}
```

## 错误响应

所有API在出错时都会返回以下格式的错误响应：

```json
{
  "error": "错误描述信息"
}
```

### 常见错误码

- `400 Bad Request`: 请求参数错误
- `401 Unauthorized`: 未认证或token无效
- `403 Forbidden`: 权限不足
- `404 Not Found`: 资源不存在
- `409 Conflict`: 资源冲突（如用户名已存在）
- `500 Internal Server Error`: 服务器内部错误

## 数据类型说明

### 目标类型 (target_type)
- `user1`: 情侣中的第一个用户
- `user2`: 情侣中的第二个用户  
- `both`: 情侣双方

### 积分历史类型 (type)
- `transaction`: 交易产生的积分变化
- `rule`: 规则执行产生的积分变化
- `event`: 事件产生的积分变化
- `revert`: 撤销操作产生的积分变化

### 交易状态 (status)
- `completed`: 已完成
- `cancelled`: 已取消
