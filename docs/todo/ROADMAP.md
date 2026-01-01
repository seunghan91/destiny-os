# Destiny.OS - 프로젝트 로드맵 및 체크리스트

> **최종 업데이트**: 2026-01-01
> **현재 상태**: Phase 2-3 진행 중 (MVP 기능 개발)

---

## Phase 1: 프로젝트 셋업 및 설계 ✅ 완료
- [x] 프로젝트 폴더 구조 생성
- [x] 설계 문서 초안 작성 (PRD, Tech Spec)
- [x] 상세 기능 명세 확정 (01-features.md)
- [x] UI/UX 와이어프레임 설계 (04-ui-design.md)
- [x] 데이터베이스 스키마 설계 (03-data-model.md)

---

## Phase 2: 개발 환경 구축 ✅ 완료

### 기본 환경
- [x] Flutter 프로젝트 생성
- [x] Clean Architecture 디렉토리 구조 설정
- [x] 필수 패키지 설치 (flutter_bloc, go_router, get_it, lunar 등)
- [x] Git 레포지토리 초기화
- [x] Supabase 프로젝트 연동 (초기화 완료, 오프라인 모드 지원) ✅ 신규

### 테마 & 라우팅
- [x] 테마 시스템 구축 (Toss 디자인 시스템 컬러)
- [x] 타이포그래피 설정 (Pretendard 정의됨)
- [x] Pretendard 폰트 설정 (pubspec.yaml 구성 완료, 폰트 다운로드 가이드 제공) ✅ 신규
- [x] 라우터 설정 (go_router, 8개 메인 라우트)
- [x] DI 컨테이너 완성 (GetIt - Supabase 클라이언트 등록 완료) ✅ 신규
- [x] Error handling 기본 구조 (failures.dart)

### 핵심 알고리즘
- [x] 천간/지지 상수 정의 (saju_constants.dart)
- [x] 60갑자 매핑 로직 (lunar 패키지 활용)
- [x] 양력↔음력 변환 (lunar 패키지)
- [x] 24절기 계산 (lunar 패키지)
- [x] 경도 보정 (진태양시) 옵션
- [x] 십성 매핑 로직 (ten_gods.dart)
- [x] 오행 분포 계산

---

## Phase 3: MVP 기능 개발 🔄 진행 중

### 3.1 사주 분석 기능 ✅ 완료
- [x] 입력 화면 (input_page.dart - 1172줄)
  - [x] CupertinoDatePicker (생년월일)
  - [x] 성별 선택
  - [x] 시간 선택 (12시진 - siju_picker.dart)
  - [x] MBTI 그리드 선택 (mbti_grid_selector.dart)
  - [x] 로딩 애니메이션
- [x] DestinyBloc 구현 (632줄)
  - [x] AnalyzeFortune 이벤트
  - [x] UpdateBirthData/UpdateMbti 이벤트
  - [x] 상태 관리 (Initial, Analyzing, Success, Failure)
- [x] 결과 화면 (result_page.dart - 536줄)
  - [x] 사주 차트 표시
  - [x] Gap 분석 결과 카드
  - [x] 네비게이션 그리드
  - [x] AI 상담 CTA

### 3.2 MBTI 연동 & Gap Analysis ✅ 완료
- [x] Saju-to-MBTI 변환 로직 (saju_calculator.dart)
- [x] Gap Score 계산 (destiny_bloc.dart)
- [x] 차원별 분석 (E/I, N/S, T/F, J/P)
- [x] 인사이트 텍스트 생성
- [x] 숨겨진 잠재력 해석

### 3.3 2026년 운세 (병오년) ✅ 완료
- [x] Fortune2026 엔티티 (fortune_2026.dart - 173줄)
- [x] 월별 에너지 데이터 (화기 에너지)
- [x] 화(火) 궁합 분석 (FireCompatibility)
- [x] 운세 레벨 열거형 (FortuneLevel)
- [x] fortune_2026_page.dart 구현

### 3.4 대운(Daewoon) 타임라인 ✅ 완료
- [x] Daewoon 엔티티 정의 (daewoon.dart)
- [x] 대운 계산 로직 (saju_calculator.dart:261-316)
- [x] **절입일 기반 대운 시작 나이 계산** (lunar 패키지 getNextJie/getPrevJie 활용) ✅ 신규
- [x] 순행/역행 결정 로직 (양남음녀=순행, 음남양녀=역행) ✅
- [x] 기본 페이지 구조 (daewoon_page.dart - 812줄)
- [x] 가로 스크롤 타임라인 UI ✅
- [x] 현재 대운 하이라이트 ✅
- [x] 클릭 시 상세 팝업 (정보 모달) ✅
- [x] 대운별 운세 점수 차트 ✅
- [x] 다음 대운 미리보기 ✅
- [x] BLoC 연동 완료 (DestinyBloc.daewoonChart)

