import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';

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
  String _appVersion = '';

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
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_yaja_time', _useYajaTime);
    await prefs.setBool('use_solar_time', _useSolarTime);
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '설정',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
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
                const Divider(height: 1, color: AppColors.borderLight),
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

              // 알림 설정 섹션
              _buildSectionHeader('알림'),
              _buildSettingsCard([
                _buildSwitchTile(
                  title: '오늘의 운세 알림',
                  subtitle: '매일 아침 오늘의 운세를 알려드립니다',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                    _saveSettings();
                  },
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
                  title: '개인정보처리방침',
                  icon: Icons.privacy_tip_outlined,
                  onTap: () => _openUrl('https://destinyos.app/privacy'),
                ),
                const Divider(height: 1, color: AppColors.borderLight),
                _buildActionTile(
                  title: '이용약관',
                  icon: Icons.description_outlined,
                  onTap: () => _openUrl('https://destinyos.app/terms'),
                ),
                const Divider(height: 1, color: AppColors.borderLight),
                _buildActionTile(
                  title: '오픈소스 라이선스',
                  icon: Icons.code_outlined,
                  onTap: () => _showLicensePage(context),
                ),
                const Divider(height: 1, color: AppColors.borderLight),
                _buildInfoTile(
                  title: '앱 버전',
                  value: _appVersion,
                ),
              ]),

              const SizedBox(height: 24),

              // 법적 고지
              _buildDisclaimerCard(),

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
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
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
                color: iconColor ?? AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLarge.copyWith(
                        color: iconColor ?? AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 22,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
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
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '안내사항',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
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
              color: AppColors.textSecondary,
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
        content: const Text(
          '저장된 모든 사주 정보와 설정이 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.',
        ),
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
          content: Text(
            '모든 데이터가 초기화되었습니다',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.white),
          ),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
            AppColors.secondary.withValues(alpha: 0.05),
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
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '검증된 만세력과 명리 이론 적용',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textTertiary,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
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
            color: AppColors.surface,
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
                          colors: [AppColors.primary, AppColors.secondary],
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
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Destiny.OS의 핵심 기술',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: AppColors.textSecondary,
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
        color: AppColors.grey50,
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
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•  ',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
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
            AppColors.secondary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
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
                  color: AppColors.textPrimary,
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
          _buildAccuracyRow('대운 흐름', 0.75, '기본'),
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
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.grey200,
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
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '사주명리학은 동양 철학에 기반한 해석 체계입니다. '
              '재미와 참고용으로 활용해 주세요. '
              '중요한 결정은 전문가와 상담하시기 바랍니다.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
