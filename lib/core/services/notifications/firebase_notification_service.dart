import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Firebase Cloud Messaging 서비스
///
/// 기능:
/// - FCM 토큰 관리
/// - 푸시 알림 수신 및 처리
/// - 알림 권한 요청
/// - 백그라운드/포그라운드 메시지 핸들링
class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();

  factory FirebaseNotificationService() => _instance;

  FirebaseNotificationService._internal();

  FirebaseMessaging? _messaging;
  String? _fcmToken;

  /// FCM 토큰 스트림
  final _tokenController = StreamController<String>.broadcast();
  Stream<String> get tokenStream => _tokenController.stream;

  /// 메시지 수신 스트림
  final _messageController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get messageStream => _messageController.stream;

  /// FCM 토큰 getter
  String? get fcmToken => _fcmToken;

  /// Firebase Messaging 초기화
  Future<void> initialize() async {
    try {
      // Firebase가 이미 초기화되어 있는지 확인
      if (Firebase.apps.isEmpty) {
        debugPrint('⚠️  Firebase not initialized. Call Firebase.initializeApp() first.');
        return;
      }

      _messaging = FirebaseMessaging.instance;

      // 알림 권한 요청 (iOS)
      if (Platform.isIOS) {
        await _requestPermissionIOS();
      } else if (Platform.isAndroid) {
        await _requestPermissionAndroid();
      }

      // FCM 토큰 가져오기
      await _getFCMToken();

      // 토큰 갱신 리스너
      _messaging!.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _tokenController.add(newToken);
        debugPrint('🔄 FCM Token refreshed: ${newToken.substring(0, 20)}...');
      });

      // 포그라운드 메시지 핸들러
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 백그라운드 메시지 핸들러 (앱이 백그라운드에서 실행 중일 때)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // 앱이 종료된 상태에서 알림 탭으로 실행된 경우
      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessage(initialMessage);
      }

      debugPrint('✅ Firebase Notification Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Firebase Notification Service initialization failed: $e');
    }
  }

  /// iOS 알림 권한 요청
  Future<void> _requestPermissionIOS() async {
    final settings = await _messaging!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ iOS notification permission granted');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('⚠️  iOS notification permission granted provisionally');
    } else {
      debugPrint('❌ iOS notification permission denied');
    }
  }

  /// Android 알림 권한 요청 (Android 13+)
  Future<void> _requestPermissionAndroid() async {
    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Android notification permission granted');
    } else {
      debugPrint('❌ Android notification permission denied');
    }
  }

  /// FCM 토큰 가져오기
  Future<String?> _getFCMToken() async {
    try {
      // iOS의 경우 APNs 토큰이 먼저 필요
      if (Platform.isIOS) {
        final apnsToken = await _messaging!.getAPNSToken();
        if (apnsToken == null) {
          debugPrint('⚠️  APNs token not available yet. Retrying...');
          await Future.delayed(const Duration(seconds: 2));
          return await _getFCMToken();
        }
      }

      _fcmToken = await _messaging!.getToken();
      if (_fcmToken != null) {
        debugPrint('✅ FCM Token: ${_fcmToken!.substring(0, 20)}...');
        _tokenController.add(_fcmToken!);

        // TODO: 서버에 토큰 등록 (Supabase 또는 백엔드 API)
        // await _registerTokenToServer(_fcmToken!);
      }
      return _fcmToken;
    } catch (e) {
      debugPrint('❌ Failed to get FCM token: $e');
      return null;
    }
  }

  /// 포그라운드 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📱 Foreground message received');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');

    _messageController.add(message);

    // TODO: 포그라운드 알림 UI 표시 (로컬 알림 사용)
    // 예: flutter_local_notifications 패키지 사용
  }

  /// 백그라운드 메시지 처리
  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('📱 Background message opened');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');

    _messageController.add(message);

    // TODO: 딥링크 처리 (특정 페이지로 이동)
    // 예: message.data['route']에 따라 화면 전환
  }

  /// 알림 구독 (토픽 구독)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging!.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to topic $topic: $e');
    }
  }

  /// 알림 구독 해제
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging!.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from topic $topic: $e');
    }
  }

  /// 알림 권한 상태 확인
  Future<bool> isNotificationEnabled() async {
    try {
      final settings = await _messaging!.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('❌ Failed to check notification status: $e');
      return false;
    }
  }

  /// 리소스 정리
  void dispose() {
    _tokenController.close();
    _messageController.close();
  }
}

/// 백그라운드 메시지 핸들러 (최상위 함수)
///
/// 앱이 완전히 종료된 상태에서도 메시지를 받을 수 있도록 함
/// main.dart에서 FirebaseMessaging.onBackgroundMessage()로 등록해야 함
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase 초기화가 필요한 경우
  await Firebase.initializeApp();

  debugPrint('📱 Background message received (app terminated)');
  debugPrint('   Title: ${message.notification?.title}');
  debugPrint('   Body: ${message.notification?.body}');
  debugPrint('   Data: ${message.data}');

  // TODO: 백그라운드에서 데이터 처리
  // 예: 로컬 DB 업데이트, 캐시 갱신 등
}
