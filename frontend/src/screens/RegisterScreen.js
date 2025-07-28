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

export default function RegisterScreen({ navigation, onRegisterSuccess }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  // 使用 Snackbar Hook
  const snackbar = useSnackbar();

  const validateForm = () => {
    if (!username.trim()) {
      console.log('验证失败: 用户名为空');
      snackbar.showError('请输入用户名');
      showError('请输入用户名');
      return false;
    }

    if (username.trim().length < 3) {
      console.log('验证失败: 用户名长度不够');
      snackbar.showError('用户名至少需要3个字符');
      showError('用户名至少需要3个字符');
      return false;
    }

    if (!password) {
      console.log('验证失败: 密码为空');
      snackbar.showError('请输入密码');
      showError('请输入密码');
      return false;
    }

    if (password.length < 6) {
      console.log('验证失败: 密码长度不够', password.length);
      snackbar.showError('密码至少需要6个字符');
      showError('密码至少需要6个字符');
      return false;
    }

    if (password !== confirmPassword) {
      console.log('验证失败: 密码不一致');
      snackbar.showError('两次输入的密码不一致');
      showError('两次输入的密码不一致');
      return false;
    }

    console.log('表单验证通过');
    return true;
  };

  const handleRegister = async () => {
    console.log('handleRegister 函数被调用');

    if (!validateForm()) {
      return;
    }

    setLoading(true);
    try {
      const response = await authAPI.register(username.trim(), password);
      
      // 保存token和用户信息
      await AsyncStorage.setItem('userToken', response.token);
      await AsyncStorage.setItem('userInfo', JSON.stringify(response.user));

      // 显示成功提示并跳转
      snackbar.showSuccess('注册成功！欢迎使用Booonus');
      // 通知父组件注册成功，让它更新登录状态
      if (onRegisterSuccess) {
        onRegisterSuccess();
      }
    } catch (error) {
      console.error('注册失败:', error);
      const errorMessage = error.response?.data?.error || '注册失败，请检查网络连接';
      snackbar.showError(errorMessage);
      showError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const goToLogin = () => {
    navigation.navigate('Login');
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
            <Ionicons name="heart-circle" size={80} color={colors.secondary} />
            <Text style={styles.appTitle}>加入Booonus</Text>
            <Text style={styles.appSubtitle}>开始你们的甜蜜积分之旅</Text>
          </View>

          {/* 注册表单 */}
          <Card style={styles.registerCard}>
            <Card.Content>
              <Text style={styles.registerTitle}>创建账号</Text>
              
              <TextInput
                label="用户名"
                value={username}
                onChangeText={setUsername}
                mode="outlined"
                style={commonStyles.input}
                left={<TextInput.Icon icon="account" />}
                autoCapitalize="none"
                autoCorrect={false}
                placeholder="至少3个字符"
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
                placeholder="至少6个字符"
              />

              <TextInput
                label="确认密码"
                value={confirmPassword}
                onChangeText={setConfirmPassword}
                mode="outlined"
                style={commonStyles.input}
                secureTextEntry={!showConfirmPassword}
                left={<TextInput.Icon icon="lock-check" />}
                right={
                  <TextInput.Icon
                    icon={showConfirmPassword ? 'eye-off' : 'eye'}
                    onPress={() => setShowConfirmPassword(!showConfirmPassword)}
                  />
                }
                placeholder="再次输入密码"
              />

              <Button
                mode="contained"
                onPress={handleRegister}
                loading={loading}
                disabled={loading}
                style={[commonStyles.button, styles.registerButton]}
                contentStyle={styles.buttonContent}
              >
                {loading ? '注册中...' : '注册'}
              </Button>

              <Button
                mode="text"
                onPress={goToLogin}
                style={styles.loginButton}
                textColor={colors.secondary}
              >
                已有账号？立即登录
              </Button>
            </Card.Content>
          </Card>

          {/* 装饰元素 */}
          <View style={styles.decorationContainer}>
            <Ionicons name="heart" size={16} color={colors.heart} style={styles.heart1} />
            <Ionicons name="heart" size={12} color={colors.heart} style={styles.heart2} />
            <Ionicons name="star" size={14} color={colors.star} style={styles.star1} />
          </View>
        </View>
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
    fontSize: 28,
    fontWeight: 'bold',
    color: colors.secondary,
    marginTop: 16,
  },
  appSubtitle: {
    fontSize: 16,
    color: colors.onSurfaceVariant,
    marginTop: 8,
    textAlign: 'center',
  },
  registerCard: {
    backgroundColor: colors.surface,
    borderRadius: 20,
    elevation: 4,
    shadowColor: colors.outline,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 8,
  },
  registerTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: colors.onSurface,
    textAlign: 'center',
    marginBottom: 24,
  },
  registerButton: {
    marginTop: 16,
    backgroundColor: colors.secondary,
  },
  buttonContent: {
    paddingVertical: 8,
  },
  loginButton: {
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
  heart1: {
    position: 'absolute',
    top: 120,
    left: 40,
  },
  heart2: {
    position: 'absolute',
    bottom: 200,
    right: 60,
  },
  star1: {
    position: 'absolute',
    top: 180,
    right: 30,
  },
});
