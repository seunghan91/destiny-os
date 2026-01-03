import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/auth/auth_manager.dart';

class TojungPremiumAccessService {
  static SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static String? get _firebaseUid => AuthManager().firebaseUser?.uid;

  static Future<void> initializeIfNeeded() async {
    // server-backed: no-op
  }

  static Future<int> getCredits() async {
    final client = _client;
    final firebaseUid = _firebaseUid;

    if (client == null || firebaseUid == null) return 0;

    try {
      final result = await client.rpc(
        'tojung_get_pass_balance',
        params: {'p_firebase_uid': firebaseUid},
      );

      if (result is int) return result;
      if (result is num) return result.toInt();
      return int.tryParse(result.toString()) ?? 0;
    } catch (e) {
      debugPrint('❌ Failed to load tojung pass balance: $e');
      return 0;
    }
  }

  static Future<int> addCredits(
    int amount, {
    String? paymentId,
    String? description,
  }) async {
    final client = _client;
    final firebaseUid = _firebaseUid;

    if (client == null || firebaseUid == null) return 0;

    try {
      final result = await client.rpc(
        'tojung_add_pass',
        params: {
          'p_firebase_uid': firebaseUid,
          'p_amount': amount,
          'p_payment_id': paymentId,
          'p_description': description,
        },
      );

      if (result is List && result.isNotEmpty) {
        final first = result.first;
        if (first is Map) {
          return (first['new_balance'] as num?)?.toInt() ?? 0;
        }
      }
      return await getCredits();
    } catch (e) {
      debugPrint('❌ Failed to add tojung pass: $e');
      return await getCredits();
    }
  }

  static Future<bool> consumeOne() async {
    final client = _client;
    final firebaseUid = _firebaseUid;

    if (client == null || firebaseUid == null) return false;

    try {
      final result = await client.rpc(
        'tojung_consume_pass',
        params: {'p_firebase_uid': firebaseUid},
      );

      if (result is List && result.isNotEmpty) {
        final first = result.first;
        if (first is Map) {
          return first['success'] == true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Failed to consume tojung pass: $e');
      return false;
    }
  }
}
