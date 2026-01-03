import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../../../core/services/auth/auth_manager.dart';
import '../../../../core/services/auth/auth_service.dart';
import '../../../../core/services/auth/user_profile_service.dart';
import '../../../../core/services/apps_in_toss/apps_in_toss_service.dart';
import '../../../../core/services/credit/unified_credit_service.dart';
import '../../../../core/services/auth/credit_service.dart';

/// 설정 페이지 상단 로그인 섹션 위젯
class LoginSectionWidget extends StatefulWidget {
  final VoidCallback? onLoginStateChanged;

  const LoginSectionWidget({super.key, this.onLoginStateChanged});

  @override
  State<LoginSectionWidget> createState() => _LoginSectionWidgetState();
}

class _LoginSectionWidgetState extends State<LoginSectionWidget> {
  final AuthManager _authManager = AuthManager();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authManager.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _authManager.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {});
      widget.onLoginStateChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_authManager.isAuthenticated) {
      return _buildAuthenticatedSection();
    } else {
      return _buildUnauthenticatedSection();
    }
  }

  /// 로그인 전 섹션
  Widget _buildUnauthenticatedSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primaryLight.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '로그인해서 사주정보 저장하기',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textPrimaryOf(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '로그인하면 사주 정보가 저장되어\n다음에도 바로 이용할 수 있어요',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondaryOf(context),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 로그인 버튼들
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Column(
                children: [
                  // Google 로그인
                  _buildLoginButton(
                    icon: _buildGoogleIcon(),
                    label: 'Google로 계속하기',
                    backgroundColor: Colors.white,
                    textColor: Colors.black87,
                    onTap: _signInWithGoogle,
                  ),
                  const SizedBox(height: 10),
                  // Apple 로그인
                  _buildLoginButton(
                    icon: const Icon(
                      Icons.apple,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: 'Apple로 계속하기',
                    backgroundColor: Colors.black,
                    textColor: Colors.white,
                    onTap: _signInWithApple,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// 로그인 후 섹션
  Widget _buildAuthenticatedSection() {
    final user = _authManager.firebaseUser;
    final profile = _authManager.userProfile;
    final creditBalance = _authManager.creditBalance;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowOf(
              context,
              lightOpacity: 0.04,
              darkOpacity: 0.12,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 프로필 정보
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 프로필 아바타
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? Icon(Icons.person, color: AppColors.primary, size: 28)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user?.displayName ??
                                  profile?.displayName ??
                                  '사용자',
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textPrimaryOf(context),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildProviderBadge(),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondaryOf(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.borderLightOf(context)),

          // 크레딧 잔액
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '사용권 잔액',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                      Text(
                        '$creditBalance회',
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.textPrimaryOf(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _showPurchaseDialog,
                  child: Text(
                    '충전하기',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 사주 정보 저장 상태
          if (profile != null) ...[
            Divider(height: 1, color: AppColors.borderLightOf(context)),
            _buildSajuInfoSection(profile),
          ],

          Divider(height: 1, color: AppColors.borderLightOf(context)),

          // 로그아웃 버튼
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _signOut,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout,
                      size: 18,
                      color: AppColors.textSecondaryOf(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '로그아웃',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 사주 정보 섹션
  Widget _buildSajuInfoSection(UserProfile profile) {
    final hasSajuInfo = profile.hasSajuInfo;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasSajuInfo
                  ? Colors.green.withValues(alpha: 0.15)
                  : AppColors.grey200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasSajuInfo ? Icons.check_circle : Icons.info_outline,
              color: hasSajuInfo ? Colors.green : AppColors.grey500,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '사주 정보',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
                Text(
                  hasSajuInfo ? '저장됨' : '미설정',
                  style: AppTypography.bodyMedium.copyWith(
                    color: hasSajuInfo
                        ? Colors.green
                        : AppColors.textSecondaryOf(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (!hasSajuInfo)
            TextButton(
              onPressed: _showSajuInputDialog,
              child: Text(
                '설정하기',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 인증 제공자 배지
  Widget _buildProviderBadge() {
    final provider = _authManager.authProvider;
    if (provider == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: provider == AuthProvider.google
            ? Colors.blue.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        provider == AuthProvider.google ? 'Google' : 'Apple',
        style: AppTypography.caption.copyWith(
          color: provider == AuthProvider.google ? Colors.blue : Colors.grey,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 로그인 버튼 빌더
  Widget _buildLoginButton({
    required Widget icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Google 아이콘
  Widget _buildGoogleIcon() {
    return SizedBox(
      width: 20,
      height: 20,
      child: kIsWeb
          ? const Icon(Icons.g_mobiledata, color: Colors.red, size: 24)
          : Image.network(
              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
              width: 20,
              height: 20,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.g_mobiledata, color: Colors.red, size: 24),
            ),
    );
  }

  /// Google 로그인
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final result = await _authManager.signInWithGoogle();

      if (!result.success && mounted) {
        _showErrorSnackBar(result.errorMessage ?? 'Google 로그인에 실패했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Apple 로그인
  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);

    try {
      final result = await _authManager.signInWithApple();

      if (!result.success && mounted) {
        _showErrorSnackBar(result.errorMessage ?? 'Apple 로그인에 실패했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 로그아웃
  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authManager.signOut();
    }
  }

  /// 충전하기 다이얼로그 - 웹에서 실제 결제 연동
  void _showPurchaseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.stars_rounded, color: Colors.amber),
            const SizedBox(width: 8),
            const Text('사용권 충전'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 5회권 옵션
            _buildCreditOption(credits: 5, price: 5000, isRecommended: true),
            const SizedBox(height: 12),
            // 안내 문구
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.grey600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      kIsWeb ? '토스페이먼츠로 안전하게 결제됩니다.' : '결제는 웹에서만 가능합니다.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.grey600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '취소',
              style: TextStyle(color: AppColors.textSecondaryOf(context)),
            ),
          ),
          if (kIsWeb)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _processPurchase(5, 5000);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('결제하기'),
            ),
        ],
      ),
    );
  }

  /// 크레딧 옵션 위젯
  Widget _buildCreditOption({
    required int credits,
    required int price,
    bool isRecommended = false,
  }) {
    final formattedPrice =
        '₩${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRecommended
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRecommended
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.amber.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: Colors.amber,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$credits회권',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isRecommended) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '인기',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'AI 상담, 대운 분석 등에 사용',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          Text(
            formattedPrice,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// 결제 처리
  Future<void> _processPurchase(int credits, int price) async {
    if (!kIsWeb) {
      _showErrorSnackBar('결제는 웹에서만 가능합니다.');
      return;
    }

    if (EnvConfig.betaPaymentsFree) {
      await UnifiedCreditService.addCredits(
        credits,
        type: CreditTransactionType.bonus,
        description: '베타테스트 기간 무료 제공 (사용권 ${credits}회)',
        paymentId: 'beta_free',
      );

      await _authManager.refreshCreditBalance();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('베타테스트 기간 무료로 제공됩니다. $credits회권이 충전되었습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // 로딩 다이얼로그
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final bridge = AppsInTossBridge();
      final orderId = 'credit_${DateTime.now().millisecondsSinceEpoch}';

      final paymentRequest = PaymentRequest(
        orderId: orderId,
        orderName: '사용권 $credits회권',
        amount: price,
      );

      final result = await bridge.requestPayment(paymentRequest);

      if (!mounted) return;
      Navigator.pop(context); // 로딩 닫기

      if (result.success) {
        // 크레딧 추가
        await UnifiedCreditService.addCredits(
          credits,
          type: CreditTransactionType.purchase,
          description: '사용권 $credits회권 구매',
          paymentId: result.paymentKey,
        );

        // 크레딧 새로고침
        await _authManager.refreshCreditBalance();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('결제 완료! $credits회권이 충전되었습니다.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        _showErrorSnackBar(result.errorMessage ?? '결제에 실패했습니다.');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 로딩 닫기
        _showErrorSnackBar('결제 중 오류가 발생했습니다: $e');
      }
    }
  }

  /// 사주 정보 입력 다이얼로그 - 입력 페이지로 이동
  void _showSajuInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('사주 정보 설정'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '생년월일과 시간을 입력하면\n사주 정보가 자동으로 저장됩니다.',
              style: AppTypography.bodyMedium.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '로그인 상태에서 입력한 정보는 자동 저장됩니다.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '나중에',
              style: TextStyle(color: AppColors.textSecondaryOf(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // 사주 입력 페이지로 이동
              context.go('/input');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('사주 입력하기'),
          ),
        ],
      ),
    );
  }

  /// 에러 스낵바
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
