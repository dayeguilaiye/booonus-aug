import 'package:flutter/material.dart';
import '../../core/models/rule.dart';
import '../../core/models/shop_item.dart';
import '../../core/models/couple.dart';
import '../../core/models/user.dart';
import '../../core/theme/app_colors.dart';

/// A4纸大小的导出页面组件
/// 用于生成截图，不会实际显示给用户
class ExportPageWidget extends StatelessWidget {
  final List<Rule> rules;
  final List<ShopItem> currentUserShops;
  final List<ShopItem> partnerShops;
  final User currentUser;
  final Couple? couple;

  const ExportPageWidget({
    super.key,
    required this.rules,
    required this.currentUserShops,
    required this.partnerShops,
    required this.currentUser,
    this.couple,
  });

  @override
  Widget build(BuildContext context) {
    // A4纸比例：210mm x 297mm ≈ 1:1.414
    const double a4Width = 794; // 约等于A4纸宽度的像素
    const double a4Height = 1123; // 约等于A4纸高度的像素

    return Container(
      width: a4Width,
      height: a4Height,
      color: const Color(0xFFF8FAFC), // 浅蓝灰色背景
      child: Padding(
        padding: const EdgeInsets.all(20), // 减小外边距
        child: Column(
          children: [
            // 标题部分
            _buildHeader(),
            const SizedBox(height: 16), // 减小间距

            // 约定部分
            Expanded(
              flex: 3,
              child: _buildRulesSection(),
            ),

            const SizedBox(height: 12), // 减小间距

            // 商品部分
            Expanded(
              flex: 2,
              child: _buildShopsSection(),
            ),

            const SizedBox(height: 8), // 减小间距

            // 页脚
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12), // 减小内边距
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0E7FF), Color(0xFFF3E8FF)],
        ),
        borderRadius: BorderRadius.circular(8), // 减小圆角
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4, // 减小阴影
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '💖 小小卖部开张咯 💖',
            style: TextStyle(
              fontSize: 20, // 减小字体
              fontWeight: FontWeight.w900,
              color: Color(0xFF4338CA),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4), // 减小间距
          const Text(
            '努力积分，享受生活！',
            style: TextStyle(
              fontSize: 12, // 减小字体
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRulesSection() {
    // 按目标类型分组规则
    final bothRules = rules.where((r) => r.targetType == 'both').toList();
    final currentUserRules = rules.where((r) => r.targetType == 'current_user').toList();
    final partnerRules = rules.where((r) => r.targetType == 'partner').toList();

    return Column(
      children: [
        const Text(
          '📝 积分约定',
          style: TextStyle(
            fontSize: 16, // 减小字体
            fontWeight: FontWeight.bold,
            color: Color(0xFF374151),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8), // 减小间距
        Expanded(
          child: Row(
            children: [
              // 双方约定
              Expanded(
                child: _buildRuleCard(
                  title: '对双方生效的',
                  rules: bothRules,
                  borderColor: const Color(0xFFC7D2FE),
                ),
              ),
              const SizedBox(width: 8), // 减小间距
              // 当前用户约定
              Expanded(
                child: _buildRuleCard(
                  title: '对${currentUser.username}生效的',
                  rules: currentUserRules,
                  borderColor: const Color(0xFFFCE7F3),
                ),
              ),
              const SizedBox(width: 8), // 减小间距
              // 伴侣约定
              Expanded(
                child: _buildRuleCard(
                  title: '对${couple?.partner.username ?? '对方'}生效的',
                  rules: partnerRules,
                  borderColor: const Color(0xFFD1FAE5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRuleCard({
    required String title,
    required List<Rule> rules,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(8), // 减小内边距
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6), // 减小圆角
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4, // 减小阴影
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 4), // 减小内边距
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor, width: 1), // 减小边框宽度
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12, // 减小字体
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(height: 6), // 减小间距
          Expanded(
            child: Column(
              children: [
                for (int index = 0; index < rules.length; index++) ...[
                  if (index > 0) const SizedBox(height: 4), // 减小间距
                  _buildRuleItem(rules[index]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopsSection() {
    return Column(
      children: [
        const Text(
          '🎁 兑换商品',
          style: TextStyle(
            fontSize: 16, // 减小字体
            fontWeight: FontWeight.bold,
            color: Color(0xFF374151),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8), // 减小间距
        Expanded(
          child: Row(
            children: [
              // 当前用户商品
              Expanded(
                child: _buildShopCard(
                  title: '${currentUser.username}的商品',
                  shops: currentUserShops,
                  borderColor: const Color(0xFFFED7AA),
                ),
              ),
              const SizedBox(width: 8), // 减小间距
              // 伴侣商品
              Expanded(
                child: _buildShopCard(
                  title: '${couple?.partner.username ?? '对方'}的商品',
                  shops: partnerShops,
                  borderColor: const Color(0xFFBAE6FD),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShopCard({
    required String title,
    required List<ShopItem> shops,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(8), // 减小内边距
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6), // 减小圆角
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4, // 减小阴影
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 4), // 减小内边距
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor, width: 1), // 减小边框宽度
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12, // 减小字体
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(height: 6), // 减小间距
          Expanded(
            child: Column(
              children: [
                for (int index = 0; index < shops.length; index++) ...[
                  if (index > 0) const SizedBox(height: 4), // 减小间距
                  _buildShopItem(shops[index]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(Rule rule) {
    final pointsText = rule.points > 0 ? '+${rule.points}' : '${rule.points}';
    final pointsColor = rule.points > 0
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            rule.name,
            style: const TextStyle(
              fontSize: 10, // 减小字体
              color: Color(0xFF374151),
            ),
          ),
        ),
        Text(
          pointsText,
          style: TextStyle(
            fontSize: 10, // 减小字体
            fontWeight: FontWeight.w600,
            color: pointsColor,
          ),
        ),
      ],
    );
  }

  Widget _buildShopItem(ShopItem shop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            shop.name,
            style: const TextStyle(
              fontSize: 10, // 减小字体
              color: Color(0xFF374151),
            ),
          ),
        ),
        Text(
          '${shop.price} 积分',
          style: const TextStyle(
            fontSize: 10, // 减小字体
            fontWeight: FontWeight.w600,
            color: Color(0xFF3B82F6),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return const Text(
      '© 2025 小小卖部. 祝您使用愉快！',
      style: TextStyle(
        fontSize: 8, // 减小字体
        color: Color(0xFF9CA3AF),
      ),
      textAlign: TextAlign.center,
    );
  }
}
