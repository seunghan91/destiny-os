import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 사용자 프로필 모델
class UserProfile {
  final String id;
  final String firebaseUid;
  final String? email;
  final String? displayName;
  final DateTime? birthDate;
  final int? birthHour;
  final String? gender;
  final bool isLunar;
  final String? mbti;
  final String? authProvider;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.firebaseUid,
    this.email,
    this.displayName,
    this.birthDate,
    this.birthHour,
    this.gender,
    this.isLunar = false,
    this.mbti,
    this.authProvider,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      firebaseUid: json['firebase_uid'] as String,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      birthDate: json['birth_date'] != null 
          ? DateTime.parse(json['birth_date'] as String) 
          : null,
      birthHour: json['birth_hour'] as int?,
      gender: json['gender'] as String?,
      isLunar: json['is_lunar'] as bool? ?? false,
      mbti: json['mbti'] as String?,
      authProvider: json['auth_provider'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebase_uid': firebaseUid,
      'email': email,
      'display_name': displayName,
      'birth_date': birthDate?.toIso8601String(),
      'birth_hour': birthHour,
      'gender': gender,
      'is_lunar': isLunar,
      'mbti': mbti,
      'auth_provider': authProvider,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? firebaseUid,
    String? email,
    String? displayName,
    DateTime? birthDate,
    int? birthHour,
    String? gender,
    bool? isLunar,
    String? mbti,
    String? authProvider,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      birthDate: birthDate ?? this.birthDate,
      birthHour: birthHour ?? this.birthHour,
      gender: gender ?? this.gender,
      isLunar: isLunar ?? this.isLunar,
      mbti: mbti ?? this.mbti,
      authProvider: authProvider ?? this.authProvider,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 사주 정보가 설정되어 있는지 확인
  bool get hasSajuInfo => birthDate != null && birthHour != null && gender != null;
}

/// 사용자 프로필 서비스
class UserProfileService {
  final SupabaseClient _client;
  static const String _tableName = 'user_profiles';

  UserProfileService({required SupabaseClient client}) : _client = client;

  /// Firebase UID로 프로필 조회
  Future<UserProfile?> getProfileByFirebaseUid(String firebaseUid) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('firebase_uid', firebaseUid)
          .maybeSingle();

      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error fetching profile: $e');
      return null;
    }
  }

  /// 프로필 생성 또는 업데이트
  Future<UserProfile?> upsertProfile({
    required String firebaseUid,
    String? email,
    String? displayName,
    String? authProvider,
    DateTime? birthDate,
    int? birthHour,
    String? gender,
    bool? isLunar,
    String? mbti,
  }) async {
    try {
      // 기존 프로필 확인
      final existing = await getProfileByFirebaseUid(firebaseUid);

      if (existing != null) {
        // 업데이트
        final updateData = <String, dynamic>{};
        if (email != null) updateData['email'] = email;
        if (displayName != null) updateData['display_name'] = displayName;
        if (authProvider != null) updateData['auth_provider'] = authProvider;
        if (birthDate != null) updateData['birth_date'] = birthDate.toIso8601String();
        if (birthHour != null) updateData['birth_hour'] = birthHour;
        if (gender != null) updateData['gender'] = gender;
        if (isLunar != null) updateData['is_lunar'] = isLunar;
        if (mbti != null) updateData['mbti'] = mbti;

        if (updateData.isNotEmpty) {
          final response = await _client
              .from(_tableName)
              .update(updateData)
              .eq('firebase_uid', firebaseUid)
              .select()
              .single();

          debugPrint('✅ Profile updated for: $firebaseUid');
          return UserProfile.fromJson(response);
        }
        return existing;
      } else {
        // 새로 생성
        final insertData = {
          'firebase_uid': firebaseUid,
          'email': email,
          'display_name': displayName,
          'auth_provider': authProvider,
          'birth_date': birthDate?.toIso8601String(),
          'birth_hour': birthHour,
          'gender': gender,
          'is_lunar': isLunar ?? false,
          'mbti': mbti,
        };

        final response = await _client
            .from(_tableName)
            .insert(insertData)
            .select()
            .single();

        debugPrint('✅ Profile created for: $firebaseUid');
        return UserProfile.fromJson(response);
      }
    } catch (e) {
      debugPrint('❌ Error upserting profile: $e');
      return null;
    }
  }

  /// 사주 정보 업데이트
  Future<UserProfile?> updateSajuInfo({
    required String firebaseUid,
    required DateTime birthDate,
    required int birthHour,
    required String gender,
    required bool isLunar,
    String? mbti,
  }) async {
    return upsertProfile(
      firebaseUid: firebaseUid,
      birthDate: birthDate,
      birthHour: birthHour,
      gender: gender,
      isLunar: isLunar,
      mbti: mbti,
    );
  }

  /// 프로필 삭제
  Future<bool> deleteProfile(String firebaseUid) async {
    try {
      await _client
          .from(_tableName)
          .delete()
          .eq('firebase_uid', firebaseUid);

      debugPrint('✅ Profile deleted for: $firebaseUid');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting profile: $e');
      return false;
    }
  }
}
