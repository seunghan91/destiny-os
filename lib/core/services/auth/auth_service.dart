import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// 인증 결과
class AuthResult {
  final bool success;
  final User? user;
  final String? errorMessage;

  AuthResult({required this.success, this.user, this.errorMessage});

  factory AuthResult.success(User user) =>
      AuthResult(success: true, user: user);
  factory AuthResult.failure(String message) =>
      AuthResult(success: false, errorMessage: message);
}

/// 인증 제공자 타입
enum AuthProvider { google, apple }

/// Firebase Auth 기반 인증 서비스
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  // 현재 사용자 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 현재 로그인된 사용자
  User? get currentUser => _auth.currentUser;

  // 로그인 여부
  bool get isSignedIn => currentUser != null;

  /// Redirect 결과 확인 (웹 전용 - 앱 시작 시 호출)
  /// Popup이 차단되어 Redirect로 fallback한 경우, 페이지 리로드 후 결과 확인
  Future<AuthResult?> checkRedirectResult() async {
    if (!kIsWeb) return null;

    try {
      final UserCredential? credential = await _auth.getRedirectResult();

      if (credential != null && credential.user != null) {
        debugPrint(
          '✅ Redirect Sign-In successful: ${credential.user!.email}',
        );
        return AuthResult.success(credential.user!);
      }

      return null; // Redirect 결과 없음 (정상)
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Redirect result error: ${e.code} - ${e.message}');
      return AuthResult.failure(_getFirebaseAuthErrorMessage(e.code));
    } catch (e) {
      debugPrint('❌ Redirect result error: $e');
      return null;
    }
  }

  /// Google 로그인
  Future<AuthResult> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        return await _signInWithGoogleWeb();
      } else {
        return await _signInWithGoogleNative();
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Google Sign-In Firebase error: ${e.code} - ${e.message}');
      return AuthResult.failure(_getFirebaseAuthErrorMessage(e.code));
    } on PlatformException catch (e) {
      debugPrint('❌ Google Sign-In Platform error: ${e.code} - ${e.message}');
      return AuthResult.failure(_getPlatformAuthErrorMessage(e.code));
    } catch (e) {
      debugPrint('❌ Google Sign-In error: $e');
      return AuthResult.failure('Google 로그인에 실패했습니다. 다시 시도해주세요.');
    }
  }

  /// Google 로그인 (웹)
  Future<AuthResult> _signInWithGoogleWeb() async {
    final GoogleAuthProvider googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.addScope('profile');

    try {
      // 데스크탑: Popup 시도
      final UserCredential userCredential = await _auth.signInWithPopup(
        googleProvider,
      );

      if (userCredential.user != null) {
        debugPrint(
          '✅ Google Sign-In successful (Web/Popup): ${userCredential.user!.email}',
        );
        return AuthResult.success(userCredential.user!);
      }

      return AuthResult.failure('Google 로그인에 실패했습니다.');
    } on FirebaseAuthException catch (e) {
      // Popup 실패 시 Redirect로 fallback
      if (e.code == 'popup-blocked' ||
          e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        debugPrint('⚠️ Popup failed, fallback to redirect: ${e.code}');
        await _auth.signInWithRedirect(googleProvider);
        // Redirect는 페이지 리로드되므로 여기서 결과 반환 불가
        // getRedirectResult()로 결과 확인 필요 (앱 초기화 시)
        return AuthResult.failure(
          '로그인 중입니다. 잠시 후 페이지가 새로고침됩니다.',
        );
      }
      rethrow;
    }
  }

  /// Google 로그인 (네이티브)
  Future<AuthResult> _signInWithGoogleNative() async {
    // 기존 로그인 세션 정리
    await _googleSignIn.signOut();

    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      return AuthResult.failure('로그인이 취소되었습니다.');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _auth.signInWithCredential(
      credential,
    );

    if (userCredential.user != null) {
      debugPrint('✅ Google Sign-In successful: ${userCredential.user!.email}');
      return AuthResult.success(userCredential.user!);
    }

    return AuthResult.failure('Google 로그인에 실패했습니다.');
  }

  /// Apple 로그인
  Future<AuthResult> signInWithApple() async {
    try {
      if (kIsWeb) {
        return await _signInWithAppleWeb();
      } else {
        return await _signInWithAppleNative();
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Apple Sign-In Firebase error: ${e.code} - ${e.message}');
      return AuthResult.failure(_getFirebaseAuthErrorMessage(e.code));
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint(
        '❌ Apple Sign-In authorization error: ${e.code} - ${e.message}',
      );
      if (e.code == AuthorizationErrorCode.canceled) {
        return AuthResult.failure('로그인이 취소되었습니다.');
      }
      return AuthResult.failure('Apple 로그인에 실패했습니다.');
    } catch (e) {
      debugPrint('❌ Apple Sign-In error: $e');
      return AuthResult.failure('Apple 로그인에 실패했습니다. 다시 시도해주세요.');
    }
  }

  /// Apple 로그인 (웹)
  Future<AuthResult> _signInWithAppleWeb() async {
    final appleProvider = OAuthProvider('apple.com');
    appleProvider.addScope('email');
    appleProvider.addScope('name');

    try {
      // 데스크탑: Popup 시도
      final UserCredential userCredential = await _auth.signInWithPopup(
        appleProvider,
      );

      if (userCredential.user != null) {
        debugPrint(
          '✅ Apple Sign-In successful (Web/Popup): ${userCredential.user!.email}',
        );
        return AuthResult.success(userCredential.user!);
      }

      return AuthResult.failure('Apple 로그인에 실패했습니다.');
    } on FirebaseAuthException catch (e) {
      // Popup 실패 시 Redirect로 fallback
      if (e.code == 'popup-blocked' ||
          e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        debugPrint('⚠️ Popup failed, fallback to redirect: ${e.code}');
        await _auth.signInWithRedirect(appleProvider);
        // Redirect는 페이지 리로드되므로 여기서 결과 반환 불가
        return AuthResult.failure(
          '로그인 중입니다. 잠시 후 페이지가 새로고침됩니다.',
        );
      }
      rethrow;
    }
  }

  /// Apple 로그인 (네이티브)
  Future<AuthResult> _signInWithAppleNative() async {
    // nonce 생성 (보안 강화)
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider(
      'apple.com',
    ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

    final UserCredential userCredential = await _auth.signInWithCredential(
      oauthCredential,
    );

    // Apple은 첫 로그인 시에만 이름 제공, 이후에는 null
    // 필요시 displayName 업데이트
    if (userCredential.user != null) {
      final displayName = userCredential.user!.displayName;
      if ((displayName == null || displayName.isEmpty) &&
          appleCredential.givenName != null) {
        final fullName = [
          appleCredential.givenName,
          appleCredential.familyName,
        ].where((n) => n != null && n.isNotEmpty).join(' ');

        if (fullName.isNotEmpty) {
          await userCredential.user!.updateDisplayName(fullName);
        }
      }

      debugPrint('✅ Apple Sign-In successful: ${userCredential.user!.email}');
      return AuthResult.success(userCredential.user!);
    }

    return AuthResult.failure('Apple 로그인에 실패했습니다.');
  }

  /// 로그아웃
  Future<void> signOut() async {
    try {
      // Google 로그아웃
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Firebase 로그아웃
      await _auth.signOut();

      debugPrint('✅ Sign-Out successful');
    } catch (e) {
      debugPrint('❌ Sign-Out error: $e');
    }
  }

  /// 계정 삭제
  Future<bool> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      await user.delete();
      debugPrint('✅ Account deleted successfully');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Delete account error: ${e.code}');
      // requires-recent-login 에러 시 재인증 필요
      return false;
    } catch (e) {
      debugPrint('❌ Delete account error: $e');
      return false;
    }
  }

  /// 현재 인증 제공자 확인
  AuthProvider? get currentAuthProvider {
    final user = currentUser;
    if (user == null) return null;

    for (final providerData in user.providerData) {
      if (providerData.providerId == 'google.com') {
        return AuthProvider.google;
      } else if (providerData.providerId == 'apple.com') {
        return AuthProvider.apple;
      }
    }
    return null;
  }

  /// nonce 생성 (Apple Sign-In 보안용)
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// SHA256 해시 생성
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Firebase Auth 에러 메시지 한글화
  String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return '이미 다른 로그인 방식으로 가입된 계정입니다.';
      case 'app-not-authorized':
        return '앱 인증 설정에 문제가 있습니다. 관리자에게 문의해주세요.';
      case 'invalid-credential':
        return '인증 정보가 유효하지 않습니다.';
      case 'invalid-api-key':
        return '서비스 설정에 문제가 있습니다. 관리자에게 문의해주세요.';
      case 'invalid-oauth-client-id':
        return 'OAuth 클라이언트 설정에 문제가 있습니다. 관리자에게 문의해주세요.';
      case 'missing-or-invalid-nonce':
        return '인증 정보가 유효하지 않습니다. 다시 시도해주세요.';
      case 'operation-not-allowed':
        return '이 로그인 방식은 현재 사용할 수 없습니다.';
      case 'popup-blocked':
        return '브라우저에서 팝업이 차단되었습니다. 팝업 차단을 해제한 뒤 다시 시도해주세요.';
      case 'popup-closed-by-user':
        return '로그인이 취소되었습니다.';
      case 'redirect_uri_mismatch':
        return '로그인 설정에 문제가 있습니다. 관리자에게 문의해주세요.';
      case 'unauthorized-domain':
        return '허용되지 않은 도메인에서 로그인 요청이 발생했습니다. 관리자에게 문의해주세요.';
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      case 'user-not-found':
        return '계정을 찾을 수 없습니다.';
      case 'wrong-password':
        return '비밀번호가 올바르지 않습니다.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해주세요.';
      case 'too-many-requests':
        return '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.';
      case 'cancelled-popup-request':
        return '로그인이 취소되었습니다.';
      case 'web-context-canceled':
        return '로그인이 취소되었습니다.';
      case 'web-context-cancelled':
        return '로그인이 취소되었습니다.';
      default:
        return '로그인에 실패했습니다. 다시 시도해주세요.';
    }
  }

  String _getPlatformAuthErrorMessage(String code) {
    switch (code) {
      case 'network_error':
        return '네트워크 연결을 확인해주세요.';
      case 'sign_in_canceled':
        return '로그인이 취소되었습니다.';
      case 'sign_in_failed':
        return '로그인에 실패했습니다. 다시 시도해주세요.';
      default:
        return '로그인에 실패했습니다. 다시 시도해주세요.';
    }
  }
}
