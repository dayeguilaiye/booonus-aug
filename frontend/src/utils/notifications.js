import { Alert, Platform } from 'react-native';

/**
 * 跨平台提示工具
 * 在移动端显示 Alert，在 Web 端使用 console 和回调
 */
export class CrossPlatformNotifications {
  static showMessage(title, message, type = 'info', onConfirm = null) {
    console.log(`${type.toUpperCase()}: ${title} - ${message}`);
    
    if (Platform.OS !== 'web') {
      // 移动端：显示 Alert
      if (onConfirm) {
        Alert.alert(title, message, [
          { text: '确定', onPress: onConfirm }
        ]);
      } else {
        Alert.alert(title, message);
      }
    } else {
      // Web 端：使用 console 和延迟回调
      if (type === 'error') {
        console.error(`${title}: ${message}`);
      } else if (type === 'success') {
        console.log(`✅ ${title}: ${message}`);
      } else {
        console.info(`ℹ️ ${title}: ${message}`);
      }
      
      if (onConfirm) {
        // Web 端延迟执行回调，给用户时间看到 Snackbar
        setTimeout(onConfirm, type === 'success' ? 2000 : 3000);
      }
    }
  }

  static showError(message, onConfirm = null) {
    this.showMessage('错误', message, 'error', onConfirm);
  }

  static showSuccess(message, onConfirm = null) {
    this.showMessage('成功', message, 'success', onConfirm);
  }

  static showInfo(message, onConfirm = null) {
    this.showMessage('提示', message, 'info', onConfirm);
  }

  static showWarning(message, onConfirm = null) {
    this.showMessage('警告', message, 'warning', onConfirm);
  }
}

/**
 * 简化的函数导出
 */
export const showError = (message, onConfirm = null) => {
  CrossPlatformNotifications.showError(message, onConfirm);
};

export const showSuccess = (message, onConfirm = null) => {
  CrossPlatformNotifications.showSuccess(message, onConfirm);
};

export const showInfo = (message, onConfirm = null) => {
  CrossPlatformNotifications.showInfo(message, onConfirm);
};

export const showWarning = (message, onConfirm = null) => {
  CrossPlatformNotifications.showWarning(message, onConfirm);
};

export default CrossPlatformNotifications;
