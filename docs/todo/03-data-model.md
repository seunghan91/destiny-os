# Destiny.OS - 데이터 모델

## 핵심 엔티티

### 1. 사주 관련

#### HeavenlyStem (천간)

```dart
enum HeavenlyStem {
  gap(name: '갑', hanja: '甲', element: Element.wood, isYang: true),
  eul(name: '을', hanja: '乙', element: Element.wood, isYang: false),
  byeong(name: '병', hanja: '丙', element: Element.fire, isYang: true),
  jeong(name: '정', hanja: '丁', element: Element.fire, isYang: false),
  mu(name: '무', hanja: '戊', element: Element.earth, isYang: true),
  gi(name: '기', hanja: '己', element: Element.earth, isYang: false),
  gyeong(name: '경', hanja: '庚', element: Element.metal, isYang: true),
  sin(name: '신', hanja: '辛', element: Element.metal, isYang: false),
  im(name: '임', hanja: '壬', element: Element.water, isYang: true),
  gye(name: '계', hanja: '癸', element: Element.water, isYang: false);

  final String name;
  final String hanja;
  final Element element;
  final bool isYang;
}
```

#### EarthlyBranch (지지)

```dart
enum EarthlyBranch {
  ja(name: '자', hanja: '子', animal: '쥐', element: Element.water,
     season: Season.winter, hours: [23, 0, 1]),
  chuk(name: '축', hanja: '丑', animal: '소', element: Element.earth,
       season: Season.winter, hours: [1, 2, 3]),
  in_(name: '인', hanja: '寅', animal: '호랑이', element: Element.wood,
      season: Season.spring, hours: [3, 4, 5]),
  myo(name: '묘', hanja: '卯', animal: '토끼', element: Element.wood,
      season: Season.spring, hours: [5, 6, 7]),
  jin(name: '진', hanja: '辰', animal: '용', element: Element.earth,
      season: Season.spring, hours: [7, 8, 9]),
  sa(name: '사', hanja: '巳', animal: '뱀', element: Element.fire,
     season: Season.summer, hours: [9, 10, 11]),
  o(name: '오', hanja: '午', animal: '말', element: Element.fire,
    season: Season.summer, hours: [11, 12, 13]),
  mi(name: '미', hanja: '未', animal: '양', element: Element.earth,
     season: Season.summer, hours: [13, 14, 15]),
  sin(name: '신', hanja: '申', animal: '원숭이', element: Element.metal,
      season: Season.autumn, hours: [15, 16, 17]),
  yu(name: '유', hanja: '酉', animal: '닭', element: Element.metal,
     season: Season.autumn, hours: [17, 18, 19]),
  sul(name: '술', hanja: '戌', animal: '개', element: Element.earth,
      season: Season.autumn, hours: [19, 20, 21]),
  hae(name: '해', hanja: '亥', animal: '돼지', element: Element.water,
      season: Season.winter, hours: [21, 22, 23]);
}
```

#### Pillar (주)

```dart
class Pillar extends Equatable {
  final HeavenlyStem stem;
  final EarthlyBranch branch;

  const Pillar({
    required this.stem,
    required this.branch,
  });

  /// 60갑자 인덱스 (0-59)
  int get sexagenaryIndex {
    // ⚠️ 주의: (stemIndex * 12 + branchIndex) % 60 같은 단순 공식은
    // 실제 60갑자 순환(간지 조합 규칙)을 정확히 반영하지 못할 수 있습니다.
    // 구현에서는 "표준 60갑자 테이블" 또는 검증된 라이브러리/테이블 기반 매핑을 사용하세요.
    throw UnimplementedError('Use canonical sexagenary cycle mapping table.');
  }

  /// 간지 문자열 (예: "甲子")
  String get ganji => '${stem.hanja}${branch.hanja}';

  /// 한글 간지 (예: "갑자")
  String get ganjiKorean => '${stem.name}${branch.name}';
}
```

#### SajuChart (사주팔자)

```dart
class SajuChart extends Equatable {
  final Pillar yearPillar;   // 년주
  final Pillar monthPillar;  // 월주
  final Pillar dayPillar;    // 일주 (핵심)
  final Pillar? hourPillar;  // 시주 (선택)

  final DateTime birthDate;
  // Domain 모델에서는 Flutter 타입(TimeOfDay)을 직접 사용하지 않는 것을 권장합니다.
  // 실제 구현 시에는 Value Object(예: LocalTime) 또는 "HH:mm" 문자열을 사용하세요.
  final String? birthTime; // "HH:mm"
  final String gender;  // 'male' | 'female'
  final bool isLunar;
  final double? longitude;  // 경도 (진태양시 계산용)

  const SajuChart({
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    this.hourPillar,
    required this.birthDate,
    this.birthTime,
    required this.gender,
    required this.isLunar,
    this.longitude,
  });

  /// 일간 (Day Master) - 사주의 핵심
  HeavenlyStem get dayMaster => dayPillar.stem;

  /// 일간의 오행
  Element get dayMasterElement => dayMaster.element;

  /// 시주 유무
  bool get hasHourPillar => hourPillar != null;
}
```

