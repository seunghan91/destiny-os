import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSupportService {
  static const String _tableName = 'support_tickets';

  final SupabaseClient _client;

  SupabaseSupportService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<String?> createTicket({
    required String title,
    required String contact,
    required String message,
    String? userId,
    String? firebaseUid,
  }) async {
    try {
      final response = await _client
          .from(_tableName)
          .insert({
            'title': title,
            'contact': contact,
            'message': message,
            'user_id': userId,
            'firebase_uid': firebaseUid,
          })
          .select('id');

      if (response.isEmpty) return null;
      return response.first['id'] as String?;
    } catch (e, st) {
      debugPrint('❌ [SupportService] Failed to create ticket: $e');
      debugPrint('❌ [SupportService] StackTrace: $st');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> listTickets({int limit = 100}) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ [SupportService] Failed to list tickets: $e');
      return [];
    }
  }
}
