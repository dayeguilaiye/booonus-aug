import { useState } from 'react';

/**
 * Snackbar Hook
 * 提供统一的 Snackbar 状态管理
 */
export const useSnackbar = () => {
  const [visible, setVisible] = useState(false);
  const [message, setMessage] = useState('');
  const [type, setType] = useState('info'); // 'error' | 'success' | 'info' | 'warning'

  const show = (msg, msgType = 'info') => {
    setMessage(msg);
    setType(msgType);
    setVisible(true);
  };

  const showError = (msg) => show(msg, 'error');
  const showSuccess = (msg) => show(msg, 'success');
  const showInfo = (msg) => show(msg, 'info');
  const showWarning = (msg) => show(msg, 'warning');

  const hide = () => {
    setVisible(false);
  };

  return {
    visible,
    message,
    type,
    show,
    showError,
    showSuccess,
    showInfo,
    showWarning,
    hide,
  };
};
