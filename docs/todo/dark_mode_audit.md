# 다크모드 전수조사 (화면별)

이 문서는 **다크모드 미지원/부분지원 이슈를 화면(페이지) 단위로 전수조사**한 결과와, 수정 방향/진행 상황을 정리합니다.

## 기준 (원인 패턴)

- `Scaffold(backgroundColor: AppColors.background)` 같이 **라이트 고정 상수**를 직접 지정하면 `AppTheme.dark`가 적용돼도 화면이 라이트로 고정됩니다.
- `Colors.black.withOpacity(...)` 기반의 **그림자/음영**은 다크에서 “회색 먼지/막”처럼 보여 품질이 급격히 떨어집니다.
- `AppColors.white`를 **버튼/칩 텍스트**에 고정하면, 다크 테마의 `colorScheme.onPrimary`와 불일치(가독성 저하) 가능성이 큽니다.

### 권장 치환 규칙

- **배경/서피스**: `AppColors.backgroundOf(context)`, `AppColors.surfaceOf(context)`, `AppColors.surfaceVariantOf(context)`
- **텍스트**: `AppColors.textPrimaryOf(context)`, `AppColors.textSecondaryOf(context)`, `AppColors.textTertiaryOf(context)`
- **Primary 위 텍스트/아이콘**: `Theme.of(context).colorScheme.onPrimary`
- **그림자/음영**: `AppColors.shadowOf(context, lightOpacity: ..., darkOpacity: ...)`

---

## 화면별 현황

### `온보딩` (`lib/features/onboarding/presentation/pages/onboarding_page.dart`)

- **발견**: `background/surface/border/text*` 라이트 고정 다수
- **조치**: 배경/텍스트/혜택 카드/CTA 버튼을 테마 기반으로 치환
- **상태**: **수정 완료(핵심 영역)**

### `입력` (`lib/features/saju/presentation/pages/input_page.dart`)

- **발견**: `primary` 배경 위 텍스트/아이콘이 `AppColors.white`로 고정된 구간 존재
- **조치**: `Theme.of(context).colorScheme.onPrimary`로 치환(선택 칩/성별 버튼/CTA)
- **상태**: **수정 완료(핵심 영역)**

### `결과` (`lib/features/saju/presentation/pages/result_page.dart`)

- **발견**: `background/surface/text*` 라이트 고정으로 다크에서 화면 전체가 라이트로 고정
- **조치**: `*Of(context)`로 전면 치환 + 바텀시트/카드 섀도우를 `AppColors.shadowOf`로 치환
- **상태**: **수정 완료(전면)**

### `AI 상담` (`lib/features/ai_consultation/presentation/pages/consultation_page.dart`)

- **발견**: 메시지 버블/입력바/텍스트가 `surface/background/text*` 라이트 고정, 아이콘이 `Colors.white` 고정
- **조치**: `surfaceOf/backgroundOf/text*Of`로 치환 + `onPrimary/onError` 적용 + 섀도우 `shadowOf` 적용
- **상태**: **수정 완료(핵심 영역)**

### `설정` (`lib/features/settings/presentation/pages/settings_page.dart`)

- **발견**: 기술 카드/바텀시트 영역에서 `surface/grey/text*` 라이트 고정, SnackBar도 색상 오버라이드
- **조치**: 기술 관련 UI를 `surfaceVariantOf/text*Of` 기반으로 치환, SnackBar는 테마에 위임
- **상태**: **수정 완료(핵심 영역)**

### `관리자` (`lib/features/admin/presentation/pages/admin_page.dart`)

- **발견**: 배경/앱바/리스트 타일이 라이트 고정
- **조치**: `backgroundOf/surfaceOf/text*Of` 기반으로 치환
- **상태**: **수정 완료**

### `2026 운세` (`lib/features/fortune_2026/presentation/pages/fortune_2026_page.dart`)

- **발견**: 카드 배경/차트/월별 리스트에서 `surface/border/textPrimary` 라이트 고정
- **조치**: `surfaceOf/borderOf/text*Of`로 치환 + 섀도우 `shadowOf` 적용 + 경고 카드(11월) 다크에서 과도한 밝기 완화
- **상태**: **수정 완료(핵심 영역)**

---

## 미처리/추가 확인 필요(다음 타겟)

아래 화면들은 하드코딩 색상(특히 `AppColors.surface`, `AppColors.background`, `Colors.black.withOpacity`, `Colors.white`)이 다수 남아 있어 **다크 품질 저하 가능성이 높습니다**.

- `대운` (`lib/features/daewoon/presentation/pages/daewoon_page.dart`)
  - 하드코딩 스캔(대략): `AppColors.(background/surface/text*)` **37건**, `Colors.(white/black)` **35건**
- `궁합` (`lib/features/compatibility/presentation/pages/compatibility_page.dart`)
  - 하드코딩 스캔(대략): `AppColors.(background/surface/text*)` **27건**
- `공유` (`lib/features/share/presentation/pages/share_page.dart`)
  - 하드코딩 스캔(대략): `Colors.(white/black)` **38건**
  - 특이사항: SNS 브랜드 컬러(카카오/인스타 등) 고정색이 포함되어 “다크 대응”과 “브랜드 유지”의 경계가 필요
- `스플래시` (`lib/features/onboarding/presentation/pages/splash_page.dart`)

---

## 체크리스트(화면 검수 포인트)

- **Scaffold/AppBar/BottomSheet 배경**이 다크에서 밝게 뜨지 않는가?
- **Card/Container 배경**이 `surfaceOf/surfaceVariantOf`를 따르는가?
- **텍스트 대비**(특히 Primary 위 텍스트)가 `onPrimary` 기준으로 읽히는가?
- **그림자/분리선**이 다크에서 “먼지처럼 탁해지지” 않는가?

