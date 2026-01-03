# 🚀 배포 준비 완료 가이드

**작성일**: 2026-01-03
**상태**: ✅ 배포 직전 - 최종 체크

---

## ✅ 완료된 작업

### 1️⃣ 환경 설정 (완료) ✅

**파일**: `.env`

```env
# REST API
SUPABASE_URL=https://eunnaxqjyitxjdkrjaau.supabase.co

# Client Keys (Frontend)
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9....
SUPABASE_PUBLISHABLE_KEY=sb_publishable_5UE1iLKhDsRp203lWMMXEg_L4M6Z_Rd

# Server Keys (Backend only)
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9....
SUPABASE_SECRET_KEY=sb_secret_OzUCAbzREN1jfmI3hfbPIw_b9R7y6nU
```

**설정 방식**:
- ✅ flutter_dotenv로 자동 로드
- ✅ EnvConfig 클래스에서 안전하게 접근
- ✅ main.dart에서 초기화

---

### 2️⃣ 코드 수정 (완료) ✅

**파일**:
- `lib/features/admin/presentation/pages/admin_page.dart` (FIX 1-10)
- `lib/features/saju/presentation/bloc/destiny_bloc.dart` (FIX 10)

**개선사항**:
- ✅ Pagination 무한 스크롤
- ✅ DateTime 타임존 처리
- ✅ useNightSubhour 저장 & 복원
- ✅ 에러 처리 & UI

**검증**: ✅ lint 통과 (0 issues)

---

### 3️⃣ 로컬 마이그레이션 (완료) ✅

**파일**: `supabase/migrations/20260103000100_add_fields_to_user_results.sql`

**내용**:
- firebase_uid 필드 추가
- use_night_subhour 필드 추가
- 인덱스 생성

---

## 🚀 지금 해야 할 일

### Step 1️⃣: 클라우드 Supabase SQL 적용 (필수) ⭐

**URL**: https://supabase.com/dashboard/project/eunnaxqjyitxjdkrjaau/sql/new?skip=true

**SQL**:
```sql
-- firebase_uid와 use_night_subhour 필드 추가
ALTER TABLE public.user_results
ADD COLUMN IF NOT EXISTS firebase_uid TEXT UNIQUE;

ALTER TABLE public.user_results
ADD COLUMN IF NOT EXISTS use_night_subhour BOOLEAN DEFAULT FALSE NOT NULL;

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_user_results_firebase_uid
  ON public.user_results(firebase_uid);
```

**실행 순서**:
1. 위 링크 클릭
2. SQL 복사/붙여넣기
3. **Run** 클릭
4. ✅ 완료!

---

### Step 2️⃣: 필드 추가 확인

**URL**: https://supabase.com/dashboard/project/eunnaxqjyitxjdkrjaau/editor

**확인 사항**:
- [ ] user_results 테이블 클릭
- [ ] 컬럼 목록에 `firebase_uid` 표시 확인
- [ ] 컬럼 목록에 `use_night_subhour` 표시 확인

**또는 SQL로 확인**:
```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'user_results'
ORDER BY ordinal_position;
```

---

### Step 3️⃣: 앱 빌드 & 배포

```bash
# 1. 웹 앱 빌드
flutter build web --release

# 2. Firebase에 배포
firebase deploy

# 결과: https://destiny-os-2026.web.app
```

**예상 시간**: 5-10분

---

### Step 4️⃣: 기능 테스트

```
[ ] 웹앱 접속: https://destiny-os-2026.web.app
[ ] 로그인 (Google/Apple)
[ ] MBTI 입력 및 생일 입력
[ ] 사주 분석 수행
[ ] 데이터 저장 확인 (Admin 페이지)
[ ] Admin 페이지 접근 (MBTI 도움말에서 5배 탭)
[ ] Pagination 테스트 (스크롤)
[ ] 데이터 재분석 테스트
[ ] firebase_uid, use_night_subhour 저장 확인
```

---

## 📊 환경 구성도

