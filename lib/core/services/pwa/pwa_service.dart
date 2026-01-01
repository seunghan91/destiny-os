import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// PWA 설치 이벤트를 저장하는 전역 변수 (JS에서 접근)
@JS('deferredInstallPrompt')
external JSAny? get _deferredInstallPrompt;

@JS('deferredInstallPrompt')
external set _deferredInstallPrompt(JSAny? value);

@JS('isPwaInstalled')
external bool get _isPwaInstalled;

@JS('triggerInstallPrompt')
external JSPromise<JSAny?> _triggerInstallPrompt();

/// JS 객체에서 프로퍼티 읽기를 위한 확장
extension JSObjectExtension on JSObject {
  @JS('outcome')
  external JSString? get outcome;
}

/// PWA 설치 관리 서비스
/// 
/// 기능:
/// - PWA 설치 가능 여부 확인
/// - 설치 프롬프트 표시
/// - 설치 상태 추적
/// - iOS Safari 설치 안내
class PwaService {
  static final PwaService _instance = PwaService._internal();
  factory PwaService() => _instance;
  PwaService._internal();

  /// PWA 설치 가능 여부 스트림
  final _installableController = StreamController<bool>.broadcast();
  Stream<bool> get installableStream => _installableController.stream;

  /// 설치 완료 스트림
  final _installedController = StreamController<bool>.broadcast();
  Stream<bool> get installedStream => _installedController.stream;

  bool _isInstallable = false;
  bool _isInstalled = false;
  bool _isInitialized = false;

  /// PWA 설치 가능 여부
  bool get isInstallable => _isInstallable && !_isInstalled;

  /// PWA 설치 완료 여부
  bool get isInstalled => _isInstalled;

  /// 웹 플랫폼인지 확인
  bool get isWebPlatform => kIsWeb;

  /// iOS Safari인지 확인
  bool get isIosSafari {
    if (!kIsWeb) return false;
    final userAgent = web.window.navigator.userAgent.toLowerCase();
    return (userAgent.contains('iphone') || userAgent.contains('ipad')) &&
        !userAgent.contains('crios') && // Chrome on iOS
        !userAgent.contains('fxios'); // Firefox on iOS
  }

  /// Android Chrome인지 확인
  bool get isAndroidChrome {
    if (!kIsWeb) return false;
    final userAgent = web.window.navigator.userAgent.toLowerCase();
    return userAgent.contains('android') && userAgent.contains('chrome');
  }

  /// Standalone 모드(설치된 앱)인지 확인
  bool get isStandalone {
    if (!kIsWeb) return false;
    try {
      // display-mode: standalone 미디어 쿼리 확인
      return web.window.matchMedia('(display-mode: standalone)').matches ||
          web.window.matchMedia('(display-mode: fullscreen)').matches;
    } catch (e) {
      return false;
    }
  }

  /// PWA 서비스 초기화
  Future<void> initialize() async {
    if (!kIsWeb || _isInitialized) return;
    _isInitialized = true;

    try {
      // Standalone 모드 확인 (이미 설치된 경우)
      _isInstalled = isStandalone || _isPwaInstalled;
      
      if (_isInstalled) {
        debugPrint('✅ PWA is already installed');
        _installedController.add(true);
        return;
      }

      // beforeinstallprompt 이벤트 대기
      _checkInstallable();
      
      // 설치 이벤트 리스너 등록
      _listenForInstall();

      debugPrint('✅ PWA Service initialized');
      debugPrint('   isIosSafari: $isIosSafari');
      debugPrint('   isAndroidChrome: $isAndroidChrome');
      debugPrint('   isStandalone: $isStandalone');
    } catch (e) {
      debugPrint('❌ PWA Service initialization failed: $e');
    }
  }

