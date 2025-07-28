import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  StyleSheet,
  ScrollView,
  RefreshControl,
  Alert,
  Platform,
} from 'react-native';
import {
  Text,
  Card,
  Button,
  Avatar,
  Chip,
  FAB,
} from 'react-native-paper';
import { Ionicons } from '@expo/vector-icons';

import { coupleAPI, pointsAPI } from '../services/api';
import { colors, commonStyles } from '../styles/theme';
import { useSnackbar } from '../hooks/useSnackbar';
import { showError, showSuccess, showInfo } from '../utils/notifications';
import CustomSnackbar from '../components/CustomSnackbar';
import InputDialog from '../components/InputDialog';
import { useUser } from '../contexts/UserContext';
import eventBus, { EVENTS } from '../utils/eventBus';

export default function HomeScreen({ navigation }) {
  const { userInfo, refreshUserInfo } = useUser();
  const [coupleInfo, setCoupleInfo] = useState(null);
  const [recentHistory, setRecentHistory] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [showInviteDialog, setShowInviteDialog] = useState(false);

  const snackbar = useSnackbar();

  useEffect(() => {
    loadData();
  }, []);

  // 监听用户信息更新事件
  useEffect(() => {
    const handleUserPointsUpdate = () => {
      // 重新加载最近历史记录
      loadRecentHistory();
    };

    const handleUserProfileUpdate = () => {
      // 重新加载最近历史记录
      loadRecentHistory();
    };

    const unsubscribePoints = eventBus.on(EVENTS.USER_POINTS_UPDATED, handleUserPointsUpdate);
    const unsubscribeProfile = eventBus.on(EVENTS.USER_PROFILE_UPDATED, handleUserProfileUpdate);

    return () => {
      unsubscribePoints();
      unsubscribeProfile();
    };
  }, []);

  // 单独加载最近历史记录的函数
  const loadRecentHistory = async () => {
    try {
      const historyResponse = await pointsAPI.getHistory(5, 0);
      setRecentHistory(historyResponse.history || []);
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

      // 获取最近的积分历史
      try {
        const historyResponse = await pointsAPI.getHistory(5, 0);
        setRecentHistory(historyResponse.history || []);
      } catch (error) {
        console.error('获取积分历史失败:', error);
      }
    } catch (error) {
      console.error('加载数据失败:', error);
      snackbar.showError('加载数据失败，请检查网络连接');
      showError('加载数据失败，请检查网络连接');
    } finally {
      setLoading(false);
    }
  };

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await loadData();
    setRefreshing(false);
  }, []);

  const handleInviteCouple = () => {
    if (Platform.OS === 'web') {
      // Web平台使用原生prompt
      const username = window.prompt('请输入对方的用户名');
      if (!username?.trim()) return;

      inviteUser(username.trim());
    } else {
      // 移动端使用自定义输入对话框
      setShowInviteDialog(true);
    }
  };

  const handleInviteConfirm = (username) => {
    setShowInviteDialog(false);
    if (!username?.trim()) return;
    inviteUser(username.trim());
  };

  const handleInviteCancel = () => {
    setShowInviteDialog(false);
  };

  const inviteUser = async (username) => {
    try {
      await coupleAPI.invite(username);
      snackbar.showSuccess('邀请发送成功！');
      showSuccess('邀请发送成功！');
      loadData(); // 重新加载数据
    } catch (error) {
      const errorMessage = error.response?.data?.error || '邀请失败';
      snackbar.showError(errorMessage);
      showError(errorMessage);
    }
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('zh-CN', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
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
      <ScrollView
        style={styles.scrollView}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
      >
        {/* 用户信息卡片 */}
        <Card style={styles.userCard}>
          <Card.Content style={styles.userCardContent}>
            <Avatar.Icon
              size={60}
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

        {/* 情侣信息卡片 */}
        {coupleInfo ? (
          <Card style={[commonStyles.card, styles.coupleCard]}>
            <Card.Content>
              <View style={styles.coupleHeader}>
                <Ionicons name="heart" size={24} color={colors.heart} />
                <Text style={styles.coupleTitle}>我的情侣</Text>
              </View>
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
                  <View style={styles.partnerPoints}>
                    <Ionicons name="diamond" size={16} color={colors.coin} />
                    <Text style={styles.partnerPointsText}>
                      {coupleInfo.partner.points} 积分
                    </Text>
                  </View>
                </View>
              </View>
            </Card.Content>
          </Card>
        ) : (
          <Card style={[commonStyles.card, styles.noCoupleCard]}>
            <Card.Content style={styles.noCoupleContent}>
              <Ionicons name="heart-outline" size={48} color={colors.onSurfaceVariant} />
              <Text style={styles.noCoupleText}>还没有情侣</Text>
              <Text style={styles.noCoupleSubtext}>邀请你的另一半加入吧！</Text>
              <Button
                mode="contained"
                onPress={handleInviteCouple}
                style={styles.inviteButton}
                icon="heart-plus"
              >
                邀请情侣
              </Button>
            </Card.Content>
          </Card>
        )}

        {/* 最近活动 */}
        {recentHistory.length > 0 && (
          <Card style={commonStyles.card}>
            <Card.Content>
              <Text style={styles.sectionTitle}>最近活动</Text>
              {recentHistory.map((item) => (
                <View key={item.id} style={styles.historyItem}>
                  <View style={styles.historyLeft}>
                    <Text style={styles.historyDescription}>
                      {item.description}
                    </Text>
                    <Text style={styles.historyDate}>
                      {formatDate(item.created_at)}
                    </Text>
                  </View>
                  <Chip
                    style={[
                      styles.pointsChip,
                      { backgroundColor: getPointsColor(item.points) + '20' },
                    ]}
                    textStyle={{ color: getPointsColor(item.points) }}
                  >
                    {item.points > 0 ? '+' : ''}{item.points}
                  </Chip>
                </View>
              ))}
            </Card.Content>
          </Card>
        )}
      </ScrollView>

      {/* 浮动操作按钮 */}
      {coupleInfo && (
        <FAB
          icon="plus"
          style={styles.fab}
          onPress={() => {
            // 这里可以添加快速操作菜单
            // 使用跨平台兼容的方式
            if (Platform.OS === 'web') {
              // Web端显示简单提示
              snackbar.showInfo('请使用底部导航栏访问各功能');
            } else {
              // 移动端显示选择菜单
              Alert.alert(
                '快速操作',
                '选择要执行的操作',
                [
                  { text: '取消', style: 'cancel' },
                  { text: '创建事件', onPress: () => navigation.navigate('Events') },
                  { text: '执行规则', onPress: () => navigation.navigate('Rules') },
                  { text: '购买商品', onPress: () => navigation.navigate('Shop') },
                ]
              );
            }
          }}
        />
      )}

      <CustomSnackbar
        visible={snackbar.visible}
        message={snackbar.message}
        type={snackbar.type}
        onDismiss={snackbar.hide}
      />

      <InputDialog
        visible={showInviteDialog}
        title="邀请情侣"
        message="请输入对方的用户名"
        placeholder="用户名"
        onConfirm={handleInviteConfirm}
        onCancel={handleInviteCancel}
        confirmText="邀请"
        cancelText="取消"
      />
    </View>
  );
}

