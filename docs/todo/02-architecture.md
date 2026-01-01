# Destiny.OS - 기술 아키텍처

## 시스템 개요

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Widgets   │  │    BLoC     │  │      go_router      │  │
│  │ (Stateless) │  │   (State)   │  │     (Navigation)    │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                       Domain Layer                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Entities   │  │  UseCases   │  │    Repositories     │  │
│  │             │  │             │  │    (Interfaces)     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                        Data Layer                            │
│  ┌─────────────────────────┐  ┌─────────────────────────┐   │
│  │     Local Data Source   │  │   Remote Data Source    │   │
│  │  - Secure Storage       │  │  - Firebase Auth        │   │
│  │  - Hive/SharedPrefs     │  │  - (TBD) Auth Provider  │   │
│  │  - Saju Calculator      │  │  - Serverless Function  │   │
│  └─────────────────────────┘  └─────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Clean Architecture 구조

### 디렉토리 구조

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── router.dart
│
├── core/
│   ├── constants/
│   │   ├── colors.dart          # 토스 컬러 팔레트
│   │   ├── typography.dart      # Pretendard 타이포
│   │   └── saju_constants.dart  # 천간, 지지, 십성 상수
│   ├── utils/
│   │   ├── date_utils.dart
│   │   └── solar_term_calculator.dart
│   ├── errors/
│   │   └── failures.dart
│   └── di/
│       └── injection.dart       # GetIt DI
│
├── features/
│   ├── saju/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── saju_chart.dart
│   │   │   │   ├── pillar.dart
│   │   │   │   └── ten_gods.dart
│   │   │   ├── repositories/
│   │   │   │   └── saju_repository.dart
│   │   │   └── usecases/
│   │   │       ├── calculate_four_pillars.dart
│   │   │       └── analyze_ten_gods.dart
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── saju_chart_model.dart
│   │   │   ├── repositories/
│   │   │   │   └── saju_repository_impl.dart
│   │   │   └── datasources/
│   │   │       ├── lunar_calendar_source.dart
│   │   │       └── solar_term_source.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── saju_bloc.dart
│   │       │   ├── saju_event.dart
│   │       │   └── saju_state.dart
│   │       ├── pages/
│   │       │   ├── input_page.dart
│   │       │   └── result_page.dart
│   │       └── widgets/
│   │           ├── date_wheel_picker.dart
│   │           └── pillar_card.dart
│   │
│   ├── mbti/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── fortune_2026/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── daewoon/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── compatibility/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── ai_consultation/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   └── share/
│       └── presentation/
│
└── shared/
    └── widgets/
        ├── destiny_card.dart
        ├── energy_chart.dart
        └── timeline_view.dart
```

---

## BLoC 패턴 상세

### SajuBloc 예시

```dart
// saju_event.dart
abstract class SajuEvent extends Equatable {
  const SajuEvent();
}

class AnalyzeSaju extends SajuEvent {
  final DateTime birthDate;
  final TimeOfDay? birthTime;
  final bool isLunar;
  final String gender;
  final LatLng? birthLocation;

  const AnalyzeSaju({
    required this.birthDate,
    this.birthTime,
    required this.isLunar,
    required this.gender,
    this.birthLocation,
  });
}

// saju_state.dart
abstract class SajuState extends Equatable {}

class SajuInitial extends SajuState {}
class SajuLoading extends SajuState {}
class SajuSuccess extends SajuState {
  final SajuChart chart;
  final TenGodsAnalysis tenGods;
  const SajuSuccess(this.chart, this.tenGods);
}
class SajuFailure extends SajuState {
  final String message;
  const SajuFailure(this.message);
}

// saju_bloc.dart
class SajuBloc extends Bloc<SajuEvent, SajuState> {
  final CalculateFourPillarsUseCase calculateFourPillars;
  final AnalyzeTenGodsUseCase analyzeTenGods;

  SajuBloc({
    required this.calculateFourPillars,
    required this.analyzeTenGods,
  }) : super(SajuInitial()) {
    on<AnalyzeSaju>(_onAnalyzeSaju);
  }

  Future<void> _onAnalyzeSaju(
    AnalyzeSaju event,
    Emitter<SajuState> emit,
  ) async {
    emit(SajuLoading());

    final chartResult = await calculateFourPillars(
      CalculateFourPillarsParams(
        birthDate: event.birthDate,
        birthTime: event.birthTime,
        isLunar: event.isLunar,
        gender: event.gender,
        birthLocation: event.birthLocation,
      ),
    );

    chartResult.fold(
      (failure) => emit(SajuFailure(failure.message)),
      (chart) async {
        final tenGodsResult = await analyzeTenGods(chart);
        tenGodsResult.fold(
          (failure) => emit(SajuFailure(failure.message)),
          (tenGods) => emit(SajuSuccess(chart, tenGods)),
        );
      },
    );
  }
}
```

---

## 핵심 알고리즘

### 1. 만세력 계산

```dart
class LunarCalendarCalculator {
  /// 양력 → 음력 변환
  LunarDate solarToLunar(DateTime solarDate);

  /// 24절기 계산 (Jean Meeus 알고리즘)
  SolarTerm getSolarTerm(DateTime date);

  /// 월주 계산 (절기 기준)
  Pillar calculateMonthPillar(DateTime date, HeavenlyStem yearStem);

