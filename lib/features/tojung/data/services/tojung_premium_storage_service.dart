import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/auth/auth_manager.dart';

class TojungReport {
  final String id;
  final DateTime createdAt;
  final int year;
  final String? mbti;
  final String reportMarkdown;

  const TojungReport({
    required this.id,
    required this.createdAt,
    required this.year,
    required this.mbti,
    required this.reportMarkdown,
  });

  factory TojungReport.fromJson(Map<String, dynamic> json) {
    return TojungReport(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      year: (json['year'] as num?)?.toInt() ?? 2026,
      mbti: json['mbti'] as String?,
      reportMarkdown: json['report_markdown'] as String,
    );
  }
}

class TojungPremiumStorageService {
  static SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static String? get _firebaseUid => AuthManager().firebaseUser?.uid;

  static Future<String?> saveReport({
    required String reportMarkdown,
    required int year,
    required String? mbti,
    required Map<String, dynamic> sajuSnapshot,
    String? model,
    Map<String, dynamic>? metadata,
  }) async {
    final client = _client;
    final firebaseUid = _firebaseUid;

    if (client == null || firebaseUid == null) return null;

    final result = await client.rpc(
      'tojung_insert_report',
      params: {
        'p_firebase_uid': firebaseUid,
        'p_year': year,
        'p_mbti': mbti,
        'p_saju_snapshot': sajuSnapshot,
        'p_report_markdown': reportMarkdown,
        'p_model': model,
        'p_metadata': metadata ?? <String, dynamic>{},
      },
    );

    if (result is String) return result;
    if (result is Map && result['id'] is String) return result['id'] as String;
    return result?.toString();
  }

  static Future<List<TojungReport>> listReports({int limit = 20}) async {
    final client = _client;
    final firebaseUid = _firebaseUid;

    if (client == null || firebaseUid == null) return [];

    try {
      final result = await client.rpc(
        'tojung_list_reports',
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
            .map(TojungReport.fromJson)
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('❌ Failed to list tojung reports: $e');
      return [];
    }
  }
}
