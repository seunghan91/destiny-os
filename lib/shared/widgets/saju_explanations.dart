import 'package:flutter/material.dart';

/// 사주 요소 설명 모델
class SajuExplanation {
  final String title;
  final String shortDesc;
  final String? detailDesc;
  final IconData icon;
  final Color? accentColor;

  const SajuExplanation({
    required this.title,
    required this.shortDesc,
    this.detailDesc,
    this.icon = Icons.info_outline,
    this.accentColor,
  });
}

/// 사주 요소별 설명 데이터
class SajuExplanations {
  SajuExplanations._();

  // ============================================
  // 사주 기둥 (四柱) 설명
  // ============================================
  static const Map<String, SajuExplanation> pillars = {
    '년주': SajuExplanation(
      title: '년주 (年柱)',
      shortDesc: '조상궁 · 유년기(1~15세) · 사회적 환경',
      detailDesc: '태어난 해의 기운으로, 조상으로부터 물려받은 기질과 어린 시절의 환경을 나타냅니다.',
      icon: Icons.account_tree,
    ),
    '월주': SajuExplanation(
      title: '월주 (月柱)',
      shortDesc: '부모궁 · 청년기(16~30세) · 성장환경',
      detailDesc: '태어난 달의 기운으로, 부모님의 영향과 청년기의 발전 방향을 나타냅니다.',
      icon: Icons.home,
    ),
    '일주': SajuExplanation(
      title: '일주 (日柱)',
      shortDesc: '본인궁 · 중년기(31~45세) · 배우자운',
      detailDesc: '태어난 날의 기운으로, 본인의 핵심 성격과 배우자와의 인연을 나타냅니다. 사주에서 가장 중요한 기둥입니다.',
      icon: Icons.person,
    ),
    '시주': SajuExplanation(
      title: '시주 (時柱)',
      shortDesc: '자녀궁 · 말년기(46세~) · 결실',
      detailDesc: '태어난 시간의 기운으로, 자녀운과 말년의 삶, 인생의 결실을 나타냅니다.',
      icon: Icons.child_care,
    ),
  };

  // ============================================
  // 십신 (十神) 설명
  // ============================================
  static const Map<String, SajuExplanation> tenGods = {
    '비견': SajuExplanation(
      title: '비견 (比肩)',
      shortDesc: '나와 같은 오행 · 형제/친구 · 경쟁자',
      detailDesc: '나와 동등한 기운으로, 자존심이 강하고 독립심이 있습니다. 형제자매, 동료와의 관계를 나타냅니다.',
      icon: Icons.people,
    ),
    '겁재': SajuExplanation(
      title: '겁재 (劫財)',
      shortDesc: '나와 같은 오행(음양 다름) · 경쟁/손재',
      detailDesc: '강한 경쟁 본능과 승부욕을 나타냅니다. 재물의 유출이나 경쟁 관계를 의미하기도 합니다.',
      icon: Icons.flash_on,
    ),
    '식신': SajuExplanation(
      title: '식신 (食神)',
      shortDesc: '내가 생하는 오행 · 재능/식복 · 온화',
      detailDesc: '부드러운 표현력과 예술적 재능을 나타냅니다. 식복이 있고 낙천적인 성향입니다.',
      icon: Icons.restaurant,
    ),
    '상관': SajuExplanation(
      title: '상관 (傷官)',
      shortDesc: '내가 생하는 오행 · 표현력/반항 · 날카로움',
      detailDesc: '뛰어난 언변과 창의력을 나타냅니다. 권위에 도전하고 자유로운 영혼입니다.',
      icon: Icons.mic,
    ),
    '편재': SajuExplanation(
      title: '편재 (偏財)',
      shortDesc: '내가 극하는 오행 · 투자/유동재산 · 아버지',
      detailDesc: '투기성 재물과 사업 수완을 나타냅니다. 아버지와의 인연, 이성관계도 의미합니다.',
      icon: Icons.trending_up,
    ),
    '정재': SajuExplanation(
      title: '정재 (正財)',
      shortDesc: '내가 극하는 오행 · 고정재산/월급 · 아내',
      detailDesc: '안정적인 재물과 근면성을 나타냅니다. 남성에게는 아내, 여성에게는 시어머니를 의미합니다.',
      icon: Icons.account_balance_wallet,
    ),
    '편관': SajuExplanation(
      title: '편관 (偏官)',
      shortDesc: '나를 극하는 오행 · 권력/스트레스 · 칠살',
      detailDesc: '강한 추진력과 결단력을 나타냅니다. 압박감이나 외부 도전을 의미하기도 합니다.',
      icon: Icons.gavel,
    ),
    '정관': SajuExplanation(
      title: '정관 (正官)',
      shortDesc: '나를 극하는 오행 · 명예/직장 · 남편',
      detailDesc: '책임감과 사회적 지위를 나타냅니다. 여성에게는 남편, 모두에게 직장/명예를 의미합니다.',
      icon: Icons.badge,
    ),
    '편인': SajuExplanation(
      title: '편인 (偏印)',
      shortDesc: '나를 생하는 오행 · 학문/편모 · 효신',
      detailDesc: '비정통적인 학문이나 종교, 철학에 관심이 많습니다. 특별한 재능이나 영감을 나타냅니다.',
      icon: Icons.auto_stories,
    ),
    '정인': SajuExplanation(
      title: '정인 (正印)',
      shortDesc: '나를 생하는 오행 · 어머니/문서 · 학업',
      detailDesc: '학문과 지혜를 나타냅니다. 어머니의 사랑, 문서운, 자격증 등을 의미합니다.',
      icon: Icons.school,
    ),
    '일원': SajuExplanation(
      title: '일원 (日元)',
      shortDesc: '일간 본인 · 사주의 주인공 · 나 자신',
      detailDesc: '일주의 천간으로, 사주팔자의 중심입니다. 본인의 본질적인 성격과 기질을 나타냅니다.',
      icon: Icons.stars,
    ),
  };