  /// 설치 가능 여부 확인
  void _checkInstallable() {
    // JS에서 저장한 deferredInstallPrompt 확인
    if (_deferredInstallPrompt != null) {
      _isInstallable = true;
      _installableController.add(true);
      debugPrint('✅ PWA is installable (prompt available)');
    } else {
      // iOS Safari는 항상 설치 안내 가능
      _isInstallable = isIosSafari;
      if (isIosSafari) {
        _installableController.add(true);
        debugPrint('✅ iOS Safari detected - manual install available');
      }
    }
  }

  /// 설치 이벤트 리스너
  void _listenForInstall() {
    // appinstalled 이벤트 리스닝
    web.window.addEventListener(
      'appinstalled',
      ((web.Event event) {
        debugPrint('✅ PWA installed successfully');
        _isInstalled = true;
        _isInstallable = false;
        _installedController.add(true);
        _installableController.add(false);
      }).toJS,
    );

    // 커스텀 이벤트 리스닝 (JS에서 발생)
    web.window.addEventListener(
      'pwaInstallAvailable',
      ((web.Event event) {
        _isInstallable = true;
        _installableController.add(true);
        debugPrint('✅ PWA install prompt is now available');
      }).toJS,
    );
  }

  /// PWA 설치 프롬프트 표시
  Future<PwaInstallResult> showInstallPrompt() async {
    if (!kIsWeb) {
      return PwaInstallResult.notSupported;
    }

    if (_isInstalled) {
      return PwaInstallResult.alreadyInstalled;
    }

    // iOS Safari의 경우 수동 안내
    if (isIosSafari) {
      return PwaInstallResult.iosManualInstall;
    }

    // 설치 프롬프트가 없는 경우
    if (_deferredInstallPrompt == null) {
      debugPrint('⚠️  No install prompt available');
      return PwaInstallResult.notAvailable;
    }

    try {
      // JavaScript를 통해 설치 프롬프트 트리거
      final result = await _triggerInstallPrompt().toDart;
      
      if (result != null) {
        // JSObject에서 outcome 속성 읽기 (dart:js_interop 방식)
        final jsResult = result as JSObject;
        final outcomeStr = jsResult.outcome?.toDart ?? '';
        
        if (outcomeStr == 'accepted') {
          debugPrint('✅ User accepted PWA install');
          return PwaInstallResult.accepted;
        } else {
          debugPrint('❌ User dismissed PWA install');
          return PwaInstallResult.dismissed;
        }
      }
      
      return PwaInstallResult.error;
    } catch (e) {
      debugPrint('❌ Install prompt error: $e');
      return PwaInstallResult.error;
    }
  }

  /// 설치 안내 메시지 (플랫폼별)
  String get installInstructions {
    if (isIosSafari) {
      return '하단의 공유 버튼 📤 을 탭한 후\n"홈 화면에 추가"를 선택하세요';
    } else if (isAndroidChrome) {
      return '메뉴(⋮)를 탭한 후\n"홈 화면에 추가"를 선택하세요';
    }
    return '브라우저 메뉴에서 "앱 설치" 또는\n"홈 화면에 추가"를 선택하세요';
  }

  /// 설치 혜택 메시지
  List<String> get installBenefits => [
    '📱 홈 화면에서 바로 실행',
    '🔔 매일 운세 알림 받기',
    '⚡ 더 빠른 로딩 속도',
    '📴 오프라인에서도 사용 가능',
  ];

  /// 리소스 정리
  void dispose() {
    _installableController.close();
    _installedController.close();
  }
}

/// PWA 설치 결과
enum PwaInstallResult {
  /// 사용자가 설치 수락
  accepted,
  /// 사용자가 설치 거부
  dismissed,
  /// iOS Safari - 수동 설치 안내 필요
  iosManualInstall,
  /// 이미 설치됨
  alreadyInstalled,
  /// 설치 프롬프트 없음
  notAvailable,
  /// 웹 플랫폼 아님
  notSupported,
  /// 오류 발생
  error,
}
