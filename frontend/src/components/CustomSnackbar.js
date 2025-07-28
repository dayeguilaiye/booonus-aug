import React from 'react';
import { Snackbar } from 'react-native-paper';
import { colors } from '../styles/theme';

/**
 * 自定义 Snackbar 组件
 * 支持不同类型的消息显示
 */
export const CustomSnackbar = ({ 
  visible, 
  message, 
  type = 'info', 
  onDismiss,
  duration 
}) => {
  const getBackgroundColor = () => {
    switch (type) {
      case 'error':
        return colors.error;
      case 'success':
        return colors.success;
      case 'warning':
        return colors.warning;
      case 'info':
      default:
        return colors.primary;
    }
  };

  const getTextColor = () => {
    switch (type) {
      case 'error':
        return colors.onError;
      case 'success':
        return colors.onSuccess;
      case 'warning':
        return colors.onWarning;
      case 'info':
      default:
        return colors.onPrimary;
    }
  };

  const getDuration = () => {
    if (duration !== undefined) return duration;
    
    switch (type) {
      case 'success':
        return 2000; // 成功消息显示时间短一些
      case 'error':
        return 4000; // 错误消息显示时间长一些
      default:
        return 3000;
    }
  };

  return (
    <Snackbar
      visible={visible}
      onDismiss={onDismiss}
      duration={getDuration()}
      style={{ 
        backgroundColor: getBackgroundColor(),
      }}
      theme={{
        colors: {
          onSurface: getTextColor(),
        }
      }}
    >
      {message}
    </Snackbar>
  );
};

export default CustomSnackbar;
