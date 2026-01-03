import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'auth_service.dart';
import 'credit_service.dart';
import 'user_profile_service.dart';

/// 인증 상태
enum AuthStatus { initial, authenticated, unauthenticated }

/// 통합 인증 관리자
/// Firebase Auth + Supabase 프로필/크레딧 연동
class AuthManager extends ChangeNotifier {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  static const String guestSajuDraftKey = 'guest_saju_profile_draft_v1';

  final AuthService _authService = AuthService();
  UserProfileService? _profileService;
  CreditService? _creditService;

  // 상태
  AuthStatus _status = AuthStatus.initial;
  firebase_auth.User? _firebaseUser;
  UserProfile? _userProfile;
  int _creditBalance = 0;
  bool _isInitialized = false;

  StreamSubscription<firebase_auth.User?>? _authSubscription;

  // Getters
  AuthStatus get status => _status;
  firebase_auth.User? get firebaseUser => _firebaseUser;
  UserProfile? get userProfile => _userProfile;
  int get creditBalance => _creditBalance;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isInitialized => _isInitialized;

  /// 현재 인증 제공자 (google/apple)
  AuthProvider? get authProvider => _authService.currentAuthProvider;

  /// 사주 정보가 저장되어 있는지
  bool get hasSajuInfo => _userProfile?.hasSajuInfo ?? false;

