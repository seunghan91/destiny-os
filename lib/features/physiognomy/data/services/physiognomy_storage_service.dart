import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/auth/auth_manager.dart';

/// 관상 분석 리포트 모델
class PhysiognomyReport {
  final String id;
  final DateTime createdAt;
  final String? imagePath;
  final String? cardImagePath;
  final Map<String, dynamic>? featuresJson;
  final String reportMarkdown;

  const PhysiognomyReport({
    required this.id,
    required this.createdAt,
    this.imagePath,
    this.cardImagePath,
    this.featuresJson,
    required this.reportMarkdown,
  });

  factory PhysiognomyReport.fromJson(Map<String, dynamic> json) {
    return PhysiognomyReport(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      imagePath: json['image_path'] as String?,
      cardImagePath: json['card_image_path'] as String?,
      featuresJson: json['features_json'] as Map<String, dynamic>?,
      reportMarkdown: json['report_markdown'] as String,
    );
  }
}

/// 관상 프리미엄 Storage/DB 서비스
class PhysiognomyStorageService {
  static const String _bucketName = 'physiognomy-faces';
  static const String _cardBucketName = 'physiognomy-cards';

  static SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static String? get _firebaseUid => AuthManager().firebaseUser?.uid;

  /// 얼굴 이미지 업로드
  static Future<String?> uploadFaceImage(Uint8List imageBytes) async {
    final client = _client;
    final firebaseUid = _firebaseUid;

    if (client == null || firebaseUid == null) {
      debugPrint('❌ Supabase client or Firebase UID not available');
      return null;
    }

    try {
      final uuid = const Uuid().v4();
      final path = '$firebaseUid/$uuid.jpg';

      await client.storage
          .from(_bucketName)
          .uploadBinary(
            path,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      return path;
    } catch (e) {
      debugPrint('❌ Failed to upload face image: $e');
      return null;
    }
  }

  /// 카드 이미지 저장
  static Future<String?> saveCardImage(
    Uint8List imageBytes,
    String reportId,
  ) async {
    final client = _client;
    final firebaseUid = _firebaseUid;

    if (client == null || firebaseUid == null) return null;

    try {
      final path = '$firebaseUid/$reportId.png';

      await client.storage
          .from(_cardBucketName)
          .uploadBinary(
            path,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: true,
            ),
          );

      return path;
    } catch (e) {
      debugPrint('❌ Failed to save card image: $e');
      return null;
    }
  }

  /// 리포트 저장
  static Future<String?> saveReport({
    required String reportMarkdown,
    String? imagePath,
    String? cardImagePath,
    Map<String, dynamic>? featuresJson,
    Map<String, dynamic>? sajuSnapshot,
    String? mbti,
    String? model,
    Map<String, dynamic>? metadata,
  }) async {
    final client = _client;
    final firebaseUid = _firebaseUid;

    if (client == null || firebaseUid == null) return null;

    try {
      final result = await client.rpc(
        'physiognomy_insert_report',
        params: {
          'p_firebase_uid': firebaseUid,
          'p_image_path': imagePath,
          'p_card_image_path': cardImagePath,
          'p_features_json': featuresJson ?? <String, dynamic>{},
          'p_saju_snapshot': sajuSnapshot ?? <String, dynamic>{},
          'p_mbti': mbti,
          'p_report_markdown': reportMarkdown,
          'p_model': model,
          'p_metadata': metadata ?? <String, dynamic>{},
        },
      );

      if (result is String) return result;
      if (result is Map && result['id'] is String)
        return result['id'] as String;
      return result?.toString();
    } catch (e) {
      debugPrint('❌ Failed to save physiognomy report: $e');
      return null;
    }
  }

  /// 리포트 목록 조회
  static Future<List<PhysiognomyReport>> listReports({int limit = 20}) async {
    final client = _client;
    final firebaseUid = _firebaseUid;

    if (client == null || firebaseUid == null) return [];

    try {
      final result = await client.rpc(
        'physiognomy_list_reports',
        params: {
          'p_firebase_uid': firebaseUid,
          'p_limit': limit,
          'p_offset': 0,
        },
      );

      if (result is List) {
        return result
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .map(PhysiognomyReport.fromJson)
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('❌ Failed to list physiognomy reports: $e');
      return [];
    }
  }

  /// 이미지 URL 가져오기 (서명된 URL)
  static Future<String?> getSignedImageUrl(String path) async {
    final client = _client;
    if (client == null) return null;

    try {
      final response = await client.storage
          .from(_bucketName)
          .createSignedUrl(path, 3600); // 1시간 유효
      return response;
    } catch (e) {
      debugPrint('❌ Failed to get signed URL: $e');
      return null;
    }
  }
}
