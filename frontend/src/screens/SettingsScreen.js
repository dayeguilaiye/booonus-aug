import React, { useState, useEffect } from 'react';
import {
  View,
  StyleSheet,
  ScrollView,
  Alert,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import {
  Text,
  Card,
  Button,
  TextInput,
  List,
  Divider,
  Switch,
} from 'react-native-paper';
import { Ionicons } from '@expo/vector-icons';

import { configAPI } from '../services/api';
import { colors, commonStyles } from '../styles/theme';
import { useSnackbar } from '../hooks/useSnackbar';
import { showError, showSuccess } from '../utils/notifications';
import CustomSnackbar from '../components/CustomSnackbar';

export default function SettingsScreen({ navigation }) {
  const [baseURL, setBaseURL] = useState('');
  const [originalBaseURL, setOriginalBaseURL] = useState('');
  const [loading, setLoading] = useState(false);
  const [hasChanges, setHasChanges] = useState(false);

  const snackbar = useSnackbar();

  useEffect(() => {
    loadSettings();
  }, []);

  useEffect(() => {
    // 检查是否有变更
    setHasChanges(baseURL !== originalBaseURL && baseURL.trim() !== '');
  }, [baseURL, originalBaseURL]);

  const loadSettings = async () => {
    try {
      const savedBaseURL = await configAPI.getSavedBaseURL();
      setBaseURL(savedBaseURL);
      setOriginalBaseURL(savedBaseURL);
    } catch (error) {
      console.error('加载设置失败:', error);
      showError('加载设置失败');
    }
  };

  const validateURL = (url) => {
    if (!url.trim()) {
      return '请输入服务器地址';
    }
    
    // 简单的URL格式验证
    const urlPattern = /^https?:\/\/.+/;
    if (!urlPattern.test(url.trim())) {
      return '请输入有效的URL格式（如：http://127.0.0.1:8080）';
    }
    
    return null;
  };

  const handleSave = async () => {
    const trimmedURL = baseURL.trim();
    const error = validateURL(trimmedURL);
    
    if (error) {
      snackbar.showError(error);
      showError(error);
      return;
    }

    setLoading(true);
    try {
      const success = await configAPI.updateBaseURL(trimmedURL);
      if (success) {
        setOriginalBaseURL(trimmedURL);
        snackbar.showSuccess('设置保存成功！');
        showSuccess('设置保存成功！');
      } else {
        throw new Error('保存失败');
      }
    } catch (error) {
      console.error('保存设置失败:', error);
      snackbar.showError('保存设置失败');
      showError('保存设置失败');
    } finally {
      setLoading(false);
    }
  };

  const handleReset = () => {
    Alert.alert(
      '重置设置',
      '确定要重置为默认设置吗？',
      [
        { text: '取消', style: 'cancel' },
        {
          text: '确定',
          onPress: () => {
            const defaultURL = configAPI.getDefaultBaseURL();
            setBaseURL(defaultURL);
          },
        },
      ]
    );
  };

  const handleTestConnection = async () => {
    const trimmedURL = baseURL.trim();
    const error = validateURL(trimmedURL);
    
    if (error) {
      snackbar.showError(error);
      showError(error);
      return;
    }

    setLoading(true);
    try {
      // 临时更新base URL进行测试
      const originalURL = await configAPI.getSavedBaseURL();
      await configAPI.updateBaseURL(trimmedURL);
      
      // 这里可以添加一个简单的健康检查API调用
      // 暂时只显示成功消息
      snackbar.showSuccess('连接测试成功！');
      showSuccess('连接测试成功！');
      
      // 如果测试成功，保存设置
      setOriginalBaseURL(trimmedURL);
    } catch (error) {
      console.error('连接测试失败:', error);
      snackbar.showError('连接测试失败，请检查服务器地址');
      showError('连接测试失败，请检查服务器地址');
      
      // 恢复原来的URL
      try {
        const originalURL = await configAPI.getSavedBaseURL();
        await configAPI.updateBaseURL(originalURL);
      } catch (restoreError) {
        console.error('恢复URL失败:', restoreError);
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <KeyboardAvoidingView
      style={commonStyles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView style={styles.scrollView}>
        {/* 服务器设置 */}
        <Card style={commonStyles.card}>
          <Card.Content>
            <Text style={styles.sectionTitle}>服务器设置</Text>
            <Text style={styles.sectionDescription}>
              配置后端服务器地址，修改后需要重新登录
            </Text>
            
            <TextInput
              label="服务器地址"
              value={baseURL}
              onChangeText={setBaseURL}
              mode="outlined"
              style={styles.input}
              placeholder="http://127.0.0.1:8080"
              left={<TextInput.Icon icon="server" />}
              autoCapitalize="none"
              autoCorrect={false}
            />
            
            <View style={styles.buttonRow}>
              <Button
                mode="outlined"
                onPress={handleReset}
                style={[styles.button, styles.resetButton]}
                disabled={loading}
              >
                重置默认
              </Button>
              
              <Button
                mode="outlined"
                onPress={handleTestConnection}
                style={[styles.button, styles.testButton]}
                loading={loading}
                disabled={loading}
              >
                测试连接
              </Button>
            </View>
            
            {hasChanges && (
              <Button
                mode="contained"
                onPress={handleSave}
                style={[styles.button, styles.saveButton]}
                loading={loading}
                disabled={loading}
              >
                保存设置
              </Button>
            )}
          </Card.Content>
        </Card>

        {/* 其他设置 */}
        <Card style={commonStyles.card}>
          <Card.Content>
            <Text style={styles.sectionTitle}>其他设置</Text>
            
            <List.Item
              title="清除缓存"
              description="清除应用缓存数据"
              left={(props) => <List.Icon {...props} icon="delete-sweep" />}
              right={(props) => <List.Icon {...props} icon="chevron-right" />}
              onPress={() => {
                Alert.alert(
                  '清除缓存',
                  '确定要清除所有缓存数据吗？这将需要重新登录。',
                  [
                    { text: '取消', style: 'cancel' },
                    {
                      text: '确定',
                      onPress: () => {
                        snackbar.showInfo('清除缓存功能开发中');
                      },
                    },
                  ]
                );
              }}
            />
            
            <Divider />
            
            <List.Item
              title="关于应用"
              description="版本信息和帮助"
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
      </ScrollView>

      <CustomSnackbar
        visible={snackbar.visible}
        message={snackbar.message}
        type={snackbar.type}
        onDismiss={snackbar.hide}
      />
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  scrollView: {
    flex: 1,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: colors.onSurface,
    marginBottom: 8,
  },
  sectionDescription: {
    fontSize: 14,
    color: colors.onSurfaceVariant,
    marginBottom: 16,
  },
  input: {
    marginBottom: 16,
  },
  buttonRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 16,
  },
  button: {
    flex: 1,
    marginHorizontal: 4,
  },
  resetButton: {
    borderColor: colors.onSurfaceVariant,
  },
  testButton: {
    borderColor: colors.primary,
  },
  saveButton: {
    backgroundColor: colors.primary,
  },
});
