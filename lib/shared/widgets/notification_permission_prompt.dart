import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../core/services/pwa/web_notification_service.dart';

/// 알림 권한 요청 프롬프트
/// 
/// PWA 설치 후 또는 앱 사용 중 알림 권한을 요청하는 UI
class NotificationPermissionPrompt extends StatefulWidget {
  final VoidCallback? onGranted;
  final VoidCallback? onDenied;
  final VoidCallback? onDismiss;

  const NotificationPermissionPrompt({
    super.key,
    this.onGranted,
    this.onDenied,
    this.onDismiss,
  });

  @override
  State<NotificationPermissionPrompt> createState() => _NotificationPermissionPromptState();

  /// 다이얼로그로 표시
  static Future<void> showAsDialog(BuildContext context) async {
    if (!kIsWeb) return;

    final service = WebNotificationService();
    await service.initialize();

    // 이미 권한이 있거나 거부된 경우 표시 안 함
    if (service.permissionStatus == NotificationPermissionStatus.granted ||
        service.permissionStatus == NotificationPermissionStatus.denied) {
      return;
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => NotificationPermissionPrompt(
        onGranted: () => Navigator.pop(context),
        onDenied: () => Navigator.pop(context),
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }
}

class _NotificationPermissionPromptState extends State<NotificationPermissionPrompt> {
  final WebNotificationService _service = WebNotificationService();
  bool _isRequesting = false;

  Future<void> _requestPermission() async {
    HapticFeedback.mediumImpact();
    
    setState(() => _isRequesting = true);
    
    final result = await _service.requestPermission();
    
    setState(() => _isRequesting = false);
    
    if (result == NotificationPermissionStatus.granted) {
      widget.onGranted?.call();
      
      // 기본 토픽 구독
      await _service.subscribeToTopic(NotificationTopics.dailyFortune);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.white),
                SizedBox(width: 12),
                Text('알림이 활성화되었습니다! 🔔'),
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
    } else if (result == NotificationPermissionStatus.denied) {
      widget.onDenied?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  AppColors.fortuneGood,
                  AppColors.fortuneGood.withAlpha(180),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.fortuneGood.withAlpha(80),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: Text('🔔', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 20),
          
          Text(
            '매일 운세 알림 받기',
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            '매일 아침 당신의 운세를\n푸시 알림으로 받아보세요',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryOf(context),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // 혜택 목록
          _buildBenefit(Icons.wb_sunny_outlined, '매일 아침 오늘의 운세 알림'),
          const SizedBox(height: 10),
          _buildBenefit(Icons.event_note, '중요한 운세 변화 알림'),
          const SizedBox(height: 10),
          _buildBenefit(Icons.auto_awesome, '맞춤형 행운의 조언'),
          
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
                  onPressed: _isRequesting ? null : _requestPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.fortuneGood,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isRequesting
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
                            const Icon(Icons.notifications_active, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '알림 허용하기',
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

  Widget _buildBenefit(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.fortuneGood.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.fortuneGood,
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
      ],
    );
  }
}

/// 알림 설정 타일 (설정 페이지용)
class NotificationSettingsTile extends StatefulWidget {
  const NotificationSettingsTile({super.key});

  @override
  State<NotificationSettingsTile> createState() => _NotificationSettingsTileState();
}

class _NotificationSettingsTileState extends State<NotificationSettingsTile> {
  final WebNotificationService _service = WebNotificationService();
  bool _isEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (!kIsWeb) {
      setState(() => _isLoading = false);
      return;
    }

    await _service.initialize();
    final enabled = await _service.isNotificationsEnabled();
    
    if (mounted) {
      setState(() {
        _isEnabled = enabled && 
            _service.permissionStatus == NotificationPermissionStatus.granted;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      // 권한 요청
      final result = await _service.requestPermission();
      if (result == NotificationPermissionStatus.granted) {
        await _service.subscribeToTopic(NotificationTopics.dailyFortune);
        setState(() => _isEnabled = true);
      }
    } else {
      // 알림 비활성화
      await _service.disableNotifications();
      setState(() => _isEnabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const SizedBox.shrink();
    }

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.fortuneGood.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.notifications_active,
          color: AppColors.fortuneGood,
          size: 22,
        ),
      ),
      title: Text(
        '푸시 알림',
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        _isEnabled ? '매일 운세 알림 활성화됨' : '알림을 받지 않음',
        style: AppTypography.caption.copyWith(
          color: AppColors.textTertiaryOf(context),
        ),
      ),
      trailing: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch.adaptive(
              value: _isEnabled,
              onChanged: _toggleNotifications,
              activeThumbColor: AppColors.fortuneGood,
            ),
    );
  }
}