---

### 2. 십성 관련

#### TenGod (십성)

```dart
enum TenGod {
  // 비겁 (같은 오행)
  companion(name: '비견', hanja: '比肩', category: TenGodCategory.peer),
  robWealth(name: '겁재', hanja: '劫財', category: TenGodCategory.peer),

  // 식상 (내가 생하는 오행)
  eatingGod(name: '식신', hanja: '食神', category: TenGodCategory.output),
  hurtingOfficer(name: '상관', hanja: '傷官', category: TenGodCategory.output),

  // 재성 (내가 극하는 오행)
  indirectWealth(name: '편재', hanja: '偏財', category: TenGodCategory.wealth),
  directWealth(name: '정재', hanja: '正財', category: TenGodCategory.wealth),

  // 관성 (나를 극하는 오행)
  sevenKillings(name: '편관', hanja: '偏官', category: TenGodCategory.authority),
  directOfficer(name: '정관', hanja: '正官', category: TenGodCategory.authority),

  // 인성 (나를 생하는 오행)
  indirectResource(name: '편인', hanja: '偏印', category: TenGodCategory.resource),
  directResource(name: '정인', hanja: '正印', category: TenGodCategory.resource);
}

enum TenGodCategory {
  peer,       // 비겁
  output,     // 식상
  wealth,     // 재성
  authority,  // 관성
  resource,   // 인성
}
```

#### TenGodsAnalysis (십성 분석 결과)

```dart
class TenGodsAnalysis extends Equatable {
  /// 각 위치별 십성
  final TenGod yearStemGod;
  final TenGod yearBranchGod;
  final TenGod monthStemGod;
  final TenGod monthBranchGod;
  final TenGod dayBranchGod;  // 일간은 자신이므로 제외
  final TenGod? hourStemGod;
  final TenGod? hourBranchGod;

  /// 십성 개수 통계
  final Map<TenGod, int> godCounts;

  /// 카테고리별 강도
  final Map<TenGodCategory, double> categoryStrengths;

  /// 용신 (가장 필요한 오행)
  final Element? yongShin;

  /// 기신 (가장 피해야 할 오행)
  final Element? giShin;
}
```

---

### 3. MBTI 관련

#### MbtiType

```dart
enum MbtiType {
  INTJ, INTP, ENTJ, ENTP,
  INFJ, INFP, ENFJ, ENFP,
  ISTJ, ISFJ, ESTJ, ESFJ,
  ISTP, ISFP, ESTP, ESFP;

  bool get isExtrovert => name.startsWith('E');
  bool get isIntrovert => name.startsWith('I');
  bool get isIntuitive => name[1] == 'N';
  bool get isSensing => name[1] == 'S';
  bool get isThinking => name[2] == 'T';
  bool get isFeeling => name[2] == 'F';
  bool get isJudging => name[3] == 'J';
  bool get isPerceiving => name[3] == 'P';
}
```

#### GapAnalysisResult (괴리 분석)

```dart
class GapAnalysisResult extends Equatable {
  /// 사주 기반 추정 MBTI
  final MbtiType inferredMbti;

  /// 사용자 입력 MBTI
  final MbtiType actualMbti;

  /// 괴리 점수 (0-100, 높을수록 큰 차이)
  final int gapScore;

  /// 각 지표별 괴리
  final Map<String, double> dimensionGaps; // E/I, S/N, T/F, J/P

  /// 인사이트 텍스트
  final String insight;

  /// 숨겨진 잠재력
  final String hiddenPotential;
}
```

---

### 4. 운세 관련

#### Fortune2026 (2026년 운세)

```dart
class Fortune2026 extends Equatable {
  /// 연간 총운 점수 (0-100)
  final int overallScore;

  /// 2026년(병오년)과의 관계
  final YearRelation yearRelation;

  /// 분야별 운세
  final FortuneCategory categoryFortunes;

  /// 월별 에너지 차트 데이터
  final List<MonthlyEnergy> monthlyEnergies;

  /// 핵심 메시지
  final String keyMessage;

  /// 행운의 색
  final Color luckyColor;

  /// 행운의 숫자
  final List<int> luckyNumbers;

  /// 주의 시기
  final List<String> cautionPeriods;
}

class MonthlyEnergy extends Equatable {
  final int month;
  final int energyLevel;  // 0-100
  final String monthBranch;  // 지지
  final String description;
  final List<String> keywords;
}
```