const styles = StyleSheet.create({
  scrollView: {
    flex: 1,
  },
  userCard: {
    ...commonStyles.card,
    backgroundColor: colors.primaryContainer,
  },
  userCardContent: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  userInfo: {
    marginLeft: 16,
    flex: 1,
  },
  username: {
    fontSize: 20,
    fontWeight: 'bold',
    color: colors.onPrimaryContainer,
  },
  pointsContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 4,
  },
  pointsText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.onPrimaryContainer,
    marginLeft: 4,
  },
  coupleCard: {
    backgroundColor: colors.secondaryContainer,
  },
  coupleHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  coupleTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: colors.onSecondaryContainer,
    marginLeft: 8,
  },
  coupleInfo: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  partnerInfo: {
    marginLeft: 12,
  },
  partnerName: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.onSecondaryContainer,
  },
  partnerPoints: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 4,
  },
  partnerPointsText: {
    fontSize: 14,
    color: colors.onSecondaryContainer,
    marginLeft: 4,
  },
  noCoupleCard: {
    backgroundColor: colors.surfaceVariant,
  },
  noCoupleContent: {
    alignItems: 'center',
    paddingVertical: 20,
  },
  noCoupleText: {
    fontSize: 18,
    fontWeight: 'bold',
    color: colors.onSurfaceVariant,
    marginTop: 12,
  },
  noCoupleSubtext: {
    fontSize: 14,
    color: colors.onSurfaceVariant,
    marginTop: 4,
    marginBottom: 16,
  },
  inviteButton: {
    backgroundColor: colors.primary,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: colors.onSurface,
    marginBottom: 12,
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
  pointsChip: {
    marginLeft: 8,
  },
  fab: {
    position: 'absolute',
    margin: 16,
    right: 0,
    bottom: 0,
    backgroundColor: colors.primary,
  },
});
