import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地存储服务
class StorageService {
  StorageService._();

  static final StorageService _instance = StorageService._();
  factory StorageService() => _instance;

  SharedPreferences? _prefs;

  /// 初始化存储服务
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 确保 SharedPreferences 已初始化
  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ===== String =====
  Future<String?> getString(String key) async {
    final p = await prefs;
    return p.getString(key);
  }

  Future<void> setString(String key, String value) async {
    final p = await prefs;
    await p.setString(key, value);
  }

  // ===== Bool =====
  Future<bool?> getBool(String key) async {
    final p = await prefs;
    return p.getBool(key);
  }

  Future<void> setBool(String key, bool value) async {
    final p = await prefs;
    await p.setBool(key, value);
  }

  // ===== Int =====
  Future<int?> getInt(String key) async {
    final p = await prefs;
    return p.getInt(key);
  }

  Future<void> setInt(String key, int value) async {
    final p = await prefs;
    await p.setInt(key, value);
  }

  // ===== Object (JSON) =====
  Future<T?> getObject<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    final str = await getString(key);
    if (str == null || str.isEmpty) return null;
    try {
      final map = json.decode(str) as Map<String, dynamic>;
      return fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> setObject(String key, Map<String, dynamic> value) async {
    await setString(key, json.encode(value));
  }

  // ===== 删除 =====
  Future<void> remove(String key) async {
    final p = await prefs;
    await p.remove(key);
  }

  /// 清除所有存储
  Future<void> clear() async {
    final p = await prefs;
    await p.clear();
  }
}