#### Daewoon (대운)

```dart
class Daewoon extends Equatable {
  /// 대운 시작 나이
  final int startAge;

  /// 대운 간지
  final Pillar pillar;

  /// 대운 십성
  final TenGod stemGod;
  final TenGod branchGod;

  /// 대운 테마 키워드
  final String theme;

  /// 대운 설명
  final String description;

  /// 이 대운의 강도 (길함/흉함)
  final double strength;  // -1.0 ~ 1.0
}

class DaewoonTimeline extends Equatable {
  /// 모든 대운 리스트
  final List<Daewoon> daewoons;

  /// 현재 대운 인덱스
  final int currentIndex;

  /// 다음 대운까지 남은 년수
  final int yearsToNext;

  Daewoon get currentDaewoon => daewoons[currentIndex];
  Daewoon? get nextDaewoon =>
      currentIndex + 1 < daewoons.length ? daewoons[currentIndex + 1] : null;
}
```

---

### 5. 궁합 관련

#### CompatibilityResult (궁합 결과)

```dart
class CompatibilityResult extends Equatable {
  /// 총 궁합 점수 (0-100)
  final int totalScore;

  /// 관계 유형 별명
  final String relationshipNickname;  // "브레이크 없는 스포츠카" 등

  /// 일주 궁합
  final DayPillarCompatibility dayPillarCompat;

  /// 오행 균형
  final ElementBalance elementBalance;

  /// MBTI 궁합 (있는 경우)
  final MbtiCompatibility? mbtiCompat;

  /// 강점 리스트
  final List<String> strengths;

  /// 주의점 리스트
  final List<String> cautions;

  /// 조언
  final List<String> recommendations;
}

class DayPillarCompatibility extends Equatable {
  /// 합(合) 관계
  final List<String> combinations;

  /// 충(沖) 관계
  final List<String> clashes;

  /// 형(刑) 관계
  final List<String> punishments;

  /// 종합 점수
  final int score;
}
```

---

### 6. AI 상담 관련

#### Consultation (상담 기록)

```dart
class Consultation extends Equatable {
  final String id;
  final String userId;
  final ConsultationType type;
  final String question;
  final String answer;
  final DateTime createdAt;
  final SajuChart? sajuContext;
  final MbtiType? mbtiContext;
}

enum ConsultationType {
  career(name: '직업/진로'),
  relationship(name: '연애/결혼'),
  finance(name: '재물/투자'),
  health(name: '건강/웰빙'),
  general(name: '종합');

  final String name;
}
```

---

### 7. 사용자 관련

#### UserProfile (사용자 프로필)

```dart
class UserProfile extends Equatable {
  final String id;
  final String? displayName;
  final AuthProvider authProvider;
  final DateTime createdAt;
  final bool aiConsultationUsed;
  final SubscriptionTier subscriptionTier;
}

enum AuthProvider {
  anonymous,
  google,
  apple,
  kakao,
  toss,
}

enum SubscriptionTier {
  free,
  premium,
}
```

#### SajuProfile (저장된 사주 프로필)

```dart
class SajuProfile extends Equatable {
  final String id;
  final String userId;
  final String name;  // "나", "엄마", "남자친구" 등
  final DateTime birthDate;
  final String? birthTime; // "HH:mm"
  final String gender;
  final MbtiType? mbti;
  final SajuChart? cachedChart;
  final DateTime createdAt;
}
```

---

## Firestore 스키마

```
/users/{userId}
  - displayName: string?
  - authProvider: string
  - createdAt: timestamp
  - aiConsultationUsed: bool
  - subscriptionTier: string

/users/{userId}/saju_profiles/{profileId}
  - name: string
  - birthDate: timestamp
  - birthTime: string?  // "HH:mm" 형식
  - gender: string
  - mbti: string?
  - createdAt: timestamp

/users/{userId}/consultations/{consultationId}
  - type: string
  - question: string
  - answer: string
  - profileId: string?
  - createdAt: timestamp
```

---

## 로컬 저장소 스키마 (Hive)

```dart
// boxes
@HiveType(typeId: 0)
class LocalSajuProfile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime birthDate;

  @HiveField(3)
  String? birthTime;

  @HiveField(4)
  String gender;

  @HiveField(5)
  String? mbti;

  @HiveField(6)
  String? cachedChartJson;
}

// 설정
@HiveType(typeId: 1)
class LocalSettings extends HiveObject {
  @HiveField(0)
  bool useYajaTime;  // 야자시 적용 여부

  @HiveField(1)
  bool darkMode;

  @HiveField(2)
  String locale;
}
```
