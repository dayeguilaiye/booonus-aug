/// 错误消息处理工具类
class ErrorMessageUtils {
  /// 将原始错误转换为用户友好的错误消息
  static String getErrorMessage(dynamic error) {
    String errorStr = error.toString();
    
    // 移除 Exception: 前缀
    if (errorStr.startsWith('Exception: ')) {
      errorStr = errorStr.substring('Exception: '.length);
    }
    
    // 移除 DioException 前缀
    if (errorStr.startsWith('DioException ')) {
      errorStr = errorStr.substring('DioException '.length);
    }
    
    // 处理常见的错误类型
    if (errorStr.contains('Failed to host lookup') || 
        errorStr.contains('No address associated with hostname') ||
        errorStr.contains('Network is unreachable')) {
      return '网络连接失败，请检查网络设置';
    }
    
    if (errorStr.contains('Connection refused') || 
        errorStr.contains('Connection timed out')) {
      return '服务器连接失败，请稍后重试';
    }
    
    if (errorStr.contains('SocketException')) {
      return '网络异常，请检查网络连接';
    }
    
    if (errorStr.contains('FormatException')) {
      return '数据格式错误';
    }
    
    if (errorStr.contains('TimeoutException')) {
      return '请求超时，请稍后重试';
    }
    
    // 处理 HTTP 状态码错误
    if (errorStr.contains('Http status error [400]')) {
      return '请求参数错误';
    }
    
    if (errorStr.contains('Http status error [401]')) {
      return '身份验证失败，请重新登录';
    }
    
    if (errorStr.contains('Http status error [403]')) {
      return '权限不足';
    }
    
    if (errorStr.contains('Http status error [404]')) {
      return '请求的资源不存在';
    }
    
    if (errorStr.contains('Http status error [500]')) {
      return '服务器内部错误';
    }
    
    if (errorStr.contains('Http status error [502]') || 
        errorStr.contains('Http status error [503]') ||
        errorStr.contains('Http status error [504]')) {
      return '服务器暂时不可用，请稍后重试';
    }
    
    // 处理撤销相关的特定错误
    if (errorStr.contains('This operation cannot be reverted')) {
      return '此操作不支持撤销';
    }
    
    if (errorStr.contains('This operation has already been reverted')) {
      return '此操作已经被撤销过了';
    }
    
    if (errorStr.contains('History record not found')) {
      return '找不到相关记录';
    }
    
    if (errorStr.contains('Permission denied')) {
      return '权限不足，无法执行此操作';
    }
    
    if (errorStr.contains('constraint failed')) {
      return '数据约束错误，操作失败';
    }
    
    // 如果错误信息太长，截取前面部分
    if (errorStr.length > 50) {
      // 尝试提取有用的部分
      if (errorStr.contains(':')) {
        List<String> parts = errorStr.split(':');
        for (String part in parts.reversed) {
          String trimmed = part.trim();
          if (trimmed.isNotEmpty && trimmed.length <= 50) {
            return trimmed;
          }
        }
      }

      // 如果还是太长，截取前50个字符
      return '${errorStr.substring(0, 47)}...';
    }
    
    // 如果错误信息为空或只有空白字符
    if (errorStr.trim().isEmpty) {
      return '操作失败，请稍后重试';
    }
    
    return errorStr;
  }
  
  /// 获取撤销操作的友好错误消息
  static String getUndoErrorMessage(dynamic error) {
    String errorStr = getErrorMessage(error);
    
    // 针对撤销操作的特殊处理
    if (errorStr.contains('constraint failed') || 
        errorStr.contains('CHECK constraint failed')) {
      return '撤销失败，数据状态异常';
    }
    
    if (errorStr.contains('sqlite3')) {
      return '撤销失败，数据库错误';
    }
    
    return errorStr;
  }
}