  /// 시주 계산 (진태양시 적용)
  Pillar calculateHourPillar(
    DateTime dateTime,
    HeavenlyStem dayStem,
    double longitude,
  );
}
```

### 2. 경도 보정 (진태양시)

```dart
class TrueSolarTimeCalculator {
  /// 표준시 → 진태양시 변환
  ///
  /// 한국 표준시는 동경 135도 기준
  /// 서울(127.5도)은 약 30분 보정 필요
  DateTime toTrueSolarTime(DateTime localTime, double longitude) {
    const standardMeridian = 135.0;  // 한국 표준시 기준 경도
    final longitudeDiff = longitude - standardMeridian;
    final timeCorrectionMinutes = longitudeDiff * 4;  // 1도 = 4분

    return localTime.add(Duration(
      minutes: timeCorrectionMinutes.round(),
    ));
  }
}
```

### 3. 십성 계산

```dart
class TenGodsCalculator {
  /// 일간 기준 십성 도출
  TenGod calculateTenGod(
    HeavenlyStem dayMaster,
    HeavenlyStem target,
  ) {
    final dayElement = dayMaster.element;
    final targetElement = target.element;
    final isSamePolarity = dayMaster.isYang == target.isYang;

    // 오행 관계에 따른 십성 결정
    if (dayElement == targetElement) {
      return isSamePolarity ? TenGod.companion : TenGod.robWealth;
    }
    if (dayElement.generates == targetElement) {
      return isSamePolarity ? TenGod.eatingGod : TenGod.hurtingOfficer;
    }
    // ... 나머지 관계
  }
}
```

---

## Firebase 연동

### Firestore 구조

```
users/
  {userId}/
    profile:
      createdAt: timestamp
      aiConsultationUsed: bool

    saju_profiles/
      {profileId}/
        name: string
        createdAt: timestamp
        # 기본 권장: 생년월일시 원문 저장 금지(개인정보 최소화)
        # 저장이 필요하면: 파생 피처/요약(또는 암호화된 blob)만 저장 + 명시적 동의
        derivedSummary: map?

    consultations/
      {consultationId}/
        type: string
        question: string
        answer: string
        createdAt: timestamp
```

### Firebase Auth

```dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 익명 로그인 (토스 미니앱)
  Future<UserCredential> signInAnonymously();

  // 소셜 로그인 (독립 앱)
  Future<UserCredential> signInWithGoogle();
  Future<UserCredential> signInWithApple();
  Future<UserCredential> signInWithKakao();
}
```

---

## OpenAI API 연동

### AI 상담 서비스

```dart
class AIConsultationService {
  // OpenAI 키/레이트리밋/1회권 차감/남용 방지를 위해
  // 클라이언트에서 직접 OpenAI를 호출하지 않습니다.
  final Dio _dio;

  Future<String> consult({
    required String userId,
    required Map<String, dynamic> derivedSajuSummary, // 생년월일시 원문 대신 파생 데이터 권장
    required String mbti,
    required String fortuneSummary,
    required ConsultationType type,
    required String userQuestion,
  }) async {
    final response = await _dio.post(
      '/api/ai/consult',
      data: {
        'userId': userId,
        'derivedSajuSummary': derivedSajuSummary,
        'mbti': mbti,
        'fortuneSummary': fortuneSummary,
        'type': type.name,
        'userQuestion': userQuestion,
      },
    );

    return response.data['answer'] as String;
  }
}
```

---

## 의존성 패키지

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^8.1.0
  equatable: ^2.0.0

  # Dependency Injection
  get_it: ^7.6.0
  injectable: ^2.1.0

  # Navigation
  go_router: ^12.0.0

  # Firebase
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  cloud_firestore: ^4.13.0

  # Local Storage
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^9.0.0

  # Network
  dio: ^5.3.0

  # Utilities
  dartz: ^0.10.1  # Functional programming
  intl: ^0.18.0   # Date formatting

  # UI
  fl_chart: ^0.65.0      # Charts
  shimmer: ^3.0.0        # Loading
  share_plus: ^7.2.0     # Sharing

  # Lunar Calendar
  lunar: ^1.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.0
  mocktail: ^1.0.0
  injectable_generator: ^2.1.0
  build_runner: ^2.4.0
```

---

## 토스 미니앱 연동

### SDK 설정 (예상)

```dart
class TossMiniAppBridge {
  /// 토스 사용자 정보 조회
  Future<TossUser?> getTossUser();

  /// 토스 결제 연동
  Future<PaymentResult> requestPayment({
    required String productId,
    required int amount,
  });

  /// 딥링크 처리
  void handleDeepLink(String deepLink);
}
```

### 독립 앱과의 코드 공유

```dart
// platform_service.dart
abstract class PlatformService {
  Future<User?> getUser();
  Future<PaymentResult> pay(PaymentRequest request);
}

// toss_mini_app_service.dart
class TossMiniAppService implements PlatformService {
  // 토스 미니앱 SDK 사용
}

// standalone_app_service.dart
class StandaloneAppService implements PlatformService {
  // Firebase + 자체 결제 연동
}
```

---

## 테스트 전략

### Unit Tests
- 만세력 계산 정확성
- 십성 계산 로직
- MBTI 매핑 로직

### Widget Tests
- 날짜 선택 위젯
- 결과 카드 렌더링

### Integration Tests
- 전체 사주 분석 플로우
- AI 상담 플로우

### Golden Tests
- 결과 카드 UI 스냅샷