  /// 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Supabase 서비스 초기화
      final supabase = Supabase.instance.client;
      _profileService = UserProfileService(client: supabase);
      _creditService = CreditService(client: supabase);
    } catch (e) {
      debugPrint(
        '⚠️  Supabase not initialized - AuthManager running in limited mode',
      );
    }

    // Firebase Auth 상태 구독
    _authSubscription = _authService.authStateChanges.listen(
      _onAuthStateChanged,
    );

    // 현재 사용자 확인
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      await _onAuthStateChanged(currentUser);
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }

    _isInitialized = true;
    debugPrint('✅ AuthManager initialized');
  }

  /// 인증 상태 변경 처리
  Future<void> _onAuthStateChanged(firebase_auth.User? user) async {
    _firebaseUser = user;

    if (user == null) {
      _status = AuthStatus.unauthenticated;
      _userProfile = null;
      _creditBalance = 0;
    } else {
      _status = AuthStatus.authenticated;
      await _loadUserData(user);
      await _importGuestSajuDraftIfPresent(user.uid);
    }

    notifyListeners();
  }

  Future<Map<String, dynamic>?> _loadGuestSajuDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(guestSajuDraftKey);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.cast<String, dynamic>();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearGuestSajuDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(guestSajuDraftKey);
    } catch (_) {}
  }

  Future<void> _importGuestSajuDraftIfPresent(String firebaseUid) async {
    if (_profileService == null) return;

    final draft = await _loadGuestSajuDraft();
    if (draft == null) return;

    try {
      final savedAtRaw = draft['savedAt'] as String?;
      if (savedAtRaw != null) {
        final savedAt = DateTime.tryParse(savedAtRaw);
        if (savedAt != null &&
            savedAt.isBefore(
              DateTime.now().subtract(const Duration(days: 2)),
            )) {
          await _clearGuestSajuDraft();
          return;
        }
      }

      final birthDateRaw = draft['birthDate'] as String?;
      final birthHour = (draft['birthHour'] as num?)?.toInt();
      final gender = draft['gender'] as String?;
      final isLunar = draft['isLunar'] as bool?;
      final mbti = draft['mbti'] as String?;
      final displayName = draft['name'] as String?;

      final birthDate = birthDateRaw != null
          ? DateTime.tryParse(birthDateRaw)
          : null;
      if (birthDate == null ||
          birthHour == null ||
          gender == null ||
          isLunar == null) {
        return;
      }

      final existing = _userProfile;
      final shouldImportFullSaju = existing == null || !existing.hasSajuInfo;
      final shouldImportMbti =
          (existing?.mbti == null || existing!.mbti!.isEmpty) &&
          (mbti != null && mbti.isNotEmpty);
      final shouldImportName =
          (existing?.displayName == null || existing!.displayName!.isEmpty) &&
          (displayName != null && displayName.isNotEmpty);

      if (!shouldImportFullSaju && !shouldImportMbti && !shouldImportName) {
        await _clearGuestSajuDraft();
        return;
      }

      _userProfile = await _profileService!.upsertProfile(
        firebaseUid: firebaseUid,
        birthDate: shouldImportFullSaju ? birthDate : null,
        birthHour: shouldImportFullSaju ? birthHour : null,
        gender: shouldImportFullSaju ? gender : null,
        isLunar: shouldImportFullSaju ? isLunar : null,
        mbti: shouldImportFullSaju ? mbti : (shouldImportMbti ? mbti : null),
        displayName: shouldImportName ? displayName : null,
      );

      await _clearGuestSajuDraft();
    } catch (e) {
      debugPrint('⚠️  Failed to import guest saju draft: $e');
    }
  }

  /// 사용자 데이터 로드 (프로필 + 크레딧)
  Future<void> _loadUserData(firebase_auth.User user) async {
    if (_profileService == null || _creditService == null) return;

    try {
      // 프로필 조회 또는 생성
      _userProfile = await _profileService!.getProfileByFirebaseUid(user.uid);

      if (_userProfile == null) {
        // 새 사용자 - 프로필 생성
        _userProfile = await _profileService!.upsertProfile(
          firebaseUid: user.uid,
          email: user.email,
          displayName: user.displayName,
          authProvider: _authService.currentAuthProvider?.name,
        );

        // 크레딧 초기화 (신규 가입 보너스: 0회, 필요시 변경)
        if (_userProfile != null) {
          await _creditService!.initializeCredit(
            _userProfile!.id,
            initialBalance: 0,
          );
        }
      }

      // 크레딧 잔액 조회
      if (_userProfile != null) {
        _creditBalance = await _creditService!.getBalance(_userProfile!.id);
      }

      debugPrint('✅ User data loaded: ${user.email}, credits: $_creditBalance');
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
    }
  }

  /// Google 로그인
  Future<AuthResult> signInWithGoogle() async {
    final result = await _authService.signInWithGoogle();
    if (result.success && result.user != null) {
      await _onAuthStateChanged(result.user);
    }
    return result;
  }

  /// Apple 로그인
  Future<AuthResult> signInWithApple() async {
    final result = await _authService.signInWithApple();
    if (result.success && result.user != null) {
      await _onAuthStateChanged(result.user);
    }
    return result;
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _authService.signOut();
    _status = AuthStatus.unauthenticated;
    _firebaseUser = null;
    _userProfile = null;
    _creditBalance = 0;
    notifyListeners();
  }

  /// 사주 정보 저장
  Future<bool> saveSajuInfo({
    required DateTime birthDate,
    required int birthHour,
    required String gender,
    required bool isLunar,
    String? mbti,
  }) async {
    if (_profileService == null || _firebaseUser == null) return false;

    try {
      _userProfile = await _profileService!.updateSajuInfo(
        firebaseUid: _firebaseUser!.uid,
        birthDate: birthDate,
        birthHour: birthHour,
        gender: gender,
        isLunar: isLunar,
        mbti: mbti,
      );

      notifyListeners();
      debugPrint('✅ Saju info saved');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving saju info: $e');
      return false;
    }
  }

  /// 크레딧 사용
  Future<CreditResult> useCredit({
    required FeatureType feature,
    int amount = 1,
    String? description,
  }) async {
    if (_creditService == null || _userProfile == null) {
      return CreditResult(success: false, message: '로그인이 필요합니다.');
    }

    final result = await _creditService!.useCredit(
      userId: _userProfile!.id,
      amount: amount,
      feature: feature,
      description: description,
    );

    if (result.success && result.newBalance != null) {
      _creditBalance = result.newBalance!;
      notifyListeners();
    }

    return result;
  }

  /// 크레딧 추가 (구매 완료 후 호출)
  Future<CreditResult> addCredit({
    required int amount,
    required CreditTransactionType type,
    String? description,
    String? paymentId,
  }) async {
    if (_creditService == null || _userProfile == null) {
      return CreditResult(success: false, message: '로그인이 필요합니다.');
    }

    final result = await _creditService!.addCredit(
      userId: _userProfile!.id,
      amount: amount,
      type: type,
      description: description,
      paymentId: paymentId,
    );

    if (result.success && result.newBalance != null) {
      _creditBalance = result.newBalance!;
      notifyListeners();
    }

    return result;
  }

  /// 크레딧 잔액 새로고침
  Future<void> refreshCreditBalance() async {
    if (_creditService == null || _userProfile == null) return;

    _creditBalance = await _creditService!.getBalance(_userProfile!.id);
    notifyListeners();
  }

  /// 기능 사용 가능 여부
  bool canUseFeature({int requiredCredits = 1}) {
    return _creditBalance >= requiredCredits;
  }

  /// 거래 이력 조회
  Future<List<CreditTransaction>> getTransactionHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    if (_creditService == null || _userProfile == null) return [];

    return _creditService!.getTransactionHistory(
      userId: _userProfile!.id,
      limit: limit,
      offset: offset,
    );
  }

  /// 계정 삭제
  Future<bool> deleteAccount() async {
    if (_firebaseUser == null) return false;

    // Supabase 프로필 삭제
    if (_profileService != null) {
      await _profileService!.deleteProfile(_firebaseUser!.uid);
    }

    // Firebase 계정 삭제
    final success = await _authService.deleteAccount();

    if (success) {
      _status = AuthStatus.unauthenticated;
      _firebaseUser = null;
      _userProfile = null;
      _creditBalance = 0;
      notifyListeners();
    }

    return success;
  }

  /// 리소스 해제
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
