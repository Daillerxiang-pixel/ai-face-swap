/// 后端 [scene] 存中文；界面展示英文。筛选请求仍传原始 [scene] 值。
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

  /// Tab / 标签上展示用文案
  static String display(String scene) {
    if (scene == 'All') return 'All';
    return _zhToEn[scene] ?? scene;
  }
}
