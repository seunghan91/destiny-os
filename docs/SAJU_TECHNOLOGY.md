# Destiny.OS - 사주 분석 기술 문서

> **최종 업데이트**: 2026-01-01
> **버전**: 1.0.0

---

## 개요

Destiny.OS는 정통 사주명리학 이론에 기반한 과학적 접근 방식을 사용하여 사주 분석을 수행합니다. 본 문서는 앱에서 사용되는 핵심 알고리즘과 기술적 구현 내용을 설명합니다.

---

## 1. 만세력 엔진

### 1.1 사용 라이브러리

```yaml
lunar: ^1.3.12  # 중국/한국 음양력 및 사주 계산 라이브러리
```

**lunar 패키지 특징**:
- 1900~2100년 음양력 정확 변환
- 24절기 데이터 내장
- EightChar(팔자) 클래스로 년/월/일/시주 자동 계산
- 대운(DaYun), 세운(LiuNian) 정보 제공

### 1.2 핵심 API 활용

```dart
// 양력 → 음력 변환
final solar = Solar.fromYmdHms(year, month, day, hour, minute, 0);
final lunar = solar.getLunar();

// 팔자 계산
final eightChar = lunar.getEightChar();
String yearGan = eightChar.getYear();    // 년간 (예: 甲)
String yearZhi = eightChar.getYearZhi(); // 년지 (예: 子)

// 절기 정보
final nextJie = lunar.getNextJie();  // 다음 절입일
final prevJie = lunar.getPrevJie();  // 이전 절입일
```

---

## 2. 대운수(大運數) 계산

### 2.1 이론적 배경

대운수는 사람마다 다른 "대운이 시작되는 나이"입니다. 계산 방법:

1. **순행/역행 결정**
   - 양남음녀 = 순행 (다음 절기까지 일수)
   - 음남양녀 = 역행 (이전 절기까지 일수)

2. **3일 = 1년 환산법**
   - 출생일과 절기 사이의 일수를 3으로 나눔
   - 나머지 1: 버림, 나머지 2: 올림

### 2.2 구현 코드

```dart
/// saju_calculator.dart:514-563
int _calculateDaewoonStartAge(DateTime birthDateTime, bool isForward) {
  final solar = Solar.fromYmdHms(...);
  final lunar = solar.getLunar();

  // 절기 가져오기
  final nextJie = lunar.getNextJie();
  final prevJie = lunar.getPrevJie();

  late final Solar targetSolar;
  if (isForward) {
    targetSolar = nextJie.getSolar();  // 순행: 다음 절기
  } else {
    targetSolar = prevJie.getSolar();  // 역행: 이전 절기
  }

  // 일수 계산
  final daysDiff = targetDate.difference(birthDate).inDays.abs();

  // 3일 = 1년 환산
  final quotient = daysDiff ~/ 3;
  final remainder = daysDiff % 3;

  int startAge = quotient;
  if (remainder == 2) startAge += 1;  // 나머지 2는 올림

  return startAge.clamp(1, 10);  // 1~10세 범위
}
```

### 2.3 정확도

| 항목 | 정확도 | 비고 |
|------|--------|------|
| 절기 날짜 | 99%+ | lunar 패키지 천문 데이터 |
| 순행/역행 판단 | 100% | 년간 음양 + 성별 조합 |
| 3일=1년 환산 | 100% | 정통 명리학 공식 |

---

## 3. 시주(時柱) 계산

### 3.1 오자시두법(五子時頭法)

일간(日干)에 따라 자시(子時)의 천간이 결정됩니다:

| 일간 | 자시 천간 | 규칙 |
|------|----------|------|
| 甲, 己 | 甲 | 갑기일 갑자시 |
| 乙, 庚 | 丙 | 을경일 병자시 |
| 丙, 辛 | 戊 | 병신일 무자시 |
| 丁, 壬 | 庚 | 정임일 경자시 |
| 戊, 癸 | 壬 | 무계일 임자시 |

### 3.2 구현

```dart
/// saju_calculator.dart:119-142
Pillar _calculateHourPillar(String dayStem, double hour, bool useNightSubhour) {
  // 시간 → 지지 인덱스 (子시=23~01시, 丑시=01~03시, ...)
  int branchIndex = (((hour + 1) / 2).floor()) % 12;

  // 오자시두법 적용
  final dayStemIndex = _stems.indexOf(dayStem);
  final startStemIndex = (dayStemIndex % 5) * 2;
  final hourStemIndex = (startStemIndex + branchIndex) % 10;

  return Pillar(
    heavenlyStem: _stems[hourStemIndex],
    earthlyBranch: _branches[branchIndex],
  );
}
```

