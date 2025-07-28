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

import { rulesAPI } from '../services/api';
import { colors, commonStyles } from '../styles/theme';
import { useSnackbar } from '../hooks/useSnackbar';
import { showError, showSuccess } from '../utils/notifications';
import CustomSnackbar from '../components/CustomSnackbar';
import { useUser } from '../contexts/UserContext';

export default function RulesScreen() {
  const { userInfo, updateUserPoints } = useUser();
  const [rules, setRules] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [newRule, setNewRule] = useState({
    name: '',
    description: '',
    points: '',
    target_type: 'both',
  });

  const snackbar = useSnackbar();

  useEffect(() => {
    loadRules();
  }, []);

  const loadRules = async () => {
    try {
      const response = await rulesAPI.getRules();
      setRules(response.rules || []);
    } catch (error) {
      console.error('加载规则失败:', error);
      snackbar.showError('加载规则失败');
      showError('加载规则失败');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateRule = async () => {
    if (!newRule.name.trim() || !newRule.points) {
      snackbar.showError('请填写规则名称和积分');
      showError('请填写规则名称和积分');
      return;
    }

    try {
      await rulesAPI.createRule(
        newRule.name.trim(),
        newRule.description.trim(),
        parseInt(newRule.points),
        newRule.target_type
      );
      setShowCreateDialog(false);
      setNewRule({ name: '', description: '', points: '', target_type: 'both' });
      loadRules();
      snackbar.showSuccess('规则创建成功！');
      showSuccess('规则创建成功！');
    } catch (error) {
      const errorMessage = error.response?.data?.error || '创建规则失败';
      snackbar.showError(errorMessage);
      showError(errorMessage);
    }
  };

  const handleExecuteRule = async (rule) => {
    const pointsText = rule.points > 0 ? `+${rule.points}` : `${rule.points}`;
    Alert.alert(
      '执行规则',
      `确定要执行规则 "${rule.name}" 吗？\n积分变化：${pointsText}`,
      [
        { text: '取消', style: 'cancel' },
        {
          text: '执行',
          onPress: async () => {
            try {
              await rulesAPI.executeRule(rule.id);

              // 如果规则影响当前用户，立即更新积分
              if (userInfo && (rule.target_type === 'both' || rule.target_type === 'user1' || rule.target_type === 'user2')) {
                await updateUserPoints(rule.points, `执行规则: ${rule.name}`);
              }

              snackbar.showSuccess('规则执行成功！');
              showSuccess('规则执行成功！');
            } catch (error) {
              const errorMessage = error.response?.data?.error || '执行规则失败';
              snackbar.showError(errorMessage);
              showError(errorMessage);
            }
          },
        },
      ]
    );
  };

  const getTargetTypeText = (targetType) => {
    switch (targetType) {
      case 'user1': return '用户1';
      case 'user2': return '用户2';
      case 'both': return '双方';
      default: return targetType;
    }
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
        <Text style={styles.title}>规则管理</Text>
        
        {rules.length === 0 ? (
          <Card style={commonStyles.card}>
            <Card.Content style={styles.emptyContent}>
              <Ionicons name="list-outline" size={48} color={colors.onSurfaceVariant} />
              <Text style={styles.emptyText}>还没有规则</Text>
              <Text style={styles.emptySubtext}>创建一些积分规则吧！</Text>
            </Card.Content>
          </Card>
        ) : (
          rules.map((rule) => (
            <Card key={rule.id} style={commonStyles.card}>
              <Card.Content>
                <View style={styles.ruleHeader}>
                  <Text style={styles.ruleName}>{rule.name}</Text>
                  <Chip
                    style={[
                      styles.pointsChip,
                      { backgroundColor: getPointsColor(rule.points) + '20' },
                    ]}
                    textStyle={{ color: getPointsColor(rule.points) }}
                  >
                    {rule.points > 0 ? '+' : ''}{rule.points}
                  </Chip>
                </View>
                
                {rule.description && (
                  <Text style={styles.ruleDescription}>{rule.description}</Text>
                )}
                
                <View style={styles.ruleFooter}>
                  <Chip
                    icon="target"
                    style={styles.targetChip}
                    compact
                  >
                    {getTargetTypeText(rule.target_type)}
                  </Chip>
                  <Button
                    mode="contained"
                    onPress={() => handleExecuteRule(rule)}
                    style={styles.executeButton}
                    compact
                  >
                    执行
                  </Button>
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
          <Dialog.Title>创建规则</Dialog.Title>
          <Dialog.Content>
            <TextInput
              label="规则名称"
              value={newRule.name}
              onChangeText={(text) => setNewRule({ ...newRule, name: text })}
              mode="outlined"
              style={styles.input}
            />
            <TextInput
              label="规则描述"
              value={newRule.description}
              onChangeText={(text) => setNewRule({ ...newRule, description: text })}
              mode="outlined"
              style={styles.input}
              multiline
            />
            <TextInput
              label="积分变化（正数为奖励，负数为惩罚）"
              value={newRule.points}
              onChangeText={(text) => setNewRule({ ...newRule, points: text })}
              mode="outlined"
              style={styles.input}
              keyboardType="numeric"
            />
            <Text style={styles.segmentLabel}>适用对象</Text>
            <SegmentedButtons
              value={newRule.target_type}
              onValueChange={(value) => setNewRule({ ...newRule, target_type: value })}
              buttons={[
                { value: 'user1', label: '用户1' },
                { value: 'user2', label: '用户2' },
                { value: 'both', label: '双方' },
              ]}
              style={styles.segmentedButtons}
            />
          </Dialog.Content>
          <Dialog.Actions>
            <Button onPress={() => setShowCreateDialog(false)}>取消</Button>
            <Button onPress={handleCreateRule}>创建</Button>
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
  ruleHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  ruleName: {
    fontSize: 18,
    fontWeight: 'bold',
    color: colors.onSurface,
    flex: 1,
  },
  pointsChip: {
    marginLeft: 8,
  },
  ruleDescription: {
    fontSize: 14,
    color: colors.onSurfaceVariant,
    marginBottom: 12,
  },
  ruleFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  targetChip: {
    backgroundColor: colors.tertiaryContainer,
  },
  executeButton: {
    backgroundColor: colors.primary,
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
    marginTop: 8,
    marginBottom: 8,
  },
  segmentedButtons: {
    marginBottom: 8,
  },
});
