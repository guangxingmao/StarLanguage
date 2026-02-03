/// 成就 icon_key 与徽章图片资源路径映射
/// 徽章 SVG 由 scripts/generate_badge_svgs.js 生成，位于 assets/badges/badge_{icon_key}.svg
class AchievementBadges {
  AchievementBadges._();

  static const String _prefix = 'assets/badges/';
  static const String _suffix = '.svg';
  static const String _defaultKey = 'star';

  /// 根据成就的 icon_key 返回徽章 SVG 资源路径；无对应文件时使用 star
  static String assetPath(String iconKey) {
    final key = iconKey.trim().isEmpty ? _defaultKey : iconKey;
    return '${_prefix}badge_$key$_suffix';
  }
}
