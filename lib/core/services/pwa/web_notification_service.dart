import 'dart:async';
import 'dart:js_interop';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

/// JavaScript 함수 참조
@JS('requestNotificationPermission')
external JSPromise<JSString> _requestNotificationPermission();

@JS('isPushSupported')
external bool _isPushSupported();

/// 웹 푸시 알림 서비스
/// 
/// 기능:
/// - 알림 권한 요청
/// - Firebase Cloud Messaging (FCM) 웹 푸시
/// - 알림 구독/해제
/// - 알림 설정 관리
class WebNotificationService {
  static final WebNotificationService _instance = WebNotificationService._internal();
  factory WebNotificationService() => _instance;
  WebNotificationService._internal();

  FirebaseMessaging? _messaging;
  String? _fcmToken;
  bool _isInitialized = false;

  /// FCM 토큰
  String? get fcmToken => _fcmToken;

  /// 알림 지원 여부
  bool get isSupported => kIsWeb && _isPushSupported();

  /// 알림 권한 상태
  NotificationPermissionStatus _permissionStatus = NotificationPermissionStatus.unknown;
  NotificationPermissionStatus get permissionStatus => _permissionStatus;

  /// 알림 권한 스트림
  final _permissionController = StreamController<NotificationPermissionStatus>.broadcast();
  Stream<NotificationPermissionStatus> get permissionStream => _permissionController.stream;

  /// 알림 메시지 스트림
  final _messageController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get messageStream => _messageController.stream;

  /// 서비스 초기화
  Future<void> initialize() async {
    if (!kIsWeb || _isInitialized) return;
    _isInitialized = true;

    try {
      // 현재 권한 상태 확인
      await _checkCurrentPermission();

      // 이미 권한이 있으면 FCM 초기화
      if (_permissionStatus == NotificationPermissionStatus.granted) {
        await _initializeFcm();
      }

      debugPrint('✅ Web Notification Service initialized');
      debugPrint('   Permission: $_permissionStatus');
      debugPrint('   Push supported: $isSupported');
    } catch (e) {
      debugPrint('❌ Web Notification Service initialization failed: $e');
    }
  }

  /// 현재 알림 권한 상태 확인
  Future<void> _checkCurrentPermission() async {
    if (!kIsWeb) return;

    try {
      final permission = web.Notification.permission;
      _permissionStatus = _parsePermission(permission);
      _permissionController.add(_permissionStatus);
    } catch (e) {
      debugPrint('❌ Failed to check notification permission: $e');
      _permissionStatus = NotificationPermissionStatus.unsupported;
    }
  }

  /// 알림 권한 요청
  Future<NotificationPermissionStatus> requestPermission() async {
    if (!kIsWeb) {
      return NotificationPermissionStatus.unsupported;
    }

    if (!isSupported) {
      return NotificationPermissionStatus.unsupported;
    }

    try {
      // JavaScript 함수를 통해 권한 요청
      final result = await _requestNotificationPermission().toDart;
      final permissionString = result.toDart;
      
      _permissionStatus = _parsePermission(permissionString);
      _permissionController.add(_permissionStatus);

      // 권한 허용시 FCM 초기화
      if (_permissionStatus == NotificationPermissionStatus.granted) {
        await _initializeFcm();
        
        // 설정 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notifications_enabled', true);
      }

      debugPrint('📱 Notification permission: $_permissionStatus');
      return _permissionStatus;
    } catch (e) {
      debugPrint('❌ Failed to request notification permission: $e');
      return NotificationPermissionStatus.error;
    }
  }

  /// FCM 초기화
  Future<void> _initializeFcm() async {
    try {
      _messaging = FirebaseMessaging.instance;

      // 웹 푸시 인증서 VAPID 키 (Firebase Console > 프로젝트 설정 > 클라우드 메시징 > 웹 구성)
      // ⚠️ TODO: 실제 VAPID 키로 교체해야 웹 푸시가 작동합니다.
      const vapidKey = 'BFVxTu6Tav8cys34rj8EyKPqsgHEWWpkPLAomWHO9ZtYF5P4_M4720FYRk63cygy19KXcGEmTHg6TvC_heL40Rw';
      
      // FCM 토큰 가져오기
      _fcmToken = await _messaging!.getToken(vapidKey: vapidKey);
      
      if (_fcmToken != null) {
        debugPrint('✅ FCM Token obtained: ${_fcmToken!.substring(0, 20)}...');
        
        // TODO: 서버에 토큰 등록
        // await _registerTokenToServer(_fcmToken!);
      }

      // 토큰 갱신 리스너
      _messaging!.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔄 FCM Token refreshed');
        // TODO: 서버에 새 토큰 등록
      });

