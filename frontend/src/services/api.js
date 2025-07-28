import axios from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';

// 默认API基础URL
const DEFAULT_BASE_URL = 'http://192.168.31.248:8080';

// 获取当前配置的base URL
const getBaseURL = async () => {
  try {
    const savedBaseURL = await AsyncStorage.getItem('api_base_url');
    return savedBaseURL ? `${savedBaseURL}/api/v1` : `${DEFAULT_BASE_URL}/api/v1`;
  } catch (error) {
    console.error('获取base URL失败:', error);
    return `${DEFAULT_BASE_URL}/api/v1`;
  }
};

// 创建axios实例
const api = axios.create({
  baseURL: `${DEFAULT_BASE_URL}/api/v1`,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// 初始化API配置
const initializeAPI = async () => {
  const baseURL = await getBaseURL();
  api.defaults.baseURL = baseURL;
};

// 更新API base URL
const updateBaseURL = async (newBaseURL) => {
  try {
    // 保存到本地存储
    await AsyncStorage.setItem('api_base_url', newBaseURL);
    // 更新axios实例
    api.defaults.baseURL = `${newBaseURL}/api/v1`;
    return true;
  } catch (error) {
    console.error('更新base URL失败:', error);
    return false;
  }
};

// 获取当前保存的base URL（不包含/api/v1）
const getSavedBaseURL = async () => {
  try {
    const savedBaseURL = await AsyncStorage.getItem('api_base_url');
    return savedBaseURL || DEFAULT_BASE_URL;
  } catch (error) {
    console.error('获取保存的base URL失败:', error);
    return DEFAULT_BASE_URL;
  }
};

// 应用启动时初始化API
initializeAPI();

// 请求拦截器 - 自动添加token
api.interceptors.request.use(
  async (config) => {
    try {
      const token = await AsyncStorage.getItem('userToken');
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
    } catch (error) {
      console.error('获取token失败:', error);
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// 响应拦截器 - 处理错误
api.interceptors.response.use(
  (response) => {
    return response;
  },
  async (error) => {
    if (error.response?.status === 401) {
      // token过期或无效，清除本地存储并跳转到登录页
      await AsyncStorage.removeItem('userToken');
      await AsyncStorage.removeItem('userInfo');
      // 这里可以添加导航到登录页的逻辑
    }
    return Promise.reject(error);
  }
);

// 用户认证相关API
export const authAPI = {
  // 注册
  register: async (username, password) => {
    const response = await api.post('/register', { username, password });
    return response.data;
  },

  // 登录
  login: async (username, password) => {
    const response = await api.post('/login', { username, password });
    return response.data;
  },

  // 获取用户资料
  getProfile: async () => {
    const response = await api.get('/profile');
    return response.data;
  },

  // 更新用户资料
  updateProfile: async (username) => {
    const response = await api.put('/profile', { username });
    return response.data;
  },
};

// 情侣关系相关API
export const coupleAPI = {
  // 邀请情侣
  invite: async (username) => {
    const response = await api.post('/couple/invite', { username });
    return response.data;
  },

  // 获取情侣信息
  getCouple: async () => {
    const response = await api.get('/couple');
    return response.data;
  },

  // 解除情侣关系
  removeCouple: async () => {
    const response = await api.delete('/couple');
    return response.data;
  },
};

// 积分相关API
export const pointsAPI = {
  // 获取积分
  getPoints: async () => {
    const response = await api.get('/points');
    return response.data;
  },

  // 获取积分历史
  getHistory: async (limit = 50, offset = 0) => {
    const response = await api.get(`/points/history?limit=${limit}&offset=${offset}`);
    return response.data;
  },

  // 撤销操作
  revert: async (historyId) => {
    const response = await api.post(`/revert/${historyId}`);
    return response.data;
  },
};

// 小卖部相关API
export const shopAPI = {
  // 获取商品列表
  getItems: async (ownerId = null) => {
    const url = ownerId ? `/shop?owner_id=${ownerId}` : '/shop';
    const response = await api.get(url);
    return response.data;
  },

  // 创建商品
  createItem: async (name, description, price) => {
    const response = await api.post('/shop', { name, description, price });
    return response.data;
  },

  // 更新商品
  updateItem: async (itemId, data) => {
    const response = await api.put(`/shop/${itemId}`, data);
    return response.data;
  },

  // 删除商品
  deleteItem: async (itemId) => {
    const response = await api.delete(`/shop/${itemId}`);
    return response.data;
  },

  // 购买商品
  buyItem: async (itemId) => {
    const response = await api.post(`/shop/${itemId}/buy`);
    return response.data;
  },
};

// 规则相关API
export const rulesAPI = {
  // 获取规则列表
  getRules: async () => {
    const response = await api.get('/rules');
    return response.data;
  },

  // 创建规则
  createRule: async (name, description, points, targetType) => {
    const response = await api.post('/rules', { name, description, points, target_type: targetType });
    return response.data;
  },

  // 更新规则
  updateRule: async (ruleId, data) => {
    const response = await api.put(`/rules/${ruleId}`, data);
    return response.data;
  },

  // 删除规则
  deleteRule: async (ruleId) => {
    const response = await api.delete(`/rules/${ruleId}`);
    return response.data;
  },

  // 执行规则
  executeRule: async (ruleId) => {
    const response = await api.post(`/rules/${ruleId}/execute`);
    return response.data;
  },
};

// 事件相关API
export const eventsAPI = {
  // 获取事件列表
  getEvents: async (limit = 50, offset = 0) => {
    const response = await api.get(`/events?limit=${limit}&offset=${offset}`);
    return response.data;
  },

  // 创建事件
  createEvent: async (targetId, name, description, points) => {
    const response = await api.post('/events', { target_id: targetId, name, description, points });
    return response.data;
  },
};

// 配置相关API
export const configAPI = {
  // 更新base URL
  updateBaseURL,
  // 获取当前保存的base URL
  getSavedBaseURL,
  // 获取默认base URL
  getDefaultBaseURL: () => DEFAULT_BASE_URL,
};

export default api;
