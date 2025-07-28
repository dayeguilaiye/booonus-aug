import React, { useState } from 'react';
import {
  View,
  StyleSheet,
  Alert,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
} from 'react-native';
import {
  Text,
  TextInput,
  Button,
  Card,
  ActivityIndicator,
} from 'react-native-paper';
import { Ionicons } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';

import { authAPI } from '../services/api';
import { colors, commonStyles } from '../styles/theme';
import { useSnackbar } from '../hooks/useSnackbar';
import { showError } from '../utils/notifications';
import CustomSnackbar from '../components/CustomSnackbar';

export default function LoginScreen({ navigation, onLoginSuccess }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const snackbar = useSnackbar();

  const handleLogin = async () => {
    if (!username.trim() || !password.trim()) {
      snackbar.showError('请输入用户名和密码');
      showError('请输入用户名和密码');
      return;
    }

    setLoading(true);
    try {
      const response = await authAPI.login(username.trim(), password);

      // 保存token和用户信息
      await AsyncStorage.setItem('userToken', response.token);
      await AsyncStorage.setItem('userInfo', JSON.stringify(response.user));

      snackbar.showSuccess('登录成功！');
      // 通知父组件登录成功，让它更新登录状态
      if (onLoginSuccess) {
        onLoginSuccess();
      }
    } catch (error) {
      console.error('登录失败:', error);
      const errorMessage = error.response?.data?.error || '登录失败，请检查网络连接';
      snackbar.showError(errorMessage);
      showError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const goToRegister = () => {
    navigation.navigate('Register');
  };

  return (
    <KeyboardAvoidingView
      style={commonStyles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView contentContainerStyle={styles.scrollContainer}>
        <View style={styles.container}>
          {/* Logo区域 */}
          <View style={styles.logoContainer}>
            <Ionicons name="heart" size={80} color={colors.heart} />
            <Text style={styles.appTitle}>Booonus</Text>
            <Text style={styles.appSubtitle}>情侣积分管理</Text>
          </View>

          {/* 登录表单 */}
          <Card style={styles.loginCard}>
            <Card.Content>
              <Text style={styles.loginTitle}>欢迎回来</Text>
              
              <TextInput
                label="用户名"
                value={username}
                onChangeText={setUsername}
                mode="outlined"
                style={commonStyles.input}
                left={<TextInput.Icon icon="account" />}
                autoCapitalize="none"
                autoCorrect={false}
              />

              <TextInput
                label="密码"
                value={password}
                onChangeText={setPassword}
                mode="outlined"
                style={commonStyles.input}
                secureTextEntry={!showPassword}
                left={<TextInput.Icon icon="lock" />}
                right={
                  <TextInput.Icon
                    icon={showPassword ? 'eye-off' : 'eye'}
                    onPress={() => setShowPassword(!showPassword)}
                  />
                }
              />

              <Button
                mode="contained"
                onPress={handleLogin}
                loading={loading}
                disabled={loading}
                style={[commonStyles.button, styles.loginButton]}
                contentStyle={styles.buttonContent}
              >
                {loading ? '登录中...' : '登录'}
              </Button>

              <Button
                mode="text"
                onPress={goToRegister}
                style={styles.registerButton}
                textColor={colors.primary}
              >
                还没有账号？立即注册
              </Button>
            </Card.Content>
          </Card>

          {/* 装饰元素 */}
          <View style={styles.decorationContainer}>
            <Ionicons name="star" size={20} color={colors.star} style={styles.star1} />
            <Ionicons name="star" size={16} color={colors.star} style={styles.star2} />
            <Ionicons name="star" size={12} color={colors.star} style={styles.star3} />
          </View>
        </View>
      </ScrollView>

      {/* 设置按钮 */}
      <View style={styles.settingsButtonContainer}>
        <Button
          mode="text"
          onPress={() => navigation.navigate('Settings')}
          style={styles.settingsButton}
          contentStyle={styles.settingsButtonContent}
          labelStyle={styles.settingsButtonLabel}
        >
          <Ionicons name="settings-outline" size={16} color={colors.onSurfaceVariant} />
          {' 设置'}
        </Button>
      </View>

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
  scrollContainer: {
    flexGrow: 1,
  },
  container: {
    flex: 1,
    justifyContent: 'center',
    padding: 20,
    backgroundColor: colors.background,
  },
  logoContainer: {
    alignItems: 'center',
    marginBottom: 40,
  },
  appTitle: {
    fontSize: 32,
    fontWeight: 'bold',
    color: colors.primary,
    marginTop: 16,
  },
  appSubtitle: {
    fontSize: 16,
    color: colors.onSurfaceVariant,
    marginTop: 8,
  },
  loginCard: {
    backgroundColor: colors.surface,
    borderRadius: 20,
    elevation: 4,
    shadowColor: colors.outline,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 8,
  },
  loginTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: colors.onSurface,
    textAlign: 'center',
    marginBottom: 24,
  },
  loginButton: {
    marginTop: 16,
    backgroundColor: colors.primary,
  },
  buttonContent: {
    paddingVertical: 8,
  },
  registerButton: {
    marginTop: 16,
  },
  decorationContainer: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    pointerEvents: 'none',
  },
  star1: {
    position: 'absolute',
    top: 100,
    right: 50,
  },
  star2: {
    position: 'absolute',
    top: 200,
    left: 30,
  },
  star3: {
    position: 'absolute',
    bottom: 150,
    right: 80,
  },
  settingsButtonContainer: {
    position: 'absolute',
    bottom: 40,
    right: 20,
  },
  settingsButton: {
    minWidth: 0,
  },
  settingsButtonContent: {
    paddingHorizontal: 8,
    paddingVertical: 4,
  },
  settingsButtonLabel: {
    fontSize: 12,
    color: colors.onSurfaceVariant,
  },
});