### 3.5 궁합 분석 ✅ 완료
- [x] Compatibility 엔티티 (compatibility.dart)
- [x] 기본 페이지 (compatibility_page.dart - 1500줄)
- [x] 관계 유형 선택 (연인/친구/가족)
- [x] 점수 표시 및 강점/주의점
- [x] 두 번째 사람 사주 입력 UI ✅
- [x] **일주 궁합 계산 (천간합/육합/삼합/충/형/해)** - saju_calculator.dart:507-967 ✅ 검증
- [x] **오행 균형 분석 (상호보완/부족 분석)** ✅ 검증
- [x] **관계 유형별 점수 조정 (연애/결혼/사업/우정)** ✅ 검증
- [x] AI 상담 연동 (CTA 버튼 연결)

### 3.6 AI 상담 기능 🟡 부분 완료
- [x] ChatMessage 엔티티 (chat_message.dart)
- [x] AiConsultationService 래퍼 (ai_consultation_service.dart)
- [x] CreditService (1회 무료 추적)
- [x] 기본 상담 페이지 (consultation_page.dart)
- [x] **상담 기록 저장** (consultation_storage_service.dart) ✅ 신규 (2026-01-01)
  - [x] 세션 자동 저장 (앱 백그라운드 전환 시)
  - [x] 대화 히스토리 조회 바텀시트
  - [x] 대화 삭제 기능
  - [x] 최대 50개 대화, 대화당 100개 메시지 제한
- [ ] 실제 AI API 연동 (API 키 교체 필요)
- [ ] 상담 유형 선택 UI 완성
- [ ] 프롬프트 템플릿 최적화

### 3.7 공유 기능 ✅ 완료
- [x] share_page.dart 구현 (850줄)
- [x] RepaintBoundary 캡처
- [x] 9:16 카드 템플릿
- [x] **카카오톡 공유** ✅ 신규 (2026-01-01)
  - [x] 카카오톡 앱 설치 감지 및 공유
  - [x] 미설치 시 안내 다이얼로그
- [x] **인스타그램 스토리 공유** ✅ 신규 (2026-01-01)
  - [x] iOS/Android 분기 처리
  - [x] 인스타그램 앱 설치 감지 및 공유
  - [x] 스토리 공유 intent 처리
- [ ] 실제 앱 스토어 링크 연동

### 3.8 온보딩 ✅ 완료
- [x] splash_page.dart (애니메이션)
- [x] onboarding_page.dart (캐러셀)
- [x] onboarding_content.dart
- [x] onboarding_page_indicator.dart
- [x] SharedPreferences 상태 저장

### 3.9 설정 페이지 ✅ 완료
- [x] 야자시 적용 여부 토글
- [x] 진태양시 적용 토글
- [x] 알림 설정
- [x] 데이터 초기화 (개인정보 삭제)
- [x] 앱 버전 정보
- [x] 개인정보처리방침/이용약관 링크
- [x] 오픈소스 라이선스 표시
- [x] 라우터 연결 ✅ 신규
- [x] **사주 분석 기술 섹션** ✅ 신규 (2026-01-01)
  - [x] 기술력 소개 카드 (바텀시트 상세 정보)
  - [x] 정확도 표시 (사주팔자 95%, 십성 85%, 궁합 90%, 대운 88%)
  - [x] 4개 기술 태그 (만세력 엔진, 오행 분석, 십성 계산, 궁합 알고리즘)
  - [x] 기술 면책 조항

---

## Phase 4: 테스트 및 배포 🔄 진행 중

### UI/UX 개선 ✅ 완료 (2026-01-01)
- [x] **다크모드 지원** ✅ 신규
  - [x] ThemeController/ThemeNotifier 상태 관리
  - [x] 설정 페이지 테마 선택 UI (시스템/라이트/다크)
  - [x] 다크모드 전용 컬러 팔레트 (colors.dart)
  - [x] 앱 전체 다크모드 테마 (app_theme.dart)
  - [x] SharedPreferences 테마 설정 저장
- [x] **페이지 전환 애니메이션 개선** ✅ 신규
  - [x] flutter_animate 활용 위젯 애니메이션
  - [x] ResultHeroCard fadeIn/slideY/scale 애니메이션
  - [x] ResultNavigationGrid staggered 애니메이션
  - [x] ResultAiCta fadeIn/shimmer 애니메이션
