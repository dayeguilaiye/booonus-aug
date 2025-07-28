import React, { useState, useEffect } from 'react';
import {
  View,
  StyleSheet,
  ScrollView,
  Alert,
} from 'react-native';
import {
  Text,
  Card,
  Button,
  Avatar,
  List,
  Divider,
} from 'react-native-paper';
import { Ionicons } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';

import { coupleAPI, pointsAPI } from '../services/api';
import { colors, commonStyles } from '../styles/theme';
import { useSnackbar } from '../hooks/useSnackbar';
import { showError, showSuccess, showInfo } from '../utils/notifications';
import CustomSnackbar from '../components/CustomSnackbar';
import { useUser } from '../contexts/UserContext';
import eventBus, { EVENTS } from '../utils/eventBus';

export default function ProfileScreen({ navigation, onLogout }) {
  const { userInfo, refreshUserInfo, clearUserInfo } = useUser();
  const [coupleInfo, setCoupleInfo] = useState(null);
  const [pointsHistory, setPointsHistory] = useState([]);
  const [loading, setLoading] = useState(true);

  const snackbar = useSnackbar();

  useEffect(() => {
    loadData();
  }, []);

  // 监听用户信息更新事件
  useEffect(() => {
    const handleUserPointsUpdate = () => {
      // 重新加载积分历史
      loadPointsHistory();
    };

    const handleUserProfileUpdate = () => {
      // 重新加载积分历史
      loadPointsHistory();
    };

    const unsubscribePoints = eventBus.on(EVENTS.USER_POINTS_UPDATED, handleUserPointsUpdate);
    const unsubscribeProfile = eventBus.on(EVENTS.USER_PROFILE_UPDATED, handleUserProfileUpdate);

    return () => {
      unsubscribePoints();
      unsubscribeProfile();
    };
  }, []);

  // 单独加载积分历史的函数
  const loadPointsHistory = async () => {
    try {
      const historyResponse = await pointsAPI.getHistory(10, 0);
      setPointsHistory(historyResponse.history || []);
    } catch (error) {
      console.error('获取积分历史失败:', error);
    }
  };

  const loadData = async () => {
    try {
      // 刷新用户信息
      await refreshUserInfo();

      // 获取情侣信息
      try {
        const coupleResponse = await coupleAPI.getCouple();
        setCoupleInfo(coupleResponse.couple);
      } catch (error) {
        if (error.response?.status !== 404) {
          console.error('获取情侣信息失败:', error);
        }
      }

      // 获取积分历史
      try {
        const historyResponse = await pointsAPI.getHistory(10, 0);
        setPointsHistory(historyResponse.history || []);
      } catch (error) {
        console.error('获取积分历史失败:', error);
      }
    } catch (error) {
      console.error('加载数据失败:', error);
      snackbar.showError('加载数据失败');
      showError('加载数据失败');
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = () => {
    Alert.alert(
      '确认退出',
      '确定要退出登录吗？',
      [
        { text: '取消', style: 'cancel' },
        {
          text: '退出',
          style: 'destructive',
          onPress: async () => {
            try {
              await AsyncStorage.removeItem('userToken');
              await clearUserInfo();
              // 通知父组件用户已退出登录
              if (onLogout) {
                onLogout();
              }
            } catch (error) {
              console.error('退出登录失败:', error);
            }
          },
        },
      ]
    );
  };

  const handleRemoveCouple = () => {
    Alert.alert(
      '确认解除',
      '确定要解除情侣关系吗？此操作不可撤销。',
      [
        { text: '取消', style: 'cancel' },
        {
          text: '解除',
          style: 'destructive',
          onPress: async () => {
            try {
              await coupleAPI.removeCouple();
              snackbar.showSuccess('情侣关系已解除');
              showSuccess('情侣关系已解除');
              loadData();
            } catch (error) {
              const errorMessage = error.response?.data?.error || '解除失败';
              snackbar.showError(errorMessage);
              showError(errorMessage);
            }
          },
        },
      ]
    );
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('zh-CN', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  const getPointsColor = (points) => {
    if (points > 0) return colors.success;
    if (points < 0) return colors.error;
    return colors.onSurfaceVariant;
  };

  if (loading) {
    return (
      <View style={commonStyles.centerContainer}>
        <Text>加载中...</Text>
      </View>
    );
  }

  return (
    <View style={commonStyles.container}>
      <ScrollView style={styles.scrollView}>
        {/* 用户信息卡片 */}
        <Card style={styles.profileCard}>
          <Card.Content style={styles.profileContent}>
            <Avatar.Icon
              size={80}
              icon="account"
              style={{ backgroundColor: colors.primary }}
            />
            <View style={styles.userInfo}>
              <Text style={styles.username}>{userInfo?.username}</Text>
              <View style={styles.pointsContainer}>
                <Ionicons name="diamond" size={20} color={colors.coin} />
                <Text style={styles.pointsText}>{userInfo?.points || 0} 积分</Text>
              </View>
            </View>
          </Card.Content>
        </Card>

        {/* 情侣信息 */}
        {coupleInfo && (
          <Card style={commonStyles.card}>
            <Card.Content>
              <Text style={styles.sectionTitle}>情侣信息</Text>
              <View style={styles.coupleInfo}>
                <Avatar.Icon
                  size={50}
                  icon="account-heart"
                  style={{ backgroundColor: colors.secondary }}
                />
                <View style={styles.partnerInfo}>
                  <Text style={styles.partnerName}>
                    {coupleInfo.partner.username}
                  </Text>
                  <Text style={styles.partnerPoints}>
                    {coupleInfo.partner.points} 积分
                  </Text>
                  <Text style={styles.coupleDate}>
                    {formatDate(coupleInfo.created_at)} 开始
                  </Text>
                </View>
              </View>
              <Button
                mode="outlined"
                onPress={handleRemoveCouple}
                style={styles.removeCoupleButton}
                textColor={colors.error}
              >
                解除情侣关系
              </Button>
            </Card.Content>
          </Card>
        )}

        {/* 功能菜单 */}
        <Card style={commonStyles.card}>
          <Card.Content>
            <Text style={styles.sectionTitle}>功能</Text>
            <List.Item
              title="积分历史"
              description="查看详细的积分变化记录"
              left={(props) => <List.Icon {...props} icon="history" />}
              right={(props) => <List.Icon {...props} icon="chevron-right" />}
              onPress={() => {
                snackbar.showInfo('积分历史功能开发中');
                showInfo('积分历史功能开发中');
              }}
            />
            <Divider />
            <List.Item
              title="设置"
              description="应用设置和偏好"
              left={(props) => <List.Icon {...props} icon="cog" />}
              right={(props) => <List.Icon {...props} icon="chevron-right" />}
              onPress={() => {
                navigation.navigate('Settings');
              }}
            />
            <Divider />
            <List.Item
              title="关于"
              description="关于Booonus"
              left={(props) => <List.Icon {...props} icon="information" />}
              right={(props) => <List.Icon {...props} icon="chevron-right" />}
              onPress={() => {
                Alert.alert(
                  '关于Booonus',
                  'Booonus是一个可爱的情侣积分管理应用，帮助情侣们通过积分系统管理日常互动和服务交换。\n\n版本：1.0.0'
                );
              }}
            />
          </Card.Content>
        </Card>

        {/* 最近积分历史 */}
        {pointsHistory.length > 0 && (
          <Card style={commonStyles.card}>
            <Card.Content>
              <Text style={styles.sectionTitle}>最近积分变化</Text>
              {pointsHistory.slice(0, 5).map((item) => (
                <View key={item.id} style={styles.historyItem}>
                  <View style={styles.historyLeft}>
                    <Text style={styles.historyDescription}>
                      {item.description}
                    </Text>
                    <Text style={styles.historyDate}>
                      {formatDate(item.created_at)}
                    </Text>
                  </View>
                  <Text
                    style={[
                      styles.historyPoints,
                      { color: getPointsColor(item.points) },
                    ]}
                  >
                    {item.points > 0 ? '+' : ''}{item.points}
                  </Text>
                </View>
              ))}
            </Card.Content>
          </Card>
        )}

        {/* 退出登录按钮 */}
        <Card style={[commonStyles.card, styles.logoutCard]}>
          <Card.Content>
            <Button
              mode="contained"
              onPress={handleLogout}
              style={styles.logoutButton}
              buttonColor={colors.error}
              textColor={colors.onError}
              icon="logout"
            >
              退出登录
            </Button>
          </Card.Content>
        </Card>
      </ScrollView>

      <CustomSnackbar
        visible={snackbar.visible}
        message={snackbar.message}
        type={snackbar.type}
        onDismiss={snackbar.hide}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  scrollView: {
    flex: 1,
  },
  profileCard: {
    ...commonStyles.card,
    backgroundColor: colors.primaryContainer,
  },
  profileContent: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  userInfo: {
    marginLeft: 20,
    flex: 1,
  },
  username: {
    fontSize: 24,
    fontWeight: 'bold',
    color: colors.onPrimaryContainer,
  },
  pointsContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 8,
  },
  pointsText: {
    fontSize: 18,
    fontWeight: '600',
    color: colors.onPrimaryContainer,
    marginLeft: 4,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: colors.onSurface,
    marginBottom: 12,
  },
  coupleInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
  },
  partnerInfo: {
    marginLeft: 12,
    flex: 1,
  },
  partnerName: {
    fontSize: 18,
    fontWeight: 'bold',
    color: colors.onSurface,
  },
  partnerPoints: {
    fontSize: 14,
    color: colors.onSurfaceVariant,
    marginTop: 2,
  },
  coupleDate: {
    fontSize: 12,
    color: colors.onSurfaceVariant,
    marginTop: 2,
  },
  removeCoupleButton: {
    borderColor: colors.error,
  },
  historyItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: colors.outline,
  },
  historyLeft: {
    flex: 1,
  },
  historyDescription: {
    fontSize: 14,
    color: colors.onSurface,
  },
  historyDate: {
    fontSize: 12,
    color: colors.onSurfaceVariant,
    marginTop: 2,
  },
  historyPoints: {
    fontSize: 16,
    fontWeight: 'bold',
    marginLeft: 8,
  },
  logoutCard: {
    marginBottom: 20,
  },
  logoutButton: {
    paddingVertical: 4,
  },
});
