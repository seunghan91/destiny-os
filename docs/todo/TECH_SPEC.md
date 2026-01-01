# Destiny.OS - 기술 사양서 (Tech Spec)

## 1. 아키텍처 개요
- **Frontend:** Flutter (Mobile App)
- **Backend:** Serverless Architecture (Supabase)
- **AI Engine:** External LLM API (OpenAI GPT-4o or Claude 3.5 Sonnet)

## 2. 프론트엔드 (Flutter)

### 2.1 상태 관리
- **BLoC (flutter_bloc):** 이벤트 기반 상태 관리
- **Equatable:** 상태 비교 최적화
- 결정 근거: `06-decisions.md`에서 BLoC + Clean Architecture 확정

### 2.2 의존성 주입
- **GetIt + Injectable:** 컴파일 타임 DI 생성
- 싱글톤, 팩토리, 레이지 싱글톤 지원

### 2.3 라우팅
- **GoRouter:** 딥링킹 및 복잡한 네비게이션 처리
- 선언적 라우팅, 리다이렉트, 가드 지원

### 2.4 UI/UX
- 토스 디자인 시스템 준수
- Pretendard 폰트
- 오방색 파스텔 톤 재해석
- Material 3 기반 커스텀 테마

## 3. 백엔드 (Supabase)

> **선택 근거:**
> - 사주 데이터는 관계형 구조 (사주차트 → 십성 → MBTI 매핑)
> - SQL 복잡 쿼리 필요 (대운 계산, 궁합 분석, JOIN)
> - 비용 예측 가능 (storage 기반 과금, Firebase는 read/write 기반)
> - 오픈소스, self-host 가능, 벤더 종속 없음
> - Row Level Security(RLS) 우수

### 3.1 Database (PostgreSQL)

```sql
-- 테이블 구조 예시
users (
  id UUID PRIMARY KEY,
  created_at TIMESTAMP,
  mbti VARCHAR(4),
  ai_consultation_used BOOLEAN DEFAULT FALSE
)

saju_profiles (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  name VARCHAR(50),
  -- 생년월일시 원문 저장 안함 (개인정보 보호)
  derived_summary JSONB,  -- 파생 데이터만 저장
  created_at TIMESTAMP
)

consultations (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  type VARCHAR(20),
  question TEXT,
  answer TEXT,
  created_at TIMESTAMP
)
```

### 3.2 Authentication
- Supabase Auth (Email, Social Login - Kakao/Google/Apple)
- 익명 로그인 지원 (토스 미니앱 대비)

### 3.3 Edge Functions (Deno)
- **AI 상담 함수:** `/ai/consult`
  - API Key 보호 (클라이언트 노출 금지)
  - 1회권 차감/검증
  - Rate limiting (남용 방지)
- **만세력 계산 함수:** (선택사항, 클라이언트 부담 경감 시)

## 4. AI 통합

### 4.1 상담 흐름
```
[사용자]
  └─> 사주/MBTI 분석 완료
       └─> "추가 질의" 버튼 클릭
            └─> AI 상담 (1회 무료)
                 └─> Edge Function 호출
                      └─> LLM API (GPT-4o / Claude)
```

### 4.2 데이터 정책 (개인정보 보호)
- LLM에 **생년월일시 원문 전송 금지**
- 파생 피처만 전송:
  - 십성 통계 (비겁 30%, 식상 20% 등)
  - 오행 균형 (화 과다, 수 부족 등)
  - 대운 정보
  - Gap 분석 결과

### 4.3 프롬프트 구조
```
[시스템]
당신은 사주명리학과 MBTI 전문 상담사입니다.

[컨텍스트]
- 일간: 甲木 (양목)
- 십성 분포: 비겁 25%, 식상 30%, 재성 15%, 관성 20%, 인성 10%
- 오행: 목 과다, 금 부족
- MBTI: ENFP (사용자 입력)
- 추론 MBTI: ENTP (사주 기반)
- Gap Score: 35%
- 2026년 용신: 화(火) → 유리
- 상담 유형: {career|relationship|finance|health|general}

[사용자 질문]
{user_question}
```

## 5. 분석 옵션 (체크박스)

### 5.1 분석 모드 선택
```dart
enum AnalysisMode {
  sajuOnly,      // 사주만 분석
  mbtiOnly,      // MBTI만 분석 (간단 성격 테스트)
  hybrid,        // 사주 + MBTI 통합 분석 (권장)
}
```

### 5.2 UI 구현
```
┌─────────────────────────────────────┐
│  분석 옵션 선택                      │
├─────────────────────────────────────┤
│  ☑ 사주 분석                        │
│    └ 생년월일시 기반 운명 분석       │
│                                     │
│  ☑ MBTI 분석                        │
│    └ 현재 성격 유형 분석             │
│                                     │
│  ☑ Gap 분석 (둘 다 선택 시 활성화)   │
│    └ 선천적 기질 vs 현재 성향 비교   │
└─────────────────────────────────────┘
```

### 5.3 비즈니스 로직
- 사주만: 사주팔자 + 십성 + 대운 + 2026운세
- MBTI만: 성격 유형 + 강점/약점 + 궁합 힌트
- 통합(권장): 위 둘 + Gap 분석 + 숨겨진 잠재력 인사이트

## 6. 개발 환경

### 6.1 언어 및 프레임워크
- **Flutter:** 3.38.x (Dart 3.10.x)
- **Edge Functions:** TypeScript (Deno)

### 6.2 핵심 패키지
```yaml
dependencies:
  # State Management
  flutter_bloc: ^9.1.1
  bloc: ^9.0.0
  equatable: ^2.0.7

  # DI
  get_it: ^8.0.3
  injectable: ^2.5.0

  # Navigation
  go_router: ^15.1.2

  # Backend
  supabase_flutter: (추가 예정)

  # Saju Calculation
  lunar: ^1.3.12

  # UI
  fl_chart: ^0.70.2
  flutter_animate: ^4.5.2
```

### 6.3 CI/CD
- GitHub Actions (추후 설정)
- 자동 테스트, 빌드, 배포 파이프라인

## 7. 보안 고려사항

### 7.1 API Key 보호
- 모든 외부 API 호출은 Edge Function 경유
- 클라이언트에 API Key 노출 금지

### 7.2 데이터 보호
- 생년월일시: 로컬 Secure Storage 기본
- 서버 저장 시: 명시적 동의 + RLS 적용
- GDPR/개인정보보호법 준수

### 7.3 Rate Limiting
- AI 상담: 1회/계정 (무료), 추가 결제 필요
- API 호출: IP당 분당 60회 제한
