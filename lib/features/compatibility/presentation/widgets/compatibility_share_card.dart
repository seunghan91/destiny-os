import 'package:flutter/material.dart';
import '../../data/services/compatibility_calculator.dart';

/// 공유용 궁합 카드 위젯 (Instagram Stories 9:16 비율 최적화)
///
/// 포함 요소:
/// - 요약 (Summary)
/// - 총점 (Overall Score)
/// - 케미 포인트 Top 3 (Chemistry Points)
/// - 금기사항 Top 2 (Taboos)
class CompatibilityShareCard extends StatelessWidget {
  final CompatibilityResult result;
  final String partnerName;

  const CompatibilityShareCard({
    super.key,
    required this.result,
    required this.partnerName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080, // Instagram Stories width
      height: 1920, // Instagram Stories height
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF9E6), // 따뜻한 아이보리
            Color(0xFFFFE5CC), // 따뜻한 피치
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 헤더: 앱 로고 + 타이틀
              _buildHeader(),

              const SizedBox(height: 60),

              // 메인: 총점 표시
              _buildScoreSection(),

              const SizedBox(height: 80),

              // 요약
              _buildSummarySection(),

              const SizedBox(height: 60),

              // 케미 포인트 Top 3
              _buildChemistrySection(),

              const Spacer(),

              // 금기사항 Top 2
              _buildTaboosSection(),

              const SizedBox(height: 40),

              // 푸터: 앱 정보
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Text(
          '운명의 OS 2026',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D2D2D),
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 12),
        Text(
          '궁합 분석 리포트',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreSection() {
    final scoreColor = _getScoreColor(result.overallScore);
    final scoreLabel = _getScoreLabel(result.overallScore);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            partnerName.isNotEmpty ? '나와 $partnerName님의 궁합' : '우리의 궁합',
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.overallScore}',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 120,
                  fontWeight: FontWeight.w800,
                  color: scoreColor,
                  height: 1.0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 8),
                child: Text(
                  '점',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            scoreLabel,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: scoreColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9066),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '궁합 요약',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            result.insights.summary,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: Color(0xFF444444),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChemistrySection() {
    final topChemistry = result.insights.chemistryPoints.take(3).toList();

    if (topChemistry.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B9D),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '우리의 케미 포인트 ✨',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...topChemistry.asMap().entries.map((entry) {
            final index = entry.key;
            final point = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: index < topChemistry.length - 1 ? 16 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B9D).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF6B9D),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF444444),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTaboosSection() {
    final topTaboos = result.insights.taboos.take(2).toList();

    if (topTaboos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                '⚠️',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(width: 12),
              Text(
                '주의할 점',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF6B6B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...topTaboos.asMap().entries.map((entry) {
            final index = entry.key;
            final taboo = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: index < topTaboos.length - 1 ? 12 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '•',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF6B6B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      taboo,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF444444),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return const Column(
      children: [
        Divider(height: 1, color: Color(0xFFE0E0E0)),
        SizedBox(height: 24),
        Text(
          '더 자세한 분석이 궁금하다면?',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
        SizedBox(height: 8),
        Text(
          '운명의 OS 2026 앱에서 확인하세요',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D2D2D),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) {
      return const Color(0xFFFF6B9D); // 최고 궁합: 핑크
    } else if (score >= 60) {
      return const Color(0xFFFF9066); // 좋은 궁합: 오렌지
    } else if (score >= 40) {
      return const Color(0xFFFFB84D); // 보통 궁합: 옐로우
    } else {
      return const Color(0xFF999999); // 낮은 궁합: 그레이
    }
  }

  String _getScoreLabel(int score) {
    if (score >= 80) {
      return '환상의 궁합 💕';
    } else if (score >= 60) {
      return '좋은 궁합 ✨';
    } else if (score >= 40) {
      return '노력이 필요한 궁합';
    } else {
      return '신중한 접근 필요';
    }
  }
}
