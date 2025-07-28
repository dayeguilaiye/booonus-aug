import React, { createContext, useContext, useState, useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { authAPI } from '../services/api';
import eventBus, { EVENTS } from '../utils/eventBus';

const UserContext = createContext();

export const useUser = () => {
  const context = useContext(UserContext);
  if (!context) {
    throw new Error('useUser must be used within a UserProvider');
  }
  return context;
};

export const UserProvider = ({ children }) => {
  const [userInfo, setUserInfo] = useState(null);
  const [loading, setLoading] = useState(true);

  // 从本地存储加载用户信息
  const loadUserFromStorage = async () => {
    try {
      const storedUserInfo = await AsyncStorage.getItem('userInfo');
      if (storedUserInfo) {
        setUserInfo(JSON.parse(storedUserInfo));
      }
    } catch (error) {
      console.error('加载本地用户信息失败:', error);
    }
  };

  // 从服务器刷新用户信息
  const refreshUserInfo = async () => {
    try {
      const response = await authAPI.getProfile();
      const newUserInfo = response.user;

      // 更新状态
      setUserInfo(newUserInfo);

      // 同步到本地存储
      await AsyncStorage.setItem('userInfo', JSON.stringify(newUserInfo));

      // 触发用户信息更新事件
      eventBus.emit(EVENTS.USER_PROFILE_UPDATED, newUserInfo);

      return newUserInfo;
    } catch (error) {
      console.error('刷新用户信息失败:', error);
      throw error;
    }
  };

  // 更新用户积分（本地更新 + 服务器同步）
  const updateUserPoints = async (pointsChange, description) => {
    if (!userInfo) return;

    // 立即更新本地状态（乐观更新）
    const updatedUserInfo = {
      ...userInfo,
      points: userInfo.points + pointsChange
    };
    setUserInfo(updatedUserInfo);

    // 同步到本地存储
    try {
      await AsyncStorage.setItem('userInfo', JSON.stringify(updatedUserInfo));
    } catch (error) {
      console.error('保存用户信息到本地失败:', error);
    }

    // 触发积分更新事件
    eventBus.emit(EVENTS.USER_POINTS_UPDATED, {
      userInfo: updatedUserInfo,
      pointsChange,
      description
    });

    // 从服务器重新获取最新数据以确保一致性
    setTimeout(() => {
      refreshUserInfo().catch(console.error);
    }, 1000);
  };

  // 清除用户信息（退出登录时使用）
  const clearUserInfo = async () => {
    setUserInfo(null);
    try {
      await AsyncStorage.removeItem('userInfo');
    } catch (error) {
      console.error('清除本地用户信息失败:', error);
    }
  };

  // 初始化时加载用户信息
  useEffect(() => {
    const initializeUser = async () => {
      setLoading(true);
      await loadUserFromStorage();
      
      // 如果有token，尝试从服务器刷新用户信息
      try {
        const token = await AsyncStorage.getItem('userToken');
        if (token) {
          await refreshUserInfo();
        }
      } catch (error) {
        console.error('初始化用户信息失败:', error);
      } finally {
        setLoading(false);
      }
    };

    initializeUser();
  }, []);

  const value = {
    userInfo,
    loading,
    refreshUserInfo,
    updateUserPoints,
    clearUserInfo,
  };

  return (
    <UserContext.Provider value={value}>
      {children}
    </UserContext.Provider>
  );
};
