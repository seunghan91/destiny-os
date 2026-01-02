import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_fortune_model.dart';

/// 오늘의 운세 로컬 데이터 소스
class DailyFortuneLocalDatasource {
  const DailyFortuneLocalDatasource(this._prefs);

  final SharedPreferences _prefs;

  static const String _keyPrefix = 'daily_fortune_';
  static const String _premiumKey = 'has_premium_fortune';

  /// 운세 캐시 키 생성
  String _getCacheKey(DateTime date) {
    return '$_keyPrefix${date.year}_${date.month}_${date.day}';
  }

  /// 운세 캐시 저장
  Future<void> cacheFortune(DailyFortuneModel fortune) async {
    final key = _getCacheKey(fortune.date);
    final json = jsonEncode(fortune.toJson());
    await _prefs.setString(key, json);
  }

  /// 운세 캐시 조회
  DailyFortuneModel? getCachedFortune(DateTime date) {
    final key = _getCacheKey(date);
    final jsonString = _prefs.getString(key);

    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return DailyFortuneModel.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// 오래된 캐시 삭제 (30일 이상)
  Future<void> clearOldCache() async {
    final keys = _prefs.getKeys();
    final now = DateTime.now();

    for (final key in keys) {
      if (key.startsWith(_keyPrefix)) {
        try {
          final parts = key.split('_');
          if (parts.length == 4) {
            final year = int.parse(parts[2]);
            final month = int.parse(parts[3].split('_')[0]);
            final day = int.parse(parts[3].split('_')[1]);

            final cacheDate = DateTime(year, month, day);
            final diff = now.difference(cacheDate).inDays;

            if (diff > 30) {
              await _prefs.remove(key);
            }
          }
        } catch (e) {
          // 파싱 실패한 키는 무시
        }
      }
    }
  }

  /// 프리미엄 상태 저장
  Future<void> setPremiumStatus(bool hasPremium) async {
    await _prefs.setBool(_premiumKey, hasPremium);
  }

  /// 프리미엄 상태 조회
  bool get hasPremium => _prefs.getBool(_premiumKey) ?? false;
}