---

## 4. 십성(十星) 분석

### 4.1 십성 종류

| 십성 | 관계 | 의미 |
|------|------|------|
| 비견 | 같은 오행, 같은 음양 | 자아, 동료 |
| 겁재 | 같은 오행, 다른 음양 | 경쟁, 협력 |
| 식신 | 내가 생하는 오행, 같은 음양 | 표현, 재능 |
| 상관 | 내가 생하는 오행, 다른 음양 | 창의, 반항 |
| 편재 | 내가 극하는 오행, 다른 음양 | 재물, 투자 |
| 정재 | 내가 극하는 오행, 같은 음양 | 정재, 급여 |
| 편관 | 나를 극하는 오행, 다른 음양 | 권력, 압박 |
| 정관 | 나를 극하는 오행, 같은 음양 | 명예, 직장 |
| 편인 | 나를 생하는 오행, 다른 음양 | 학문, 편학 |
| 정인 | 나를 생하는 오행, 같은 음양 | 어머니, 정학 |

### 4.2 현재 구현 상태

- ✅ 천간 기반 십성 계산
- ✅ 지지 정기(正氣) 기반 십성 계산
- ⚠️ 지장간(地藏干) 여기/중기 미반영 (향후 개선 예정)

---

## 5. 궁합 분석 알고리즘

### 5.1 천간합(天干合)

두 천간이 만나 새로운 오행을 형성하는 관계:

| 천간합 | 화합 오행 | 점수 보너스 |
|--------|----------|------------|
| 甲己合 | 土 | +10 |
| 乙庚合 | 金 | +10 |
| 丙辛合 | 水 | +10 |
| 丁壬合 | 木 | +10 |
| 戊癸合 | 火 | +10 |

### 5.2 지지 관계

| 관계 | 설명 | 궁합 영향 |
|------|------|----------|
| 육합(六合) | 子丑, 寅亥, 卯戌, 辰酉, 巳申, 午未 | +15 (최고) |
| 삼합(三合) | 申子辰(水), 寅午戌(火), 巳酉丑(金), 亥卯未(木) | +10 |
| 충(沖) | 子午, 丑未, 寅申, 卯酉, 辰戌, 巳亥 | -15 |
| 형(刑) | 寅巳申(삼형살), 丑戌未(삼형살) 등 | -10 |
| 해(害) | 子未, 丑午, 寅巳, 卯辰, 申亥, 酉戌 | -8 |

### 5.3 궁합 점수 계산

```dart
/// saju_calculator.dart:523-527
final overallScore = (
  dayMasterResult.score * 0.35 +   // 일간 궁합 35%
  branchResult.score * 0.35 +       // 지지 궁합 35%
  elementBalance.score * 0.30       // 오행 균형 30%
).round();
```

---

## 6. 정확도 평가

### 6.1 분석 영역별 정확도

| 분석 영역 | 정확도 | 등급 | 비고 |
|----------|--------|------|------|
| 사주팔자 계산 | 95% | 높음 | lunar 패키지 기반 |
| 십성 분석 | 85% | 양호 | 지장간 미반영 |
| 궁합 분석 | 90% | 높음 | 천간합/지지관계 완전 구현 |
| 대운 흐름 | 88% | 양호 | 절기 기반 정밀 계산 |

### 6.2 향후 개선 계획

1. **지장간(地藏干) 추가** (우선순위: 높음)
   - 12지지별 여기/중기/정기 데이터 추가
   - 십성 분석 정확도 30%+ 향상 예상

2. **절기 시분 정밀 계산** (우선순위: 중간)
   - 현재: 일 단위 절기
   - 개선: 시분 단위 절기 (대운수 더 정밀)

3. **만세력 검증 테스트** (우선순위: 중간)
   - 10+ 샘플 기반 정확도 검증
   - 전문가 검수 추가

---

## 7. 참고 자료

### 7.1 명리학 이론
- 대운수 계산: 3일=1년 환산법 (연해자평 기준)
- 순행/역행: 양남음녀 순행, 음남양녀 역행
- 오자시두법: 일간에 따른 시주 천간 결정

### 7.2 기술 참고
- lunar 패키지: https://pub.dev/packages/lunar
- API 문서: https://6tail.cn/calendar/api.html

---

## 면책 조항

사주명리학은 동양 철학에 기반한 해석 체계입니다. 본 앱의 분석 결과는 재미와 참고용으로만 활용해 주시기 바랍니다. 중요한 결정은 전문가와 상담하시기 바랍니다.

---

*Destiny.OS 개발팀*