```
Development
├── .env (로컬 파일)
│   └── Supabase Cloud 정보 포함 ✅
│
└── lib/core/config/env_config.dart
    └── 우선순위: --dart-define > .env > 기본값

Runtime
├── main.dart
│   ├── dotenv.load('.env') ✅
│   └── Supabase.initialize() ✅
│
└── DestinyBloc, AdminPage
    └── Supabase 클라이언트 사용 ✅
```

---

## 🔗 중요 링크

| 용도 | 링크 |
|------|------|
| SQL 실행 | https://supabase.com/dashboard/project/eunnaxqjyitxjdkrjaau/sql/new?skip=true |
| Table Editor | https://supabase.com/dashboard/project/eunnaxqjyitxjdkrjaau/editor |
| API 설정 | https://supabase.com/dashboard/project/eunnaxqjyitxjdkrjaau/settings/api |
| 로그 | https://supabase.com/dashboard/project/eunnaxqjyitxjdkrjaau/logs |
| 웹앱 | https://destiny-os-2026.web.app |

---

## ✨ 최종 확인 목록

```
Code Preparation
☑️ Admin 페이지 버그 수정 (FIX 1-8)
☑️ Pagination 구현 (FIX 9)
☑️ useNightSubhour 보존 (FIX 10)
☑️ Lint 검증 통과

Configuration
☑️ .env 파일 설정
☑️ EnvConfig 클래스 확인
☑️ main.dart 초기화 확인

Database
☐ Cloud SQL 마이그레이션 적용 (firebase_uid, use_night_subhour)
☐ 필드 추가 확인

Deployment
☐ flutter build web --release
☐ firebase deploy
☐ 프로덕션 테스트

Verification
☐ 로그인 테스트
☐ 사주 분석 테스트
☐ Admin 페이지 테스트
☐ Pagination 테스트
```

---

## 💬 문제 해결

### 문제 1: "firebase_uid가 UNIQUE인데 중복이 발생"

**원인**: 같은 사용자가 여러 번 분석했을 때

**해결책**:
```dart
// INSERT 대신 UPSERT 사용
await supabase.from('user_results')
  .upsert(
    {...},
    onConflict: 'firebase_uid'
  );
```

### 문제 2: "Admin 페이지에서 데이터가 안 보임"

**원인**: RLS 정책으로 인한 접근 제한

**해결책**: 모든 사용자가 조회 가능하도록 정책 설정 (현재 설정됨)

### 문제 3: "use_night_subhour가 항상 false"

**원인**: 기존 데이터의 기본값

**정상**: 새로운 데이터부터 원본 값 저장됨

---

## 🎯 배포 후 단계

### 즉시 (배포 후)
- [ ] 모니터링 대시보드 확인
- [ ] 에러 로그 검토
- [ ] 성능 메트릭 확인

### 24시간 내
- [ ] 실제 사용자 피드백 수집
- [ ] 데이터 저장 확인
- [ ] Admin 페이지 기능 검증

### 1주일 내
- [ ] 추가 최적화
- [ ] RLS 정책 강화 (선택사항)
- [ ] 모니터링 설정

---

## 📞 주요 연락처/문서

| 항목 | 링크/위치 |
|------|---------|
| 상세 가이드 | `docs/FINAL_SUMMARY.md` |
| 마이그레이션 계획 | `docs/CLOUD_SUPABASE_MIGRATION_PLAN.md` |
| 빠른 설정 | `docs/QUICK_CLOUD_SETUP.md` |
| Admin 개선사항 | `docs/ADMIN_PAGE_IMPROVEMENTS.md` |

---

## 🎉 완료!

모든 준비가 완료되었습니다!

**다음 단계**: SQL 한 번 실행하고 배포하면 끝! 🚀

```
https://supabase.com/dashboard/project/eunnaxqjyitxjdkrjaau/sql/new?skip=true
```

---

**상태**: ✅ 배포 준비 완료
**마지막 확인**: 2026-01-03
**배포 대상**: Firebase Hosting (https://destiny-os-2026.web.app)