  // ============================================
  // 십이운성 (十二運星) 설명
  // ============================================
  static const Map<String, SajuExplanation> twelveStates = {
    '장생': SajuExplanation(
      title: '장생 (長生)',
      shortDesc: '탄생 · 시작의 에너지 · 희망',
      detailDesc: '새로운 시작과 성장의 기운입니다. 활력이 넘치고 발전 가능성이 큽니다.',
      icon: Icons.wb_sunny,
    ),
    '목욕': SajuExplanation(
      title: '목욕 (沐浴)',
      shortDesc: '성장통 · 불안정 · 변화',
      detailDesc: '성장 과정의 불안정한 시기입니다. 변화가 많고 감정 기복이 있을 수 있습니다.',
      icon: Icons.water_drop,
    ),
    '관대': SajuExplanation(
      title: '관대 (冠帶)',
      shortDesc: '성인식 · 독립 · 자립',
      detailDesc: '독립과 자립의 시기입니다. 사회에 첫발을 내딛는 젊은 에너지를 나타냅니다.',
      icon: Icons.school,
    ),
    '건록': SajuExplanation(
      title: '건록 (建祿)',
      shortDesc: '전성기 · 활동력 · 녹봉',
      detailDesc: '가장 왕성한 활동력의 시기입니다. 직장운과 재물운이 좋고 실력을 발휘합니다.',
      icon: Icons.workspace_premium,
    ),
    '제왕': SajuExplanation(
      title: '제왕 (帝旺)',
      shortDesc: '정점 · 최고조 · 정상',
      detailDesc: '에너지의 정점입니다. 최고의 상태이나, 정점 이후는 하강만 있음을 의미합니다.',
      icon: Icons.emoji_events,
    ),
    '쇠': SajuExplanation(
      title: '쇠 (衰)',
      shortDesc: '하강 · 안정기 · 성숙',
      detailDesc: '정점을 지나 안정기에 접어든 상태입니다. 원숙함과 경험의 지혜가 있습니다.',
      icon: Icons.trending_down,
    ),
    '병': SajuExplanation(
      title: '병 (病)',
      shortDesc: '약화 · 휴식 필요 · 내면 성찰',
      detailDesc: '에너지가 약해지는 시기입니다. 휴식과 재충전이 필요하며 내면을 돌아보는 때입니다.',
      icon: Icons.healing,
    ),
    '사': SajuExplanation(
      title: '사 (死)',
      shortDesc: '끝 · 정리 · 마무리',
      detailDesc: '한 사이클의 끝을 나타냅니다. 정리와 마무리의 시기이며, 새로운 시작을 준비합니다.',
      icon: Icons.nightlight,
    ),
    '묘': SajuExplanation(
      title: '묘 (墓)',
      shortDesc: '입묘 · 저장 · 축적',
      detailDesc: '에너지를 저장하고 축적하는 시기입니다. 겉으로 드러나지 않는 내면의 힘이 있습니다.',
      icon: Icons.inventory_2,
    ),
    '절': SajuExplanation(
      title: '절 (絶)',
      shortDesc: '단절 · 전환점 · 최저점',
      detailDesc: '에너지의 최저점이자 전환점입니다. 이후로는 다시 상승하는 새로운 사이클이 시작됩니다.',
      icon: Icons.change_circle,
    ),
    '태': SajuExplanation(
      title: '태 (胎)',
      shortDesc: '잉태 · 새 시작 준비 · 가능성',
      detailDesc: '새로운 생명이 잉태되는 시기입니다. 무한한 가능성을 품고 있습니다.',
      icon: Icons.egg,
    ),
    '양': SajuExplanation(
      title: '양 (養)',
      shortDesc: '양육 · 보호 · 성장 준비',
      detailDesc: '보호받으며 자라나는 시기입니다. 아직 독립하지 못했지만 성장을 준비합니다.',
      icon: Icons.spa,
    ),
  };

