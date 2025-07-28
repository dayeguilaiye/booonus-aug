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
  FAB,
  Chip,
  Dialog,
  Portal,
  TextInput,
  SegmentedButtons,
} from 'react-native-paper';
import { Ionicons } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';

import { eventsAPI, coupleAPI } from '../services/api';
import { colors, commonStyles } from '../styles/theme';
import { useSnackbar } from '../hooks/useSnackbar';
import { showError, showSuccess } from '../utils/notifications';
import CustomSnackbar from '../components/CustomSnackbar';
import { useUser } from '../contexts/UserContext';

export default function EventsScreen() {
  const { userInfo: contextUserInfo, updateUserPoints } = useUser();
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [userInfo, setUserInfo] = useState(null);
  const [coupleInfo, setCoupleInfo] = useState(null);
  const [newEvent, setNewEvent] = useState({
    target_id: '',
    name: '',
    description: '',
    points: '',
  });

  const snackbar = useSnackbar();

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      // 获取用户信息
      const storedUserInfo = await AsyncStorage.getItem('userInfo');
      if (storedUserInfo) {
        const user = JSON.parse(storedUserInfo);
        setUserInfo(user);
        setNewEvent(prev => ({ ...prev, target_id: user.id.toString() }));
      }

      // 获取情侣信息
      try {
        const coupleResponse = await coupleAPI.getCouple();
        setCoupleInfo(coupleResponse.couple);
      } catch (error) {
        if (error.response?.status !== 404) {
          console.error('获取情侣信息失败:', error);
        }
      }

      // 获取事件列表
      const eventsResponse = await eventsAPI.getEvents();
      setEvents(eventsResponse.events || []);
    } catch (error) {
      console.error('加载数据失败:', error);
      snackbar.showError('加载数据失败');
      showError('加载数据失败');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateEvent = async () => {
    if (!newEvent.name.trim() || !newEvent.points || !newEvent.target_id) {
      snackbar.showError('请填写完整信息');
      showError('请填写完整信息');
      return;
    }

    try {
      const targetId = parseInt(newEvent.target_id);
      const points = parseInt(newEvent.points);

      await eventsAPI.createEvent(
        targetId,
        newEvent.name.trim(),
        newEvent.description.trim(),
        points
      );

      // 如果目标是当前用户，立即更新积分
      if (contextUserInfo && targetId === contextUserInfo.id) {
        await updateUserPoints(points, `事件: ${newEvent.name.trim()}`);
      }

      setShowCreateDialog(false);
      setNewEvent({
        target_id: userInfo?.id.toString() || '',
        name: '',
        description: '',
        points: '',
      });
      loadData();
      snackbar.showSuccess('事件创建成功！');
      showSuccess('事件创建成功！');
    } catch (error) {
      const errorMessage = error.response?.data?.error || '创建事件失败';
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

  if (!coupleInfo) {
    return (
      <View style={commonStyles.centerContainer}>
        <Ionicons name="heart-outline" size={48} color={colors.onSurfaceVariant} />
        <Text style={styles.noCoupleText}>需要先添加情侣才能使用事件功能</Text>
      </View>
    );
  }

  return (
    <View style={commonStyles.container}>
      <ScrollView style={styles.scrollView}>
        <Text style={styles.title}>事件记录</Text>
        
        {events.length === 0 ? (
          <Card style={commonStyles.card}>
            <Card.Content style={styles.emptyContent}>
              <Ionicons name="calendar-outline" size={48} color={colors.onSurfaceVariant} />
              <Text style={styles.emptyText}>还没有事件</Text>
              <Text style={styles.emptySubtext}>创建一些积分事件吧！</Text>
            </Card.Content>
          </Card>
        ) : (
          events.map((event) => (
            <Card key={event.id} style={commonStyles.card}>
              <Card.Content>
                <View style={styles.eventHeader}>
                  <Text style={styles.eventName}>{event.name}</Text>
                  <Chip
                    style={[
                      styles.pointsChip,
                      { backgroundColor: getPointsColor(event.points) + '20' },
                    ]}
                    textStyle={{ color: getPointsColor(event.points) }}
                  >
                    {event.points > 0 ? '+' : ''}{event.points}
                  </Chip>
                </View>
                
                {event.description && (
                  <Text style={styles.eventDescription}>{event.description}</Text>
                )}
                
                <View style={styles.eventFooter}>
                  <Text style={styles.eventInfo}>
                    {event.creator_name} → {event.target_name}
                  </Text>
                  <Text style={styles.eventDate}>
                    {formatDate(event.created_at)}
                  </Text>
                </View>
              </Card.Content>
            </Card>
          ))
        )}
      </ScrollView>

      <FAB
        icon="plus"
        style={styles.fab}
        onPress={() => setShowCreateDialog(true)}
      />

      <Portal>
        <Dialog visible={showCreateDialog} onDismiss={() => setShowCreateDialog(false)}>
          <Dialog.Title>创建事件</Dialog.Title>
          <Dialog.Content>
            <Text style={styles.segmentLabel}>目标用户</Text>
            <SegmentedButtons
              value={newEvent.target_id}
              onValueChange={(value) => setNewEvent({ ...newEvent, target_id: value })}
              buttons={[
                { 
                  value: userInfo?.id.toString() || '', 
                  label: '我自己' 
                },
                { 
                  value: coupleInfo?.partner.id.toString() || '', 
                  label: coupleInfo?.partner.username || '情侣' 
                },
              ]}
              style={styles.segmentedButtons}
            />
            
            <TextInput
              label="事件名称"
              value={newEvent.name}
              onChangeText={(text) => setNewEvent({ ...newEvent, name: text })}
              mode="outlined"
              style={styles.input}
            />
            <TextInput
              label="事件描述"
              value={newEvent.description}
              onChangeText={(text) => setNewEvent({ ...newEvent, description: text })}
              mode="outlined"
              style={styles.input}
              multiline
            />
            <TextInput
              label="积分变化（正数为奖励，负数为惩罚）"
              value={newEvent.points}
              onChangeText={(text) => setNewEvent({ ...newEvent, points: text })}
              mode="outlined"
              style={styles.input}
              keyboardType="numeric"
            />
          </Dialog.Content>
          <Dialog.Actions>
            <Button onPress={() => setShowCreateDialog(false)}>取消</Button>
            <Button onPress={handleCreateEvent}>创建</Button>
          </Dialog.Actions>
        </Dialog>
      </Portal>

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
  title: {
    ...commonStyles.title,
    marginBottom: 16,
  },
  noCoupleText: {
    fontSize: 16,
    color: colors.onSurfaceVariant,
    textAlign: 'center',
    marginTop: 16,
  },
  emptyContent: {
    alignItems: 'center',
    paddingVertical: 40,
  },
  emptyText: {
    fontSize: 18,
    fontWeight: 'bold',
    color: colors.onSurfaceVariant,
    marginTop: 16,
  },
  emptySubtext: {
    fontSize: 14,
    color: colors.onSurfaceVariant,
    marginTop: 8,
  },
  eventHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  eventName: {
    fontSize: 18,
    fontWeight: 'bold',
    color: colors.onSurface,
    flex: 1,
  },
  pointsChip: {
    marginLeft: 8,
  },
  eventDescription: {
    fontSize: 14,
    color: colors.onSurfaceVariant,
    marginBottom: 12,
  },
  eventFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  eventInfo: {
    fontSize: 12,
    color: colors.onSurfaceVariant,
  },
  eventDate: {
    fontSize: 12,
    color: colors.onSurfaceVariant,
  },
  fab: {
    position: 'absolute',
    margin: 16,
    right: 0,
    bottom: 0,
    backgroundColor: colors.primary,
  },
  input: {
    marginVertical: 4,
  },
  segmentLabel: {
    fontSize: 16,
    color: colors.onSurface,
    marginBottom: 8,
  },
  segmentedButtons: {
    marginBottom: 16,
  },
});
