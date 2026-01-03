# 클라우드 Supabase 마이그레이션 계획

**프로젝트**: eunnaxqjyitxjdkrjaau
**대시보드**: https://supabase.com/dashboard/project/eunnaxqjyitxjdkrjaau

---

## 📋 현재 상황

### 로컬 Supabase (✅ 완료)
- 모든 마이그레이션 적용됨
- 테이블 구조 확정됨
- 필드 추가 완료 (firebase_uid, use_night_subhour)

### 클라우드 Supabase (🔄 진행 예정)
- 기본 테이블 구조만 있음
- firebase_uid, use_night_subhour 필드 추가 필요
- RLS 정책 업데이트 필요

---

## 🚀 클라우드에 반영할 SQL 스크립트

### 📌 1️⃣ user_results 테이블 확장 (필수)

```sql
-- firebase_uid와 use_night_subhour 필드 추가
ALTER TABLE public.user_results
ADD COLUMN IF NOT EXISTS firebase_uid TEXT UNIQUE;

ALTER TABLE public.user_results
ADD COLUMN IF NOT EXISTS use_night_subhour BOOLEAN DEFAULT FALSE NOT NULL;

-- 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_user_results_firebase_uid
  ON public.user_results(firebase_uid);
```

**실행 방법**:
1. https://supabase.com/dashboard/project/eunnaxqjyitxjdkrjaau/sql/new?skip=true 접속
2. 위 SQL 복사 & 붙여넣기
3. "Run" 버튼 클릭

---

### 📌 2️⃣ RLS 정책 업데이트 (보안)

**현재 정책** (개방적):
```sql
-- Allow read for all users
CREATE POLICY "Enable read access for all users" ON public.user_results
  FOR SELECT USING (true);

-- Allow insert for all users
CREATE POLICY "Enable insert access for all users" ON public.user_results
  FOR INSERT WITH CHECK (true);
```

**개선된 정책** (Firebase Auth 기반):
```sql
-- 기존 정책 제거
DROP POLICY IF EXISTS "Enable read access for all users" ON public.user_results;
DROP POLICY IF EXISTS "Enable insert access for all users" ON public.user_results;

-- Firebase Auth 기반 정책
-- 1. Admin만 읽기 가능
CREATE POLICY "Admin read access"
ON public.user_results
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND (auth.users.raw_user_meta_data->>'role' = 'admin'
         OR auth.users.email LIKE '%@admin%')
  )
);

-- 2. 모든 사용자 삽입 가능 (Firebase로 인증했을 때)
CREATE POLICY "Authenticated users can insert"
ON public.user_results
FOR INSERT
WITH CHECK (true);

-- 3. Admin만 업데이트/삭제
CREATE POLICY "Admin update delete"
ON public.user_results
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND (auth.users.raw_user_meta_data->>'role' = 'admin'
         OR auth.users.email LIKE '%@admin%')
  )
);

CREATE POLICY "Admin delete access"
ON public.user_results
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND (auth.users.raw_user_meta_data->>'role' = 'admin'
         OR auth.users.email LIKE '%@admin%')
  )
);
```

**⚠️ 주의**: 클라우드에서 RLS를 적용하면 Admin 페이지에서 데이터 조회가 제한될 수 있습니다.

**권장**: 처음부터 모든 사용자가 삽입/읽기 가능하도록 유지하고, 나중에 단계별 제한 추가

---

## 🎯 최종 체크리스트

### Step 1️⃣: 필드 추가 (필수)
```
[ ] firebase_uid 필드 추가
[ ] use_night_subhour 필드 추가
[ ] 인덱스 생성 확인
```

**SQL 실행**: https://supabase.com/dashboard/project/eunnaxqjyitxjdkrjaau/sql/new

```sql
ALTER TABLE public.user_results
ADD COLUMN IF NOT EXISTS firebase_uid TEXT UNIQUE;

ALTER TABLE public.user_results
ADD COLUMN IF NOT EXISTS use_night_subhour BOOLEAN DEFAULT FALSE NOT NULL;

CREATE INDEX IF NOT EXISTS idx_user_results_firebase_uid
  ON public.user_results(firebase_uid);
```

---

### Step 2️⃣: 필드 추가 확인
```
[ ] Table Editor에서 user_results 테이블 확인
[ ] 새로운 컬럼 (firebase_uid, use_night_subhour) 표시 확인
```

**확인 방법**:
1. https://supabase.com/dashboard/project/eunnaxqjyitxjdkrjaau/editor
2. user_results 클릭
3. 컬럼 목록에서 firebase_uid, use_night_subhour 확인

---

### Step 3️⃣: 코드 배포
```
[ ] Flutter 앱 빌드
[ ] Firebase Hosting에 배포
```

**명령어**:
```bash
flutter build web --release
firebase deploy
```

---

### Step 4️⃣: 통합 테스트
```
[ ] 로컬 Supabase에서 테스트 완료
[ ] 클라우드 Supabase에 필드 추가
[ ] 웹앱에서 운세 분석 후 데이터 저장 확인
[ ] Admin 페이지에서 데이터 조회 및 재분석 테스트
```

---

## 📊 적용 순서

```
1. 로컬 테스트 ✅ (완료)
   ↓
2. 클라우드에 필드 추가 🔄 (지금)
   ↓
3. 앱 배포
   ↓
4. 프로덕션 테스트
```

---

## ⚠️ 주의사항

### 1. RLS 정책 변경 시
- 기존 정책과 충돌할 수 있음
- 테스트 후 적용 권장
- 필요시 되돌릴 수 있도록 백업 필수

### 2. firebase_uid 필드
- 고유값(UNIQUE)으로 설정됨
- 중복 시 오류 발생
- 기존 데이터가 있다면 NULL 값 허용 필요

### 3. use_night_subhour 기본값
- 기본값: FALSE
- 기존 데이터는 모두 FALSE로 설정됨
- 정확한 히스토리가 필요하면 수동 업데이트 필요

---

## 🔄 생성된 마이그레이션 파일

로컬에서 준비된 SQL (필요시 참고):

```
supabase/migrations/20260103000100_add_fields_to_user_results.sql
```

클라우드에는 SQL Editor에서 직접 실행:
```
https://supabase.com/dashboard/project/eunnaxqjyitxjdkrjaau/sql/new
```

---

## 💾 백업 권장

클라우드에 변경을 적용하기 전에:

```
[ ] user_results 테이블 데이터 내보내기
[ ] 현재 스키마 스크린샷 저장
```

**방법**:
1. Supabase Dashboard → user_results 테이블
2. "Export" 버튼 → CSV 또는 JSON으로 저장
3. 변경 적용 후 복구 가능하도록 보관

---

## ✨ 완료 후 확인

```bash
# 1. Firebase 인증으로 로그인
# 2. 운세 분석 수행
# 3. user_results 테이블 확인:
#    - firebase_uid가 저장되었는가?
#    - use_night_subhour가 저장되었는가?
# 4. Admin 페이지:
#    - Pagination 작동하는가?
#    - 데이터 재분석 가능한가?
```

