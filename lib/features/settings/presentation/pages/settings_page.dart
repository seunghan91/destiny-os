import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../core/services/notifications/firebase_notification_service.dart';
import '../../../../core/services/pwa/pwa_service.dart';
import '../../../../core/services/pwa/web_notification_service.dart';
import '../../../../core/services/usage/usage_service.dart';
import '../../../../core/di/injection.dart';
import '../widgets/login_section_widget.dart';

/// 설정 페이지
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _useYajaTime = false; // 야자시 적용 여부
  bool _useSolarTime = true; // 진태양시 적용 여부
  bool _notificationsEnabled = false; // 알림 설정
  ThemeMode _themeMode = ThemeMode.system; // 테마 모드
  String _appVersion = '';

  // 개발자 모드
  bool _developerMode = false;
  int _versionTapCount = 0;
  UsageStatus? _usageStatus;
  bool _isLoadingUsage = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useYajaTime = prefs.getBool('use_yaja_time') ?? false;
      _useSolarTime = prefs.getBool('use_solar_time') ?? true;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      final themeIndex = prefs.getInt('theme_mode') ?? 0;
      _themeMode = ThemeMode.values[themeIndex];
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_yaja_time', _useYajaTime);
    await prefs.setBool('use_solar_time', _useSolarTime);
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setInt('theme_mode', _themeMode.index);
  }

  void _changeTheme(ThemeMode mode) {
    setState(() => _themeMode = mode);
    _saveSettings();
    // ThemeNotifier를 통해 앱 전체 테마 변경
    ThemeNotifier.of(context)?.setThemeMode(mode);
  }

  /// 알림 토글 처리
  Future<void> _handleNotificationToggle(bool value) async {
    try {
      final notificationService = getIt<FirebaseNotificationService>();

      if (value) {
        // 알림 활성화
        final isEnabled = await notificationService.isNotificationEnabled();

        if (!isEnabled) {
          // 권한이 없으면 권한 요청
          await notificationService.initialize();

          // 권한 재확인
          final recheckEnabled = await notificationService
              .isNotificationEnabled();

          if (!recheckEnabled) {
            // 권한 거부됨
            if (mounted) {
              _showNotificationPermissionDialog();
            }
            return;
          }
        }

        // 일일 운세 알림 토픽 구독
        await notificationService.subscribeToTopic('daily_fortune');

        setState(() => _notificationsEnabled = true);
        await _saveSettings();

        if (mounted) {
          _showSnackBar('알림이 활성화되었습니다 ✅');
        }
      } else {
        // 알림 비활성화
        await notificationService.unsubscribeFromTopic('daily_fortune');

        setState(() => _notificationsEnabled = false);
        await _saveSettings();

        if (mounted) {
          _showSnackBar('알림이 비활성화되었습니다');
        }
      }
    } catch (e) {
      debugPrint('❌ Notification toggle failed: $e');
      if (mounted) {
        _showSnackBar('알림 설정에 실패했습니다. Firebase 설정을 확인해주세요.');
      }
    }
  }

  /// 알림 권한 안내 다이얼로그
  void _showNotificationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림 권한 필요'),
        content: const Text(
          '오늘의 운세 알림을 받으려면 알림 권한이 필요합니다.\n\n'
          '설정 > Destiny.OS > 알림에서 권한을 허용해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 스낵바 표시
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      setState(() {
        _appVersion = '1.0.0';
      });
    }
  }

  /// 앱 버전 탭 처리 (5번 탭시 개발자 모드 활성화)
  void _handleVersionTap() {
    _versionTapCount++;
    if (_versionTapCount >= 5) {
      _versionTapCount = 0;
      setState(() => _developerMode = !_developerMode);
      if (_developerMode) {
        _loadUsageStatus();
        _showSnackBar('🔧 개발자 모드가 활성화되었습니다');
      } else {
        _showSnackBar('개발자 모드가 비활성화되었습니다');
      }
    }
  }

  /// 사용량 상태 로드
  Future<void> _loadUsageStatus() async {
    if (!getIt.isRegistered<UsageService>()) return;

    setState(() => _isLoadingUsage = true);
    try {
      final usageService = getIt<UsageService>();
      final status = await usageService.getUsageStatus();
      setState(() {
        _usageStatus = status;
        _isLoadingUsage = false;
      });
    } catch (e) {
      setState(() => _isLoadingUsage = false);
      debugPrint('❌ Failed to load usage status: $e');
    }
  }

  /// 서비스 일시 중단/재개 토글
  Future<void> _toggleServicePause() async {
    if (_usageStatus == null || !getIt.isRegistered<UsageService>()) return;

    final usageService = getIt<UsageService>();
    final newPauseState = !_usageStatus!.isPaused;

    final success = await usageService.toggleServicePause(newPauseState);
    if (success) {
      await _loadUsageStatus();
      _showSnackBar(newPauseState ? '⏸️ 서비스가 일시 중단되었습니다' : '▶️ 서비스가 재개되었습니다');
    } else {
      _showSnackBar('설정 변경에 실패했습니다');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceOf(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimaryOf(context),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '설정',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // 로그인 섹션 (상단 고정)
              _buildSectionHeader('계정'),
              const LoginSectionWidget(),

              const SizedBox(height: 24),

              // 사주 설정 섹션
              _buildSectionHeader('사주 계산 설정'),
              _buildSettingsCard([
                _buildSwitchTile(
                  title: '야자시(夜子時) 적용',
                  subtitle: '23:00~00:00 출생자의 일주를 다음날로 계산합니다',
                  value: _useYajaTime,
                  onChanged: (value) {
                    setState(() => _useYajaTime = value);
                    _saveSettings();
                  },
                ),
                Divider(height: 1, color: AppColors.borderLightOf(context)),
                _buildSwitchTile(
                  title: '진태양시(真太陽時) 적용',
                  subtitle: '출생지 경도에 따른 시간 보정을 적용합니다',
                  value: _useSolarTime,
                  onChanged: (value) {
                    setState(() => _useSolarTime = value);
                    _saveSettings();
                  },
                ),
              ]),

              const SizedBox(height: 24),

              // 화면 설정 섹션
              _buildSectionHeader('화면'),
              _buildSettingsCard([_buildThemeSelector()]),

              const SizedBox(height: 24),

              // PWA 설치 섹션 (웹에서만 표시)
              if (kIsWeb) ...[
                _buildSectionHeader('앱 설치'),
                _buildPwaInstallCard(),
                const SizedBox(height: 24),
              ],

              // 알림 설정 섹션
              _buildSectionHeader('알림'),
              _buildSettingsCard([
                // 웹에서는 웹 알림 사용
                if (kIsWeb)
                  _buildWebNotificationTile()
                else
                  _buildSwitchTile(
                    title: '오늘의 운세 알림',
                    subtitle: '매일 아침 오늘의 운세를 알려드립니다',
                    value: _notificationsEnabled,
                    onChanged: _handleNotificationToggle,
                  ),
              ]),

              const SizedBox(height: 24),

              // 데이터 관리 섹션
              _buildSectionHeader('데이터 관리'),
              _buildSettingsCard([
                _buildActionTile(
                  title: '데이터 초기화',
                  subtitle: '저장된 모든 사주 정보와 설정을 삭제합니다',
                  icon: Icons.delete_outline,
                  iconColor: AppColors.error,
                  onTap: _showResetConfirmDialog,
                ),
              ]),

              const SizedBox(height: 24),

              // 사주 분석 기술 섹션
              _buildSectionHeader('사주 분석 기술'),
              _buildTechnologyCard(),

              const SizedBox(height: 24),

              // 정보 섹션
              _buildSectionHeader('정보'),
              _buildSettingsCard([
                _buildActionTile(
                  title: '서비스 소개',
                  icon: Icons.info_outline,
                  onTap: () =>
                      _openUrl('https://destiny-os-2026.web.app/about'),
                ),
                Divider(height: 1, color: AppColors.borderLightOf(context)),
                _buildActionTile(
                  title: '개인정보처리방침',
                  icon: Icons.privacy_tip_outlined,
                  onTap: () =>
                      _openUrl('https://destiny-os-2026.web.app/privacy'),
                ),
                Divider(height: 1, color: AppColors.borderLightOf(context)),
                _buildActionTile(
                  title: '이용약관',
                  icon: Icons.description_outlined,
                  onTap: () =>
                      _openUrl('https://destiny-os-2026.web.app/terms'),
                ),
                Divider(height: 1, color: AppColors.borderLightOf(context)),
                _buildActionTile(
                  title: '환불(청약철회) 정책',
                  icon: Icons.receipt_long_outlined,
                  onTap: () =>
                      _openUrl('https://destiny-os-2026.web.app/refund'),
                ),
                Divider(height: 1, color: AppColors.borderLightOf(context)),
                _buildActionTile(
                  title: '고객센터',
                  subtitle: '문의 내용을 남겨주세요',
                  icon: Icons.support_agent_outlined,
                  onTap: () => context.push('/support'),
                ),
                Divider(height: 1, color: AppColors.borderLightOf(context)),
                _buildActionTile(
                  title: '오픈소스 라이선스',
                  icon: Icons.code_outlined,
                  onTap: () => _showLicensePage(context),
                ),
                Divider(height: 1, color: AppColors.borderLightOf(context)),
                _buildVersionTile(),
              ]),

              const SizedBox(height: 24),

              // 법적 고지
              _buildDisclaimerCard(),

              // 개발자 모드 (앱 버전 5번 탭시 활성화)
              if (_developerMode) ...[
                const SizedBox(height: 24),
                _buildSectionHeader('🔧 개발자 모드'),
                _buildUsageMonitorCard(),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondaryOf(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
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
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimaryOf(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    String? subtitle,
    required IconData icon,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: iconColor ?? AppColors.textSecondaryOf(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLarge.copyWith(
                        color: iconColor ?? AppColors.textPrimaryOf(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiaryOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '테마',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimaryOf(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '앱의 외관을 선택합니다',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildThemeOption(
                icon: Icons.brightness_auto,
                label: '시스템',
                isSelected: _themeMode == ThemeMode.system,
                onTap: () => _changeTheme(ThemeMode.system),
              ),
              const SizedBox(width: 10),
              _buildThemeOption(
                icon: Icons.light_mode,
                label: '라이트',
                isSelected: _themeMode == ThemeMode.light,
                onTap: () => _changeTheme(ThemeMode.light),
              ),
              const SizedBox(width: 10),
              _buildThemeOption(
                icon: Icons.dark_mode,
                label: '다크',
                isSelected: _themeMode == ThemeMode.dark,
                onTap: () => _changeTheme(ThemeMode.dark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surfaceVariantOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondaryOf(context),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondaryOf(context),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisclaimerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantOf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: AppColors.textSecondaryOf(context),
              ),
              const SizedBox(width: 8),
              Text(
                '안내사항',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryOf(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• 운세는 참고용이며 과학적으로 검증된 것이 아닙니다.\n'
            '• 23시~00시 출생자는 학파에 따라 결과가 다를 수 있습니다.\n'
            '• 사주팔자는 동양 철학의 일부로, 재미로 즐겨주세요.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryOf(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('데이터 초기화'),
        content: const Text('저장된 모든 사주 정보와 설정이 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('취소'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('초기화'),
            onPressed: () async {
              Navigator.pop(context);
              await _resetAllData();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // 설정 다시 로드
    await _loadSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('모든 데이터가 초기화되었습니다'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('링크를 열 수 없습니다'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showLicensePage(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'Destiny.OS',
      applicationVersion: _appVersion,
      applicationLegalese: '2024 Destiny.OS. All rights reserved.',
    );
  }

  /// 사주 분석 기술 카드
  Widget _buildTechnologyCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primaryLight.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showTechnologyDetails,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '정통 명리학 기반 분석',
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textPrimaryOf(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '검증된 만세력과 명리 이론 적용',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textTertiaryOf(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 기술 태그들
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTechTag('만세력 엔진', Icons.calendar_month),
                    _buildTechTag('오행 분석', Icons.blur_circular),
                    _buildTechTag('십성 계산', Icons.star_outline),
                    _buildTechTag('궁합 알고리즘', Icons.favorite_outline),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTechTag(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLightOf(context), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondaryOf(context)),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryOf(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 기술 상세 정보 바텀시트
  void _showTechnologyDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // 핸들바
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 헤더
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '사주 분석 기술',
                            style: AppTypography.headlineSmall.copyWith(
                              color: AppColors.textPrimaryOf(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Destiny.OS의 핵심 기술',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 콘텐츠
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildTechSection(
                      icon: Icons.calendar_month,
                      iconColor: const Color(0xFF5B8DEF),
                      title: '신뢰할 수 있는 만세력 엔진',
                      items: [
                        '검증된 lunar 라이브러리 기반',
                        '1900~2100년 음양력 정확 변환',
                        '24절기 기준 정확한 월주 계산',
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTechSection(
                      icon: Icons.auto_fix_high,
                      iconColor: const Color(0xFFE57373),
                      title: '정통 명리학 이론 적용',
                      items: [
                        '오자시두법(五子時頭法) 시주 계산',
                        '절기 기반 대운수 정밀 계산 (3일=1년 환산)',
                        '양남음녀 순행, 음남양녀 역행 대운',
                        '천간합 및 지지 육합/삼합/충/형/해 분석',
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTechSection(
                      icon: Icons.science_outlined,
                      iconColor: const Color(0xFF81C784),
                      title: '과학적 접근',
                      items: [
                        '태양시 보정 옵션 (KST → 진태양시)',
                        '오행 상생상극의 수학적 모델링',
                        '십성(十星) 기반 성격·운세 분석',
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTechSection(
                      icon: Icons.favorite_outline,
                      iconColor: const Color(0xFFFF8A80),
                      title: '궁합 분석 알고리즘',
                      items: [
                        '천간합(甲己, 乙庚, 丙辛, 丁壬, 戊癸)',
                        '지지 육합·삼합·충·형·해 종합 평가',
                        '오행 균형 및 보완 관계 분석',
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildAccuracyCard(),
                    const SizedBox(height: 20),
                    _buildTechDisclaimerCard(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantOf(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimaryOf(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•  ',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryOf(context),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primaryLight.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '현재 버전 분석 정확도',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimaryOf(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildAccuracyRow('사주팔자 계산', 0.95, '높음'),
          const SizedBox(height: 10),
          _buildAccuracyRow('십성 분석', 0.85, '양호'),
          const SizedBox(height: 10),
          _buildAccuracyRow('궁합 분석', 0.90, '높음'),
          const SizedBox(height: 10),
          _buildAccuracyRow('대운 흐름', 0.88, '양호'),
        ],
      ),
    );
  }

  Widget _buildAccuracyRow(String label, double value, String level) {
    Color levelColor;
    switch (level) {
      case '높음':
        levelColor = const Color(0xFF4CAF50);
        break;
      case '양호':
        levelColor = const Color(0xFF2196F3);
        break;
      default:
        levelColor = const Color(0xFFFF9800);
    }

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariantOf(context),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  color: levelColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: levelColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            level,
            style: AppTypography.caption.copyWith(
              color: levelColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTechDisclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantOf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: AppColors.textSecondaryOf(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '사주명리학은 동양 철학에 기반한 해석 체계입니다. '
              '재미와 참고용으로 활용해 주세요. '
              '중요한 결정은 전문가와 상담하시기 바랍니다.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryOf(context),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// PWA 설치 카드
  Widget _buildPwaInstallCard() {
    final pwaService = PwaService();

    return FutureBuilder(
      future: pwaService.initialize().then((_) => null),
      builder: (context, snapshot) {
        final isInstalled = pwaService.isInstalled;
        final isInstallable =
            pwaService.isInstallable || pwaService.isIosSafari;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isInstalled
                  ? [
                      AppColors.success.withAlpha(20),
                      AppColors.success.withAlpha(10),
                    ]
                  : [
                      AppColors.primary.withAlpha(15),
                      AppColors.primaryLight.withAlpha(10),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isInstalled
                  ? AppColors.success.withAlpha(40)
                  : AppColors.primary.withAlpha(30),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isInstalled
                  ? null
                  : () async {
                      if (pwaService.isIosSafari) {
                        _showIosInstallGuide();
                      } else {
                        final result = await pwaService.showInstallPrompt();
                        if (result == PwaInstallResult.accepted && mounted) {
                          setState(() {});
                          _showSnackBar('앱이 설치되었습니다! 🎉');
                        }
                      }
                    },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isInstalled
                            ? AppColors.success.withAlpha(30)
                            : AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          isInstalled
                              ? Icons.check_circle
                              : Icons.download_rounded,
                          color: isInstalled
                              ? AppColors.success
                              : AppColors.primary,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isInstalled ? '앱이 설치됨' : '홈 화면에 추가',
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textPrimaryOf(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isInstalled
                                ? '홈 화면에서 바로 실행하세요'
                                : '앱처럼 빠르게 실행하고 알림 받기',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isInstalled && isInstallable)
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.textTertiaryOf(context),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// iOS 설치 가이드 표시
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
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(18),
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

  /// 웹 알림 설정 타일
  Widget _buildWebNotificationTile() {
    final webNotificationService = WebNotificationService();

    return FutureBuilder(
      future: webNotificationService.initialize().then(
        (_) => webNotificationService.isNotificationsEnabled(),
      ),
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? false;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오늘의 운세 알림',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textPrimaryOf(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEnabled ? '매일 아침 운세를 알려드립니다' : '알림을 받지 않음',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : CupertinoSwitch(
                      value: isEnabled,
                      onChanged: (value) async {
                        if (value) {
                          final result = await webNotificationService
                              .requestPermission();
                          if (result == NotificationPermissionStatus.granted) {
                            await webNotificationService.subscribeToTopic(
                              NotificationTopics.dailyFortune,
                            );
                            setState(() {});
                            if (mounted) {
                              _showSnackBar('알림이 활성화되었습니다 ✅');
                            }
                          } else if (result ==
                              NotificationPermissionStatus.denied) {
                            if (mounted) {
                              _showNotificationPermissionDialog();
                            }
                          }
                        } else {
                          await webNotificationService.disableNotifications();
                          setState(() {});
                          if (mounted) {
                            _showSnackBar('알림이 비활성화되었습니다');
                          }
                        }
                      },
                      activeTrackColor: AppColors.primary,
                    ),
            ],
          ),
        );
      },
    );
  }

  /// 앱 버전 타일 (5번 탭시 개발자 모드)
  Widget _buildVersionTile() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleVersionTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 22,
                color: AppColors.textSecondaryOf(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '앱 버전',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimaryOf(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                _appVersion,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
              if (_developerMode) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'DEV',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 사용량 모니터링 카드 (개발자 모드)
  Widget _buildUsageMonitorCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1a0a2e).withValues(alpha: 0.9),
            const Color(0xFF2d1b4e).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '오늘의 사용량',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _usageStatus != null
                            ? '${_usageStatus!.date.month}/${_usageStatus!.date.day} 기준'
                            : '로딩 중...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadUsageStatus,
                  icon: _isLoadingUsage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.refresh, color: Colors.white),
                ),
              ],
            ),
          ),

          // 사용량 현황
          if (_usageStatus != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // 프로그레스 바
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (_usageStatus!.usagePercentage / 100).clamp(
                        0,
                        1,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _usageStatus!.usagePercentage >= 80
                                ? [Colors.red, Colors.orange]
                                : [
                                    const Color(0xFFFFD700),
                                    const Color(0xFFDAA520),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_usageStatus!.totalCount.toStringAsFixed(0)} / ${_usageStatus!.dailyLimit}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_usageStatus!.usagePercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: _usageStatus!.usagePercentage >= 80
                              ? Colors.orange
                              : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 상세 통계
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    '사주',
                    _usageStatus!.sajuCount,
                    Icons.auto_awesome,
                  ),
                  _buildStatItem(
                    'MBTI',
                    _usageStatus!.mbtiCount,
                    Icons.psychology,
                  ),
                  _buildStatItem(
                    '궁합',
                    _usageStatus!.compatibilityCount,
                    Icons.favorite,
                  ),
                  _buildStatItem(
                    '상담',
                    _usageStatus!.consultationCount,
                    Icons.chat,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 알림 표시
            if (_usageStatus!.alerts.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _usageStatus!.alerts.first.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 서비스 제어 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _toggleServicePause,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _usageStatus!.isPaused
                            ? Colors.green
                            : Colors.red.withValues(alpha: 0.8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(
                        _usageStatus!.isPaused ? Icons.play_arrow : Icons.pause,
                      ),
                      label: Text(
                        _usageStatus!.isPaused ? '서비스 재개' : '서비스 일시 중단',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else if (!_isLoadingUsage) ...[
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Supabase 연결을 확인해주세요',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