      // 포그라운드 메시지 핸들러
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 백그라운드에서 알림 탭 시
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    } catch (e) {
      debugPrint('❌ FCM initialization failed: $e');
    }
  }

  /// 포그라운드 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📱 Foreground message: ${message.notification?.title}');
    _messageController.add(message);

    // 브라우저 알림 표시
    _showBrowserNotification(
      title: message.notification?.title ?? 'Destiny.OS',
      body: message.notification?.body ?? '',
      icon: '/icons/Icon-192.png',
    );
  }

  /// 백그라운드에서 알림 탭 처리
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('📱 Message opened app: ${message.notification?.title}');
    _messageController.add(message);

    // TODO: 딥링크 처리
    // final route = message.data['route'];
  }

  /// 브라우저 알림 표시
  void _showBrowserNotification({
    required String title,
    required String body,
    String? icon,
  }) {
    if (!kIsWeb) return;
    if (_permissionStatus != NotificationPermissionStatus.granted) return;

    try {
      final options = web.NotificationOptions(
        body: body,
        icon: icon ?? '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
        tag: 'destiny-os-${DateTime.now().millisecondsSinceEpoch}',
      );
      
      web.Notification(title, options);
    } catch (e) {
      debugPrint('❌ Failed to show browser notification: $e');
    }
  }

  /// 토픽 구독
  Future<void> subscribeToTopic(String topic) async {
    if (_messaging == null) return;
    
    try {
      await _messaging!.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
      
      // 설정 저장
      final prefs = await SharedPreferences.getInstance();
      final topics = prefs.getStringList('subscribed_topics') ?? [];
      if (!topics.contains(topic)) {
        topics.add(topic);
        await prefs.setStringList('subscribed_topics', topics);
      }
    } catch (e) {
      debugPrint('❌ Failed to subscribe to topic: $e');
    }
  }

  /// 토픽 구독 해제
  Future<void> unsubscribeFromTopic(String topic) async {
    if (_messaging == null) return;
    
    try {
      await _messaging!.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
      
      // 설정 저장
      final prefs = await SharedPreferences.getInstance();
      final topics = prefs.getStringList('subscribed_topics') ?? [];
      topics.remove(topic);
      await prefs.setStringList('subscribed_topics', topics);
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from topic: $e');
    }
  }

  /// 알림 활성화 여부
  Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? false;
  }

  /// 알림 비활성화
  Future<void> disableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', false);
    
    // 구독 토픽 모두 해제
    final topics = prefs.getStringList('subscribed_topics') ?? [];
    for (final topic in topics) {
      await unsubscribeFromTopic(topic);
    }
  }

  /// 권한 문자열 파싱
  NotificationPermissionStatus _parsePermission(String permission) {
    switch (permission) {
      case 'granted':
        return NotificationPermissionStatus.granted;
      case 'denied':
        return NotificationPermissionStatus.denied;
      case 'default':
        return NotificationPermissionStatus.notDetermined;
      case 'unsupported':
        return NotificationPermissionStatus.unsupported;
      case 'error':
        return NotificationPermissionStatus.error;
      default:
        return NotificationPermissionStatus.unknown;
    }
  }

  /// 리소스 정리
  void dispose() {
    _permissionController.close();
    _messageController.close();
  }
}

/// 알림 권한 상태
enum NotificationPermissionStatus {
  /// 권한 허용됨
  granted,
  /// 권한 거부됨
  denied,
  /// 아직 결정되지 않음
  notDetermined,
  /// 지원되지 않음
  unsupported,
  /// 알 수 없음
  unknown,
  /// 오류
  error,
}

/// 알림 토픽
class NotificationTopics {
  /// 매일 운세 알림
  static const String dailyFortune = 'daily_fortune';
  
  /// 주간 운세 알림
  static const String weeklyFortune = 'weekly_fortune';
  
  /// 월간 운세 알림
  static const String monthlyFortune = 'monthly_fortune';
  
  /// 특별 운세 (대운, 세운 변화)
  static const String specialFortune = 'special_fortune';
  
  /// 이벤트/프로모션
  static const String promotions = 'promotions';
}
