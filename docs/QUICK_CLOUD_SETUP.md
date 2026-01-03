# 클라우드 Supabase 빠른 설정 가이드

## 🎯 1분 안에 완료하기

### 1️⃣ 클라우드 대시보드 접속
https://supabase.com/dashboard/project/eunnaxqjyitxjdkrjaau/sql/new?skip=true

### 2️⃣ 아래 SQL을 복사하여 붙여넣기

```sql
-- firebase_uid와 use_night_subhour 필드 추가
ALTER TABLE public.user_results
ADD COLUMN IF NOT EXISTS firebase_uid TEXT UNIQUE;

ALTER TABLE public.user_results
ADD COLUMN IF NOT EXISTS use_night_subhour BOOLEAN DEFAULT FALSE NOT NULL;

-- 인덱스 생성 (Admin 페이지 성능 최적화)
CREATE INDEX IF NOT EXISTS idx_user_results_firebase_uid
  ON public.user_results(firebase_uid);
```

### 3️⃣ "Run" 버튼 클릭

✅ 완료!

---

## ✅ 확인 방법

### 방법 1: Table Editor에서 확인
1. https://supabase.com/dashboard/project/eunnaxqjyitxjdkrjaau/editor
2. **user_results** 테이블 클릭
3. 우측 "Columns" 패널 확인
4. `firebase_uid`, `use_night_subhour` 컬럼 표시 확인

### 방법 2: SQL로 확인
```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'user_results'
ORDER BY ordinal_position;
```

---

## 🚀 다음 단계

### 앱 배포
```bash
# 로컬 테스트 완료 후
flutter build web --release
firebase deploy
```

### 기능 확인
1. ✅ 사주 분석 → 데이터 저장
2. ✅ Admin 페이지 → 데이터 조회
3. ✅ 재분석 → 원본 설정 복원

---

## ⚠️ 주의사항

### firebase_uid가 UNIQUE로 설정됨
- 같은 firebase_uid로 여러 번 저장하면 오류
- 의도: 한 사용자당 1개의 최신 분석만 저장
- 해결: 새로운 분석을 저장하려면 REPLACE 또는 UPDATE 사용

**현재 코드 (INSERT)는 새 레코드 생성**:
```dart
await supabase.from('user_results').insert({...})
```

**만약 업데이트 원한다면** (선택사항):
```dart
// INSERT OR UPDATE (UPSERT)
await supabase.from('user_results')
  .upsert({...}, onConflict: 'firebase_uid')
```

---

## 📊 스키마 확인

### user_results 테이블 완전 스키마
```
Column              | Type                    | Nullable | Default
--------------------|------------------------|----------|------------------
id                  | uuid                   | FALSE    | gen_random_uuid()
created_at          | timestamptz            | TRUE     | now()
name                | text                   | TRUE     |
birth_date          | timestamp with tz      | FALSE    |
birth_hour          | integer                | TRUE     |
gender              | text                   | FALSE    |
is_lunar            | boolean                | TRUE     | false
mbti                | text                   | FALSE    |
firebase_uid        | text                   | TRUE     | ✨ NEW
use_night_subhour   | boolean                | FALSE    | false ✨ NEW
```

---

## 🔗 관련 링크

- **SQL Editor**: https://supabase.com/dashboard/project/eunnaxqjyitxjdkrjaau/sql/new
- **Table Editor**: https://supabase.com/dashboard/project/eunnaxqjyitxjdkrjaau/editor
- **API Docs**: https://supabase.com/dashboard/project/eunnaxqjyitxjdkrjaau/api
- **로그**: https://supabase.com/dashboard/project/eunnaxqjyitxjdkrjaau/logs

---

## 💬 FAQ

**Q: 기존 데이터는 어떻게 되나?**
A: 새 컬럼이 추가되고 기존 행은 그대로 유지됨. NULL 값으로 기본 설정됨.

**Q: Rollback은?**
A: 다음 SQL로 필드 제거 가능:
```sql
ALTER TABLE public.user_results DROP COLUMN IF EXISTS firebase_uid;
ALTER TABLE public.user_results DROP COLUMN IF EXISTS use_night_subhour;
DROP INDEX IF EXISTS idx_user_results_firebase_uid;
```

**Q: 이게 맞는 구조인가?**
A: 예. 로컬 Supabase에서 먼저 완전히 테스트했고 작동 확인됨.

---

## ✨ 완료 후

```
☑️ Supabase 필드 추가 완료
☑️ 앱 배포 완료
☑️ 기능 테스트 완료
→ 🎉 완성!
```

