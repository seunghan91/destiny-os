import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../core/services/pwa/pwa_service.dart';

/// PWA 설치 프롬프트 위젯
/// 
/// 사용자에게 PWA 설치를 유도하는 배너/다이얼로그
/// 베스트 프랙티스:
/// - 사용자가 앱을 충분히 사용한 후 표시 (예: 사주 결과 확인 후)
/// - 너무 자주 표시하지 않음 (하루에 1번 또는 3일에 1번)
/// - 쉽게 닫을 수 있는 옵션 제공
/// - 설치 혜택을 명확히 전달
class PwaInstallPrompt extends StatefulWidget {
  /// 프롬프트 유형
  final PwaPromptType type;
  
  /// 닫기 콜백
  final VoidCallback? onDismiss;
  
  /// 설치 완료 콜백
  final VoidCallback? onInstalled;

  const PwaInstallPrompt({
    super.key,
    this.type = PwaPromptType.banner,
    this.onDismiss,
    this.onInstalled,
  });

  @override
  State<PwaInstallPrompt> createState() => _PwaInstallPromptState();

  /// 프롬프트 표시 여부 확인
  /// 
  /// 조건:
  /// - 웹 플랫폼
  /// - 아직 설치되지 않음
  /// - 하루에 1번만 표시
  /// - 3회 이상 닫으면 일주일간 표시 안 함
  static Future<bool> shouldShowPrompt() async {
    // 웹이 아니면 표시 안 함
    if (!kIsWeb) return false;

    final pwaService = PwaService();
    await pwaService.initialize();

    // 이미 설치되었으면 표시 안 함
    if (pwaService.isInstalled) return false;

    // 설치 가능하지 않으면 표시 안 함 (iOS Safari 제외)
    if (!pwaService.isInstallable && !pwaService.isIosSafari) return false;

    // SharedPreferences로 표시 빈도 체크
    final prefs = await SharedPreferences.getInstance();
    
    // 마지막 표시 시간
    final lastShown = prefs.getInt('pwa_prompt_last_shown') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final oneDayMs = 24 * 60 * 60 * 1000;
    
    // 하루가 지나지 않았으면 표시 안 함
    if (now - lastShown < oneDayMs) return false;

    // 닫은 횟수 확인
    final dismissCount = prefs.getInt('pwa_prompt_dismiss_count') ?? 0;
    
    // 3회 이상 닫았으면 일주일 후에 표시
    if (dismissCount >= 3) {
      final lastDismiss = prefs.getInt('pwa_prompt_last_dismiss') ?? 0;
      final oneWeekMs = 7 * oneDayMs;
      if (now - lastDismiss < oneWeekMs) return false;
      
      // 일주일 지났으면 카운트 리셋
      await prefs.setInt('pwa_prompt_dismiss_count', 0);
    }

    return true;
  }

  /// 프롬프트 표시 기록
  static Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pwa_prompt_last_shown', DateTime.now().millisecondsSinceEpoch);
  }

  /// 프롬프트 닫기 기록
  static Future<void> markDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt('pwa_prompt_dismiss_count') ?? 0) + 1;
    await prefs.setInt('pwa_prompt_dismiss_count', count);
    await prefs.setInt('pwa_prompt_last_dismiss', DateTime.now().millisecondsSinceEpoch);
  }

  /// 다이얼로그로 표시
  static Future<void> showAsDialog(BuildContext context) async {
    if (!await shouldShowPrompt()) return;

    await markShown();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PwaInstallPrompt(
        type: PwaPromptType.bottomSheet,
        onDismiss: () {
          markDismissed();
          Navigator.of(context).pop();
        },
        onInstalled: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _PwaInstallPromptState extends State<PwaInstallPrompt> 
    with SingleTickerProviderStateMixin {
  final PwaService _pwaService = PwaService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isInstalling = false;

  @override
  void initState() {
    super.initState();
    _pwaService.initialize();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleInstall() async {
    HapticFeedback.mediumImpact();
    
    setState(() => _isInstalling = true);
    
    final result = await _pwaService.showInstallPrompt();
    
    setState(() => _isInstalling = false);
    
    switch (result) {
      case PwaInstallResult.accepted:
        widget.onInstalled?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('앱이 설치되었습니다! 🎉'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        break;
      case PwaInstallResult.iosManualInstall:
        _showIosInstallGuide();
        break;
      case PwaInstallResult.dismissed:
      case PwaInstallResult.notAvailable:
      case PwaInstallResult.error:
        // 무시
        break;
      default:
        break;
    }
  }

  void _showIosInstallGuide() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // 아이콘
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryLight,
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(80),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text('📲', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              'iPhone/iPad에 설치하기',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            
            Text(
              _pwaService.installInstructions,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryOf(context),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // 단계별 안내
            _buildIosStep(1, '하단의 공유 버튼을 탭하세요', '📤'),
            const SizedBox(height: 12),
            _buildIosStep(2, '"홈 화면에 추가"를 선택하세요', '➕'),
            const SizedBox(height: 12),
            _buildIosStep(3, '추가 버튼을 탭하면 완료!', '✅'),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '확인',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIosStep(int step, String text, String emoji) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantOf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$step',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ),
          Text(emoji, style: const TextStyle(fontSize: 24)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == PwaPromptType.banner) {
      return _buildBanner();
    } else {
      return _buildBottomSheet();
    }
  }

  Widget _buildBanner() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withAlpha(25),
                AppColors.primaryLight.withAlpha(15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withAlpha(50),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('📱', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '앱으로 설치하기',
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '홈 화면에 추가하고 알림 받기',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: widget.onDismiss,
                child: Text(
                  '나중에',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiaryOf(context),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              ElevatedButton(
                onPressed: _isInstalling ? null : _handleInstall,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: _isInstalling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('설치'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // 아이콘
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryLight,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(100),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: Text('🔮', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 20),
          
          Text(
            'Destiny.OS 앱 설치',
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            '홈 화면에 추가하고\n더 편리하게 운세를 확인하세요',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryOf(context),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // 혜택 목록
          ..._pwaService.installBenefits.map((benefit) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    benefit,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                ),
              ],
            ),
          )),
          
          const SizedBox(height: 24),
          
          // 버튼
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onDismiss,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondaryOf(context),
                    side: BorderSide(color: AppColors.grey300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    '나중에',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isInstalling ? null : _handleInstall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isInstalling
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.download_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '지금 설치하기',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 프롬프트 유형
enum PwaPromptType {
  /// 상단/하단 배너
  banner,
  /// 바텀 시트
  bottomSheet,
}
