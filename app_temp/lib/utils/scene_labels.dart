/// Backend may store [scene] in Chinese; UI shows English. API filters still use the raw [scene] value.
class SceneLabels {
  SceneLabels._();

  static const Map<String, String> _zhToEn = {
    '全部': 'All',
    '电影': 'Movie',
    '春风': 'Spring',
    '动漫': 'Anime',
    '悬疑': 'Mystery',
    '明星': 'Celebrity',
    '舞台': 'Stage',
    '搞笑': 'Funny',
    '通用': 'General',
    '古风': 'Vintage',
    '节日': 'Holiday',
    '宠物': 'Pet',
    '运动': 'Sports',
    '旅行': 'Travel',
    '美食': 'Food',
  };

  /// Label text for tabs (English only in UI).
  static String display(String scene) {
    if (scene == 'All') return 'All';
    final en = _zhToEn[scene];
    if (en != null) return en;
    if (RegExp(r'[\u4e00-\u9fff]').hasMatch(scene)) return 'Other';
    return scene;
  }
}