  // ============================================
  // 오행 (五行) 설명
  // ============================================
  static const Map<String, SajuExplanation> elements = {
    '木': SajuExplanation(
      title: '목 (木) - 나무',
      shortDesc: '성장 · 인자함 · 봄 · 동쪽 · 청색',
      detailDesc: '위로 뻗어나가는 성장의 기운입니다. 인자하고 곧은 성품을 나타냅니다.',
      icon: Icons.park,
    ),
    '나무': SajuExplanation(
      title: '목 (木) - 나무',
      shortDesc: '성장 · 인자함 · 봄 · 동쪽 · 청색',
      detailDesc: '위로 뻗어나가는 성장의 기운입니다. 인자하고 곧은 성품을 나타냅니다.',
      icon: Icons.park,
    ),
    '火': SajuExplanation(
      title: '화 (火) - 불',
      shortDesc: '열정 · 예의 · 여름 · 남쪽 · 적색',
      detailDesc: '타오르는 열정의 기운입니다. 밝고 활발하며 예의를 중시합니다.',
      icon: Icons.local_fire_department,
    ),
    '불': SajuExplanation(
      title: '화 (火) - 불',
      shortDesc: '열정 · 예의 · 여름 · 남쪽 · 적색',
      detailDesc: '타오르는 열정의 기운입니다. 밝고 활발하며 예의를 중시합니다.',
      icon: Icons.local_fire_department,
    ),
    '土': SajuExplanation(
      title: '토 (土) - 흙',
      shortDesc: '중용 · 신의 · 환절기 · 중앙 · 황색',
      detailDesc: '중심을 잡아주는 안정의 기운입니다. 믿음직하고 신뢰를 중시합니다.',
      icon: Icons.landscape,
    ),
    '흙': SajuExplanation(
      title: '토 (土) - 흙',
      shortDesc: '중용 · 신의 · 환절기 · 중앙 · 황색',
      detailDesc: '중심을 잡아주는 안정의 기운입니다. 믿음직하고 신뢰를 중시합니다.',
      icon: Icons.landscape,
    ),
    '金': SajuExplanation(
      title: '금 (金) - 쇠',
      shortDesc: '결단 · 의리 · 가을 · 서쪽 · 백색',
      detailDesc: '단단하고 날카로운 결단의 기운입니다. 의리를 중시하고 원칙적입니다.',
      icon: Icons.diamond,
    ),
    '쇠': SajuExplanation(
      title: '금 (金) - 쇠',
      shortDesc: '결단 · 의리 · 가을 · 서쪽 · 백색',
      detailDesc: '단단하고 날카로운 결단의 기운입니다. 의리를 중시하고 원칙적입니다.',
      icon: Icons.diamond,
    ),
    '水': SajuExplanation(
      title: '수 (水) - 물',
      shortDesc: '지혜 · 유연함 · 겨울 · 북쪽 · 흑색',
      detailDesc: '흐르는 물처럼 유연한 지혜의 기운입니다. 총명하고 적응력이 뛰어납니다.',
      icon: Icons.waves,
    ),
    '물': SajuExplanation(
      title: '수 (水) - 물',
      shortDesc: '지혜 · 유연함 · 겨울 · 북쪽 · 흑색',
      detailDesc: '흐르는 물처럼 유연한 지혜의 기운입니다. 총명하고 적응력이 뛰어납니다.',
      icon: Icons.waves,
    ),
  };

  /// 키로 설명 찾기 (모든 카테고리에서 검색)
  static SajuExplanation? find(String key) {
    return pillars[key] ??
           tenGods[key] ??
           twelveStates[key] ??
           elements[key];
  }
}
