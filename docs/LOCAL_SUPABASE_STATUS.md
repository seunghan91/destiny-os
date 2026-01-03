# 로컬 Supabase 상태 분석 및 반영 계획

**작성일**: 2026-01-03
**상태**: 분석 완료

---

## 📊 로컬 vs 클라우드 Supabase 구조 비교

### 로컬 Supabase (supabase/migrations)

✅ **이미 구축된 테이블**:
1. **user_profiles** (20260102000100)
   - firebase_uid (UNIQUE, NOT NULL) ✨ Firebase Auth 연동
   - birth_date, birth_hour, gender, is_lunar, mbti
   - email, display_name, auth_provider
   - created_at, updated_at

2. **user_results** (20240101000000)
   - id, created_at, name, birth_date, birth_hour
   - gender, is_lunar, mbti
   - ❌ firebase_uid 없음 (별도 테이블에 존재)
   - ❌ use_night_subhour 없음

3. **user_credits** (20260102000100)
   - balance, user_id (foreign key to user_profiles)

4. **credit_transactions** (20260102000100)
   - type, amount, balance_after
   - feature_used, description, metadata

5. **consultations** (20260101_create_consultations)
   - 상담 내역

6. **fortune_year_results** (20260101000300)
   - 연간 운세

7. **payments, subscriptions** (20260101000500)
   - 결제 시스템

---

## 🔍 현재 코드와의 불일치

### DestinyBloc (lib/features/saju/presentation/bloc/destiny_bloc.dart)

**현재 코드**:
```dart
await supabase.from('user_results').insert({
  'firebase_uid': user?.id,              // ❌ user_results에 없음
  'birth_date': event.birthDateTime.toIso8601String(),
  'birth_hour': event.birthDateTime.hour,
  'is_lunar': event.isLunar,
  'gender': event.gender,
  'mbti': event.mbtiType,
  'name': event.name,
  'use_night_subhour': event.useNightSubhour,  // ❌ user_results에 없음
  'created_at': DateTime.now().toIso8601String(),
}).select('id');
```

**문제**:
- `user_results`에 `firebase_uid` 필드가 없음 (user_profiles에 있음)
- `use_night_subhour` 필드가 없음

---

## 🛠️ 반영해야 할 작업

### 📌 옵션 1: user_results 테이블 확장 (권장)

로컬 구조를 유지하면서 필드 추가:

```sql
-- supabase/migrations/20260103000100_add_fields_to_user_results.sql
ALTER TABLE public.user_results ADD COLUMN IF NOT EXISTS firebase_uid TEXT;
ALTER TABLE public.user_results ADD COLUMN IF NOT EXISTS use_night_subhour BOOLEAN DEFAULT FALSE NOT NULL;

-- 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_user_results_firebase_uid ON public.user_results(firebase_uid);
```

**장점**:
- ✅ 단순함
- ✅ user_results가 독립적으로 완전한 데이터 보유
- ✅ Admin 페이지에서 쉽게 접근

---

### 📌 옵션 2: 구조 개선 (장기적)

user_profiles와 user_results 연결:

```sql
-- user_results에 user_profiles 참조 추가
ALTER TABLE public.user_results
ADD COLUMN IF NOT EXISTS user_profile_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE;

-- firebase_uid는 user_profiles에서만 관리
-- use_night_subhour는 user_results에 추가
ALTER TABLE public.user_results
ADD COLUMN IF NOT EXISTS use_night_subhour BOOLEAN DEFAULT FALSE NOT NULL;
```

**장점**:
- ✅ 데이터 일관성
- ✅ user_profiles과 user_results 간 관계 명확
- ❌ 코드 변경 필요 (쿼리 JOIN 필요)

---

## 🎯 권장 조치

### 1️⃣ 즉시 적용 (Option 1 선택)

새 마이그레이션 파일 생성:
```bash
supabase/migrations/20260103000100_add_fields_to_user_results.sql
```

**이유**:
- 코드 변경 최소화
- 로컬 구조와 맞춤
- Admin 페이지 호환성 유지

---

## 📋 체크리스트

### 로컬 환경
- [ ] `supabase/migrations/20260103000100_add_fields_to_user_results.sql` 생성
- [ ] `supabase start` 또는 마이그레이션 적용
- [ ] 필드 추가 확인:
  ```bash
  psql postgresql://postgres:postgres@127.0.0.1:54322/postgres \
    -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'user_results' ORDER BY ordinal_position;"
  ```

### 클라우드 Supabase (배포 전)
- [ ] 동일한 마이그레이션 생성/적용
- [ ] RLS 정책 검토 (scripts/rls_user_results.sql의 정책 통합 여부)

### 코드
- [x] DestinyBloc 수정 (firebase_uid, use_night_subhour 저장) ✅ 완료
- [x] AdminPage 수정 (use_night_subhour 복원) ✅ 완료
- [ ] 로컬 테스트

---

## 🤔 MCP 연결 문제 설명

### 왜 `mcp__postgresql__query`가 안 되는가?

**현재 상황**:
```
❌ mcp__postgresql__query ← PostgreSQL MCP 서버 미연결
✅ Bash + psql      ← 직접 CLI 접근 (작동)
```

**이유**:
1. MCP (Model Context Protocol) 서버는 **선택 사항**
2. 현재 환경에서 PostgreSQL MCP 서버가 구성되지 않음
3. 대신 Bash로 `psql` 명령어 직접 사용 가능

**해결책**:
- MCP 설정이 필요하지 않음 ✅
- Bash + psql로 충분함 ✅
- 이미 성공적으로 사용 중

**MCP의 역할**:
- 데이터베이스와의 구조화된 상호작용
- 더 안전한 쿼리 실행
- 자동 타입 변환
- 에러 처리

**현재 대안**:
- 직접 psql CLI 사용 (현재 방식)
- 더 안전하지만 번거로움
- Bash로 충분함

---

## 📝 다음 단계

1. **마이그레이션 파일 생성**: 20260103000100_add_fields_to_user_results.sql
2. **로컬 테스트**: `supabase start` 후 필드 확인
3. **Admin 페이지 테스트**: Pagination + useNightSubhour 복원 기능
4. **배포 준비**: 클라우드 Supabase에도 동일 마이그레이션 적용

---

## 📚 참고

**로컬 마이그레이션 파일 목록**:
```
20240101000000_create_user_results.sql
20260101_create_consultations.sql
20260101000100_harden_user_results.sql
20260101000200_create_usage_tracking.sql
20260101000300_create_fortune_year_results.sql
20260101000500_payment_system.sql
20260102000100_user_profiles_credits.sql
20260102000200_rls_security_and_schema_integration.sql
20260103_fix_rls_for_client_insert.sql
```

**필요한 마이그레이션**:
```
➕ 20260103000100_add_fields_to_user_results.sql (NEW)
```

