import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/auth/auth_manager.dart';
import '../models/dating_profile.dart';

/// MBTI 소개팅 서비스
class DatingService {
  static final _supabase = Supabase.instance.client;

  static String? _getFirebaseUid() => AuthManager().firebaseUser?.uid;

  /// 현재 유저의 user_profiles ID 조회 (UI에서 필요)
  static Future<String?> getCurrentUserProfileId() =>
      _getCurrentUserProfileId();

  /// 현재 유저의 user_profiles ID 조회
  static Future<String?> _getCurrentUserProfileId() async {
    final firebaseUid = _getFirebaseUid();
    if (firebaseUid == null) return null;

    final result = await _supabase
        .from('user_profiles')
        .select('id')
        .eq('firebase_uid', firebaseUid)
        .maybeSingle();

    return result?['id'] as String?;
  }

  /// 소개팅 프로필 존재 여부 확인
  static Future<bool> hasProfile() async {
    final userId = await _getCurrentUserProfileId();
    if (userId == null) return false;

    final result = await _supabase
        .from('dating_profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    return result != null;
  }

  /// 소개팅 프로필 조회
  static Future<DatingProfile?> getProfile() async {
    final userId = await _getCurrentUserProfileId();
    if (userId == null) return null;

    final result = await _supabase
        .from('dating_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (result == null) return null;
    return DatingProfile.fromJson(result);
  }

  /// 소개팅 프로필 생성/업데이트
  static Future<DatingProfile?> upsertProfile({
    required int birthYear,
    required String gender,
    required String mbti,
    String? job,
    int? height,
    List<String> keywords = const [],
    String? bio,
    String? photoPath,
  }) async {
    final userId = await _getCurrentUserProfileId();
    if (userId == null) return null;

    final data = {
      'user_id': userId,
      'birth_year': birthYear,
      'gender': gender,
      'mbti': mbti.toUpperCase(),
      'job': job,
      'height': height,
      'keywords': keywords,
      'bio': bio,
      'photo_path': photoPath,
      'status': 'active',
    };

    final result = await _supabase
        .from('dating_profiles')
        .upsert(data, onConflict: 'user_id')
        .select()
        .single();

    return DatingProfile.fromJson(result);
  }

  /// 프로필 상태 업데이트
  static Future<void> updateStatus(String status) async {
    final userId = await _getCurrentUserProfileId();
    if (userId == null) return;

    await _supabase
        .from('dating_profiles')
        .update({'status': status})
        .eq('user_id', userId);
  }

  /// 선호도 조회
  static Future<DatingPreferences?> getPreferences() async {
    final userId = await _getCurrentUserProfileId();
    if (userId == null) return null;

    final result = await _supabase
        .from('dating_preferences')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (result == null) return null;
    return DatingPreferences.fromJson(result);
  }

  /// 선호도 생성/업데이트
  static Future<DatingPreferences?> upsertPreferences({
    required List<String> targetMbti,
    required int ageMin,
    required int ageMax,
    String? targetGender,
  }) async {
    final userId = await _getCurrentUserProfileId();
    if (userId == null) return null;

    final data = {
      'user_id': userId,
      'target_mbti': targetMbti.map((e) => e.toUpperCase()).toList(),
      'age_min': ageMin,
      'age_max': ageMax,
      'target_gender': targetGender,
    };

    final result = await _supabase
        .from('dating_preferences')
        .upsert(data, onConflict: 'user_id')
        .select()
        .single();

    return DatingPreferences.fromJson(result);
  }

  /// 오늘의 추천 3명 조회 (온디맨드 생성)
  static Future<List<RecommendedProfile>> getTodayRecommendations() async {
    final userId = await _getCurrentUserProfileId();
    if (userId == null) return [];

    final result = await _supabase.rpc(
      'generate_daily_recommendations',
      params: {'p_user_id': userId},
    );

    if (result == null) return [];

    return (result as List<dynamic>)
        .map((e) => RecommendedProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 좋아요/패스 액션
  static Future<bool> recordAction({
    required String targetUserId,
    required String action,
  }) async {
    final userId = await _getCurrentUserProfileId();
    if (userId == null) return false;

    try {
      await _supabase.from('dating_likes').insert({
        'user_id': userId,
        'target_user_id': targetUserId,
        'action': action,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 매치 목록 조회
  static Future<List<DatingMatch>> getMatches() async {
    final userId = await _getCurrentUserProfileId();
    if (userId == null) return [];

    final result = await _supabase
        .from('dating_matches')
        .select()
        .or('user1_id.eq.$userId,user2_id.eq.$userId')
        .order('created_at', ascending: false);

    return (result as List<dynamic>)
        .map((e) => DatingMatch.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 매치 상세 조회
  static Future<DatingMatch?> getMatchById(String matchId) async {
    final userId = await _getCurrentUserProfileId();
    if (userId == null) return null;

    final result = await _supabase
        .from('dating_matches')
        .select()
        .eq('id', matchId)
        .maybeSingle();

    if (result == null) return null;

    final match = DatingMatch.fromJson(result);
    if (match.user1Id != userId && match.user2Id != userId) return null;
    return match;
  }

  /// 매치 승락 (상호 승락 시 accepted_at 설정)
  static Future<bool> acceptMatch(String matchId) async {
    final firebaseUid = _getFirebaseUid();
    if (firebaseUid == null) return false;

    try {
      final result = await _supabase.rpc(
        'dating_accept_match',
        params: {'p_firebase_uid': firebaseUid, 'p_match_id': matchId},
      );

      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// 오픈카카오 URL 등록 (accepted_at 이후 가능)
  static Future<bool> setOpenChatUrl({
    required String matchId,
    required String openChatUrl,
  }) async {
    final firebaseUid = _getFirebaseUid();
    if (firebaseUid == null) return false;

    try {
      final result = await _supabase.rpc(
        'dating_set_open_chat_url',
        params: {
          'p_firebase_uid': firebaseUid,
          'p_match_id': matchId,
          'p_open_chat_url': openChatUrl,
        },
      );

      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// 특정 유저의 프로필 조회 (매치된 상대방 정보 등)
  static Future<DatingProfile?> getProfileByUserId(String targetUserId) async {
    final result = await _supabase
        .from('dating_profiles')
        .select()
        .eq('user_id', targetUserId)
        .eq('status', 'active')
        .maybeSingle();

    if (result == null) return null;
    return DatingProfile.fromJson(result);
  }

  /// 오늘 남은 추천 수 확인
  static Future<int> getRemainingRecommendationsToday() async {
    final userId = await _getCurrentUserProfileId();
    if (userId == null) return 0;

    final today = DateTime.now().toIso8601String().split('T')[0];

    final result = await _supabase
        .from('dating_recommendations')
        .select('id')
        .eq('user_id', userId)
        .eq('date_key', today);

    final count = (result as List<dynamic>).length;
    return 3 - count;
  }
}
