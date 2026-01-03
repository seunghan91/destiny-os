import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../../../core/services/auth/auth_manager.dart';
import '../../data/models/dating_profile.dart';
import '../../data/services/dating_service.dart';

/// MBTI 소개팅 오늘의 추천 페이지
class DatingRecommendationsPage extends StatefulWidget {
  const DatingRecommendationsPage({super.key});

  @override
  State<DatingRecommendationsPage> createState() =>
      _DatingRecommendationsPageState();
}

class _DatingRecommendationsPageState extends State<DatingRecommendationsPage> {
  bool _isLoading = true;
  bool _hasProfile = false;
  List<RecommendedProfile> _recommendations = [];
  int _currentIndex = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 프로필 존재 여부 확인
      _hasProfile = await DatingService.hasProfile();

      if (_hasProfile) {
        // 오늘의 추천 로드
        _recommendations = await DatingService.getTodayRecommendations();
      }
    } catch (e) {
      _errorMessage = '데이터를 불러오는 중 오류가 발생했습니다: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAction(String action) async {
    if (_currentIndex >= _recommendations.length) return;

    final target = _recommendations[_currentIndex];
    HapticFeedback.mediumImpact();

    final success = await DatingService.recordAction(
      targetUserId: target.recommendedUserId,
      action: action,
    );

    if (success && mounted) {
      if (action == 'like') {
        // 좋아요 애니메이션/피드백
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('💕 좋아요를 보냈습니다!'),
            backgroundColor: AppColors.primaryOf(context),
            duration: const Duration(seconds: 1),
          ),
        );
      }

      setState(() {
        _currentIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: const Text('MBTI 소개팅'),
        backgroundColor: AppColors.surfaceOf(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/dating/onboarding'),
            tooltip: '프로필 수정',
          ),
          IconButton(
            icon: const Icon(Icons.favorite_outline),
            onPressed: () => _showMatches(),
            tooltip: '매치 목록',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !AuthManager().isAuthenticated
          ? _buildLoginRequired()
          : !_hasProfile
          ? _buildProfileRequired()
          : _errorMessage != null
          ? _buildError()
          : _recommendations.isEmpty
          ? _buildNoRecommendations()
          : _currentIndex >= _recommendations.length
          ? _buildAllDone()
          : _buildRecommendationCard(),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💕', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            Text(
              '로그인이 필요합니다',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'MBTI 소개팅을 이용하려면\n먼저 로그인해주세요',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryOf(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.push('/settings'),
              child: const Text('로그인하러 가기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📝', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            Text(
              '프로필을 작성해주세요',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '매칭을 위해 간단한 프로필 정보가 필요해요',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryOf(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.push('/dating/onboarding'),
              child: const Text('프로필 작성하기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😢', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            Text(
              '오류가 발생했습니다',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryOf(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _loadData, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRecommendations() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            Text(
              '추천할 사람이 없습니다',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '조건에 맞는 사용자가 아직 없어요.\n내일 다시 확인해보세요!',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryOf(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => context.push('/dating/onboarding'),
              child: const Text('선호도 조건 변경하기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllDone() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✨', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            Text(
              '오늘의 추천 완료!',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '오늘 추천된 ${_recommendations.length}명을 모두 확인했어요.\n내일 새로운 추천을 받아보세요!',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryOf(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _showMatches(),
              child: const Text('매치 확인하기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard() {
    final profile = _recommendations[_currentIndex];
    final primary = AppColors.primaryOf(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 진행 상황
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '오늘의 추천 ${_currentIndex + 1} / ${_recommendations.length}',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 프로필 카드
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 프로필 이미지 플레이스홀더
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: primary.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        profile.mbti[0],
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // MBTI 뱃지
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      profile.mbti,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 나이 & 직업
                  Text(
                    '${profile.age}세${profile.job != null ? ' · ${profile.job}' : ''}',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 관심사 태그
                  if (profile.keywords.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: profile.keywords.take(5).map((keyword) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundOf(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.borderOf(context),
                            ),
                          ),
                          child: Text(
                            keyword,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 자기소개
                  if (profile.bio != null && profile.bio!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundOf(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        profile.bio!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondaryOf(context),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 액션 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 패스 버튼
              _ActionButton(
                icon: Icons.close_rounded,
                label: '패스',
                color: AppColors.grey500Of(context),
                onPressed: () => _handleAction('pass'),
              ),

              // 좋아요 버튼
              _ActionButton(
                icon: Icons.favorite_rounded,
                label: '좋아요',
                color: Colors.pink,
                isPrimary: true,
                onPressed: () => _handleAction('like'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showMatches() async {
    final matches = await DatingService.getMatches();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('💕', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      '매치 목록',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (matches.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        '아직 매치가 없습니다.\n좋아요를 보내보세요!',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondaryOf(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: matches.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryOf(
                            context,
                          ).withAlpha(25),
                          child: const Icon(Icons.person),
                        ),
                        title: Text(
                          '매치 #${index + 1}',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${match.createdAt.toLocal()}'.split('.').first,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      );
                    },
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.isPrimary = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isPrimary ? 72 : 64,
            height: isPrimary ? 72 : 64,
            decoration: BoxDecoration(
              color: isPrimary ? color : color.withAlpha(25),
              shape: BoxShape.circle,
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: color.withAlpha(77),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: isPrimary ? 36 : 28,
              color: isPrimary ? Colors.white : color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
