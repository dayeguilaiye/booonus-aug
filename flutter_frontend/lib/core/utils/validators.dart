class Validators {
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入用户名';
    }
    if (value.trim().length < 3) {
      return '用户名至少需要3个字符';
    }
    if (value.trim().length > 20) {
      return '用户名不能超过20个字符';
    }
    // Check for valid characters (letters, numbers, underscore)
    if (!RegExp(r'^[a-zA-Z0-9_\u4e00-\u9fa5]+$').hasMatch(value.trim())) {
      return '用户名只能包含字母、数字、下划线和中文';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入密码';
    }
    if (value.length < 6) {
      return '密码至少需要6个字符';
    }
    if (value.length > 50) {
      return '密码不能超过50个字符';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return '请确认密码';
    }
    if (value != password) {
      return '两次输入的密码不一致';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '请输入$fieldName';
    }
    return null;
  }

  static String? validatePoints(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入积分';
    }
    final points = int.tryParse(value.trim());
    if (points == null) {
      return '请输入有效的积分数值';
    }
    if (points < -1000 || points > 1000) {
      return '积分范围应在-1000到1000之间';
    }
    return null;
  }

  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入价格';
    }
    final price = int.tryParse(value.trim());
    if (price == null) {
      return '请输入有效的价格';
    }
    if (price < 0) {
      return '价格不能为负数';
    }
    if (price > 10000) {
      return '价格不能超过10000';
    }
    return null;
  }

  static String? validateDescription(String? value, {int maxLength = 200}) {
    if (value == null || value.trim().isEmpty) {
      return '请输入描述';
    }
    if (value.trim().length > maxLength) {
      return '描述不能超过$maxLength个字符';
    }
    return null;
  }

  static String? validateName(String? value, {int maxLength = 50}) {
    if (value == null || value.trim().isEmpty) {
      return '请输入名称';
    }
    if (value.trim().length > maxLength) {
      return '名称不能超过$maxLength个字符';
    }
    return null;
  }

  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入URL';
    }
    
    final urlPattern = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$'
    );
    
    if (!urlPattern.hasMatch(value.trim())) {
      return '请输入有效的URL地址';
    }
    
    return null;
  }
}
