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
} from 'react-native-paper';
import { Ionicons } from '@expo/vector-icons';

import { shopAPI } from '../services/api';
import { colors, commonStyles } from '../styles/theme';
import { useSnackbar } from '../hooks/useSnackbar';
import { showError, showSuccess } from '../utils/notifications';
import CustomSnackbar from '../components/CustomSnackbar';
import { useUser } from '../contexts/UserContext';

export default function ShopScreen() {
  const { userInfo, updateUserPoints } = useUser();
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [newItem, setNewItem] = useState({
    name: '',
    description: '',
    price: '',
  });

  const snackbar = useSnackbar();

  useEffect(() => {
    loadItems();
  }, []);

  const loadItems = async () => {
    try {
      const response = await shopAPI.getItems();
      setItems(response.items || []);
    } catch (error) {
      console.error('加载商品失败:', error);
      snackbar.showError('加载商品失败');
      showError('加载商品失败');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateItem = async () => {
    if (!newItem.name.trim() || !newItem.price) {
      snackbar.showError('请填写商品名称和价格');
      showError('请填写商品名称和价格');
      return;
    }

    try {
      await shopAPI.createItem(
        newItem.name.trim(),
        newItem.description.trim(),
        parseInt(newItem.price)
      );
      setShowCreateDialog(false);
      setNewItem({ name: '', description: '', price: '' });
      loadItems();
      snackbar.showSuccess('商品创建成功！');
      showSuccess('商品创建成功！');
    } catch (error) {
      const errorMessage = error.response?.data?.error || '创建商品失败';
      snackbar.showError(errorMessage);
      showError(errorMessage);
    }
  };

  const handleBuyItem = async (item) => {
    Alert.alert(
      '确认购买',
      `确定要花费 ${item.price} 积分购买 "${item.name}" 吗？`,
      [
        { text: '取消', style: 'cancel' },
        {
          text: '购买',
          onPress: async () => {
            try {
              await shopAPI.buyItem(item.id);

              // 立即更新买家积分（扣除）
              if (userInfo) {
                await updateUserPoints(-item.price, `购买商品: ${item.name}`);
              }

              snackbar.showSuccess('购买成功！');
              showSuccess('购买成功！');
              loadItems();
            } catch (error) {
              const errorMessage = error.response?.data?.error || '购买失败';
              snackbar.showError(errorMessage);
              showError(errorMessage);
            }
          },
        },
      ]
    );
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
        <Text style={styles.title}>小卖部</Text>
        
        {items.length === 0 ? (
          <Card style={commonStyles.card}>
            <Card.Content style={styles.emptyContent}>
              <Ionicons name="storefront-outline" size={48} color={colors.onSurfaceVariant} />
              <Text style={styles.emptyText}>还没有商品</Text>
              <Text style={styles.emptySubtext}>添加一些服务商品吧！</Text>
            </Card.Content>
          </Card>
        ) : (
          items.map((item) => (
            <Card key={item.id} style={commonStyles.card}>
              <Card.Content>
                <View style={styles.itemHeader}>
                  <Text style={styles.itemName}>{item.name}</Text>
                  <Chip
                    icon="diamond"
                    style={styles.priceChip}
                    textStyle={styles.priceText}
                  >
                    {item.price}
                  </Chip>
                </View>
                
                {item.description && (
                  <Text style={styles.itemDescription}>{item.description}</Text>
                )}
                
                <View style={styles.itemFooter}>
                  <Text style={styles.sellerName}>by {item.username}</Text>
                  <Button
                    mode="contained"
                    onPress={() => handleBuyItem(item)}
                    style={styles.buyButton}
                    compact
                  >
                    购买
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
          <Dialog.Title>添加商品</Dialog.Title>
          <Dialog.Content>
            <TextInput
              label="商品名称"
              value={newItem.name}
              onChangeText={(text) => setNewItem({ ...newItem, name: text })}
              mode="outlined"
              style={styles.input}
            />
            <TextInput
              label="商品描述"
              value={newItem.description}
              onChangeText={(text) => setNewItem({ ...newItem, description: text })}
              mode="outlined"
              style={styles.input}
              multiline
            />
            <TextInput
              label="价格（积分）"
              value={newItem.price}
              onChangeText={(text) => setNewItem({ ...newItem, price: text })}
              mode="outlined"
              style={styles.input}
              keyboardType="numeric"
            />
          </Dialog.Content>
          <Dialog.Actions>
            <Button onPress={() => setShowCreateDialog(false)}>取消</Button>
            <Button onPress={handleCreateItem}>创建</Button>
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
  itemHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  itemName: {
    fontSize: 18,
    fontWeight: 'bold',
    color: colors.onSurface,
    flex: 1,
  },
  priceChip: {
    backgroundColor: colors.primaryContainer,
  },
  priceText: {
    color: colors.onPrimaryContainer,
    fontWeight: 'bold',
  },
  itemDescription: {
    fontSize: 14,
    color: colors.onSurfaceVariant,
    marginBottom: 12,
  },
  itemFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  sellerName: {
    fontSize: 12,
    color: colors.onSurfaceVariant,
  },
  buyButton: {
    backgroundColor: colors.secondary,
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
});