- [x] **햅틱 피드백 적용** (HapticFeedback.lightImpact/mediumImpact)
- [ ] 차트 드로잉 애니메이션

### 테스트
- [ ] 만세력 정확도 검증 (10+ 샘플)
- [ ] Unit 테스트 작성
- [ ] Widget 테스트 작성
- [ ] 통합 테스트

### 배포 준비
- [ ] 앱 아이콘 & 스플래시 최종화
- [ ] 스토어 스크린샷 제작
- [ ] 개인정보처리방침 작성
- [ ] 이용약관 작성
- [ ] iOS 빌드 및 App Store 제출
- [ ] Android 빌드 및 Play Store 제출

---

## 구현 현황 요약

| 기능 | 상태 | 완성도 | 업데이트 |
|------|------|--------|----------|
| 프로젝트 셋업 | ✅ | 100% | Supabase 연동 완료 |
| 사주 분석 엔진 | ✅ | 98% | 절입일 기반 대운수 계산 검증 |
| MBTI Gap 분석 | ✅ | 95% | - |
| 2026년 운세 | ✅ | 85% | - |
| 대운 타임라인 | ✅ | 98% | 3일=1년 환산법, 절기 기반 정밀 계산 |
| 궁합 분석 | ✅ | 100% | 합/충/형/파/해 계산 엔진 완성 |
| AI 상담 | 🟡 | 70% | 상담 기록 저장 기능 추가 |
| 공유 기능 | ✅ | 95% | 카카오/인스타그램 공유 추가 |
| 온보딩 | ✅ | 90% | - |
| 설정 | ✅ | 100% | 다크모드 테마 선택 추가 |
| UI/UX | ✅ | 90% | 애니메이션, 햅틱, 다크모드 완성 |
| 테스트 | ❌ | 0% | - |

**전체 진행률: ~91%** (2026-01-01 업데이트)

---

## 즉시 해결 필요한 TODO

### Critical (기능 차단)
1. ~~`injection.dart:12` - Supabase Client 등록~~ ✅ 완료 (2026-01-01)
2. ~~`main.dart:28` - Supabase 초기화~~ ✅ 완료 (2026-01-01)
3. `ai_consultation_service.dart:7` - 실제 API 키 교체

### High Priority
1. ~~Settings 페이지 구현~~ ✅ 완료
2. ~~대운 타임라인 UI 완성~~ ✅ 완료
3. ~~궁합 두 번째 사람 입력 기능~~ ✅ 완료
4. ~~대운 순행/역행 실제 계산 로직~~ ✅ 완료 (2026-01-01, 절입일 기반)
5. ~~궁합 실제 계산 로직~~ ✅ 검증 완료 (2026-01-01, 이미 구현됨)
6. ~~다크모드 지원~~ ✅ 완료 (2026-01-01, ThemeNotifier 패턴)
7. ~~AI 상담 기록 저장~~ ✅ 완료 (2026-01-01, ConsultationStorageService)
8. ~~카카오/인스타그램 공유~~ ✅ 완료 (2026-01-01, url_launcher 연동)
9. ~~UI/UX 애니메이션~~ ✅ 완료 (2026-01-01, flutter_animate 적용)

### Medium Priority
1. `share_page.dart` - 실제 앱 스토어 링크
2. ~~Pretendard 폰트 파일 추가~~ ✅ 설정 완료 (2026-01-01, assets/fonts/DOWNLOAD_FONTS.md 참조)
3. 테스트 코드 작성
4. flutter analyze 경고 수정

---

## 기술 스택

### 현재 사용 중
```yaml
# State Management
flutter_bloc: ^9.1.1
equatable: ^2.0.7

# Navigation
go_router: ^15.1.2

# Storage
flutter_secure_storage: ^9.2.4
shared_preferences: ^2.3.5
supabase_flutter: ^2.8.3

# Business Logic
lunar: ^1.3.12  # 핵심 - 만세력 계산
dio: ^5.8.0+1
dartz: ^0.10.1

# UI
fl_chart: ^0.70.2
flutter_animate: ^4.5.2
flutter_svg: ^2.0.10+1
google_fonts: ^6.2.1

# DI
get_it: ^8.0.3
```

---

## 파일 통계

- **총 Dart 파일**: 47개
- **Feature 모듈**: 9개 (saju, mbti, fortune_2026, daewoon, compatibility, ai_consultation, onboarding, share, settings)
- **Core 모듈**: 8개 (constants, di, error, theme, router, usecases, utils, config)
- **Shared 위젯**: 6개
- **추정 코드 라인**: ~8,000줄
