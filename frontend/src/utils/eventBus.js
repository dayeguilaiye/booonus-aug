/**
 * 简单的事件总线，用于组件间通信
 */
class EventBus {
  constructor() {
    this.events = {};
  }

  // 订阅事件
  on(event, callback) {
    if (!this.events[event]) {
      this.events[event] = [];
    }
    this.events[event].push(callback);

    // 返回取消订阅的函数
    return () => {
      this.off(event, callback);
    };
  }

  // 取消订阅
  off(event, callback) {
    if (!this.events[event]) return;
    
    this.events[event] = this.events[event].filter(cb => cb !== callback);
    
    if (this.events[event].length === 0) {
      delete this.events[event];
    }
  }

  // 触发事件
  emit(event, data) {
    if (!this.events[event]) return;
    
    this.events[event].forEach(callback => {
      try {
        callback(data);
      } catch (error) {
        console.error(`Error in event listener for ${event}:`, error);
      }
    });
  }

  // 清除所有事件监听器
  clear() {
    this.events = {};
  }
}

// 创建全局事件总线实例
const eventBus = new EventBus();

// 定义事件类型常量
export const EVENTS = {
  USER_POINTS_UPDATED: 'USER_POINTS_UPDATED',
  USER_PROFILE_UPDATED: 'USER_PROFILE_UPDATED',
  COUPLE_INFO_UPDATED: 'COUPLE_INFO_UPDATED',
  POINTS_HISTORY_UPDATED: 'POINTS_HISTORY_UPDATED',
};

export default eventBus;
