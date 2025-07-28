#!/bin/bash

# Booonus API 测试脚本
BASE_URL="http://localhost:8080/api/v1"

echo "=== Booonus API 测试 ==="

# 测试注册
echo "1. 测试用户注册..."
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "alice",
    "password": "password123"
  }')

echo "注册响应: $REGISTER_RESPONSE"

# 提取token
TOKEN1=$(echo $REGISTER_RESPONSE | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
echo "Alice Token: $TOKEN1"

# 注册第二个用户
echo -e "\n2. 注册第二个用户..."
REGISTER_RESPONSE2=$(curl -s -X POST "$BASE_URL/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "bob",
    "password": "password123"
  }')

echo "注册响应: $REGISTER_RESPONSE2"
TOKEN2=$(echo $REGISTER_RESPONSE2 | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
echo "Bob Token: $TOKEN2"

# 测试登录
echo -e "\n3. 测试用户登录..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "alice",
    "password": "password123"
  }')

echo "登录响应: $LOGIN_RESPONSE"

# 测试获取用户资料
echo -e "\n4. 测试获取用户资料..."
PROFILE_RESPONSE=$(curl -s -X GET "$BASE_URL/profile" \
  -H "Authorization: Bearer $TOKEN1")

echo "用户资料: $PROFILE_RESPONSE"

# 测试邀请情侣
echo -e "\n5. 测试邀请情侣..."
COUPLE_RESPONSE=$(curl -s -X POST "$BASE_URL/couple/invite" \
  -H "Authorization: Bearer $TOKEN1" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "bob"
  }')

echo "邀请情侣响应: $COUPLE_RESPONSE"

# 测试获取情侣信息
echo -e "\n6. 测试获取情侣信息..."
GET_COUPLE_RESPONSE=$(curl -s -X GET "$BASE_URL/couple" \
  -H "Authorization: Bearer $TOKEN1")

echo "情侣信息: $GET_COUPLE_RESPONSE"

# 测试创建小卖部商品
echo -e "\n7. 测试创建小卖部商品..."
SHOP_RESPONSE=$(curl -s -X POST "$BASE_URL/shop" \
  -H "Authorization: Bearer $TOKEN1" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "做饭服务",
    "description": "为你做一顿美味的晚餐",
    "price": 50
  }')

echo "创建商品响应: $SHOP_RESPONSE"

# 测试获取小卖部商品
echo -e "\n8. 测试获取小卖部商品..."
GET_SHOP_RESPONSE=$(curl -s -X GET "$BASE_URL/shop" \
  -H "Authorization: Bearer $TOKEN2")

echo "小卖部商品: $GET_SHOP_RESPONSE"

# 测试创建规则
echo -e "\n9. 测试创建规则..."
RULE_RESPONSE=$(curl -s -X POST "$BASE_URL/rules" \
  -H "Authorization: Bearer $TOKEN1" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "忘记吃药",
    "description": "忘记按时吃药的惩罚",
    "points": -5,
    "target_type": "both"
  }')

echo "创建规则响应: $RULE_RESPONSE"

# 测试获取规则
echo -e "\n10. 测试获取规则..."
GET_RULES_RESPONSE=$(curl -s -X GET "$BASE_URL/rules" \
  -H "Authorization: Bearer $TOKEN2")

echo "规则列表: $GET_RULES_RESPONSE"

echo -e "\n=== 测试完成 ==="
