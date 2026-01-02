# Supabase 자동화 가이드

## 📋 목차

1. [자동 배포 시스템](#자동-배포-시스템)
2. [SQL 마이그레이션 자동화](#sql-마이그레이션-자동화)
3. [Edge Functions 자동 배포](#edge-functions-자동-배포)
4. [Cron Job 자동 설정](#cron-job-자동-설정)
5. [문제 해결](#문제-해결)

---

## 자동 배포 시스템

### 전체 자동화 흐름

```bash
# 1단계: Supabase CLI 로그인 (최초 1회만)
supabase login

# 2단계: 프로젝트 연결 (최초 1회만)
supabase link --project-ref eunnaxqjyitxjdkrjaau

# 3단계: 자동 배포 (이후 계속 사용)
supabase db push              # SQL 마이그레이션 자동 실행
supabase functions deploy     # Edge Functions 전체 배포
```

---

## SQL 마이그레이션 자동화

### 기본 원칙

1. **파일명 규칙**: `YYYYMMDDHHMMSS_description.sql`
   - 예: `20260101000500_payment_system.sql`
   - 시간순으로 정렬되어 순차 실행됨

2. **멱등성 보장**: 여러 번 실행해도 안전하도록 작성
   ```sql
   -- ✅ 올바른 예
   CREATE TABLE IF NOT EXISTS users (...);
   CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

   -- ❌ 잘못된 예
   CREATE TABLE users (...);  -- 이미 존재하면 에러 발생
   ```

3. **정책(Policy) 중복 방지**
   ```sql
   -- ✅ 올바른 예: DO $$ 블록으로 체크
   DO $$
   BEGIN
     IF NOT EXISTS (
       SELECT 1 FROM pg_policies
       WHERE tablename = 'users'
       AND policyname = 'Users can view own data'
     ) THEN
       CREATE POLICY "Users can view own data"
       ON users FOR SELECT
       USING (auth.uid() = auth_id);
     END IF;
   END $$;

   -- ❌ 잘못된 예
   CREATE POLICY "Users can view own data" ...;  -- 이미 존재하면 에러
   ```

4. **트리거 중복 방지**
   ```sql
   -- ✅ 올바른 예
   DROP TRIGGER IF EXISTS update_users_updated_at ON users;
   CREATE TRIGGER update_users_updated_at ...;

   -- ❌ 잘못된 예
   CREATE TRIGGER update_users_updated_at ...;  -- 이미 존재하면 에러
   ```

### UUID 함수 사용

```sql
-- ✅ 권장: PostgreSQL 내장 함수 (extension 불필요)
id UUID PRIMARY KEY DEFAULT gen_random_uuid()

-- ⚠️ 비권장: extension 필요
id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
-- 만약 사용한다면 먼저 extension 활성화:
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

### 자동 배포 명령어

```bash
# 방법 1: 대화형 (추천)
supabase db push

# 방법 2: 자동 승인
echo "Y" | supabase db push

# 방법 3: GitHub Actions CI/CD
- name: Deploy migrations
  run: |
    supabase link --project-ref ${{ secrets.SUPABASE_PROJECT_REF }}
    echo "Y" | supabase db push
```

### 마이그레이션 충돌 해결

**문제**: 기존 마이그레이션과 충돌 발생
```
ERROR: policy "Enable read access" already exists
```

**해결책 1**: 새 마이그레이션만 배포
```bash
# 1. 기존 마이그레이션 임시 백업
mkdir -p /tmp/old_migrations
mv supabase/migrations/old_migration.sql /tmp/old_migrations/

# 2. 새 마이그레이션 배포
supabase db push

# 3. 백업 복원
mv /tmp/old_migrations/* supabase/migrations/
```

**해결책 2**: 충돌하는 마이그레이션 삭제 후 통합
```bash
# 여러 개의 마이그레이션을 하나로 통합
cat migration1.sql migration2.sql > combined_migration.sql
```

---

## Edge Functions 자동 배포

### 개별 함수 배포

```bash
# 1개씩 배포
supabase functions deploy confirm-payment
supabase functions deploy create-subscription
supabase functions deploy process-billing
supabase functions deploy webhook
```

### 전체 함수 일괄 배포

```bash
# supabase/functions/ 아래 모든 함수 배포
supabase functions deploy
```

### 환경변수 자동 설정

```bash
# .env 파일에서 자동으로 읽어서 설정
supabase secrets set \
  TOSS_CLIENT_KEY=test_gck_docs_Ovk5rk1EwkEbP0W43n07xlzm \
  TOSS_SECRET_KEY=test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R

# 주의: SUPABASE_로 시작하는 환경변수는 자동 설정되므로 제외됨
# SUPABASE_SERVICE_ROLE_KEY는 자동으로 사용 가능
```

### GitHub Actions 자동 배포

`.github/workflows/deploy-functions.yml`:
```yaml
name: Deploy Edge Functions

on:
  push:
    branches: [main]
    paths:
      - 'supabase/functions/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Supabase CLI
        uses: supabase/setup-cli@v1

      - name: Link project
        run: supabase link --project-ref ${{ secrets.SUPABASE_PROJECT_REF }}
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}

      - name: Deploy functions
        run: supabase functions deploy

      - name: Set secrets
        run: |
          supabase secrets set \
            TOSS_CLIENT_KEY=${{ secrets.TOSS_CLIENT_KEY }} \
            TOSS_SECRET_KEY=${{ secrets.TOSS_SECRET_KEY }}
```

---

## Cron Job 자동 설정

### Cron Job 등록 (SQL)

```sql
-- 1. Extension 활성화
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 2. 기존 작업 삭제 (멱등성 보장)
SELECT cron.unschedule('daily-subscription-billing')
WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'daily-subscription-billing'
);

-- 3. 새 작업 등록
SELECT cron.schedule(
  'daily-subscription-billing',  -- 작업 이름
  '0 0 * * *',                   -- 매일 자정 UTC
  $$
  SELECT net.http_post(
    url := 'https://eunnaxqjyitxjdkrjaau.supabase.co/functions/v1/process-billing',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY'
    ),
    body := '{}'::jsonb
  );
  $$
);

-- 4. 등록 확인
SELECT * FROM cron.job WHERE jobname = 'daily-subscription-billing';
```

### Cron 표현식

```
┌─────── 분 (0-59)
│ ┌───── 시 (0-23)
│ │ ┌─── 일 (1-31)
│ │ │ ┌─ 월 (1-12)
│ │ │ │ ┌ 요일 (0-6, 0=일요일)
│ │ │ │ │
0 0 * * *  = 매일 자정 UTC (한국시간 09:00)
0 9 * * *  = 매일 09:00 UTC (한국시간 18:00)
0 0 1 * *  = 매달 1일 자정
0 0 * * 1  = 매주 월요일 자정
*/15 * * * * = 15분마다
```

### Cron Job 관리 명령어

```sql
-- 모든 작업 조회
SELECT * FROM cron.job;

-- 작업 실행 이력 조회
SELECT * FROM cron.job_run_details
WHERE jobid = (
  SELECT jobid FROM cron.job
  WHERE jobname = 'daily-subscription-billing'
)
ORDER BY start_time DESC
LIMIT 10;

-- 작업 삭제
SELECT cron.unschedule('daily-subscription-billing');

-- 작업 일시 중지 (삭제 후 재등록으로 구현)
-- PostgreSQL cron에는 pause 기능이 없음
```

---

## 문제 해결

### 1. "relation already exists" 에러

**원인**: 테이블이 이미 존재함

**해결**:
```sql
-- ✅ 이렇게 수정
CREATE TABLE IF NOT EXISTS users (...);

-- ❌ 기존 코드
CREATE TABLE users (...);
```

### 2. "policy already exists" 에러

**원인**: 정책이 이미 존재함

**해결**:
```sql
-- ✅ DO $$ 블록 사용
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'users'
    AND policyname = 'Users can view own data'
  ) THEN
    CREATE POLICY "Users can view own data" ON users ...;
  END IF;
END $$;

-- 또는 기존 정책 삭제 후 재생성
DROP POLICY IF EXISTS "Users can view own data" ON users;
CREATE POLICY "Users can view own data" ON users ...;
```

### 3. "function uuid_generate_v4() does not exist" 에러

**원인**: uuid-ossp extension 미활성화

**해결**:
```sql
-- 방법 1: Extension 활성화 (권장하지 않음)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 방법 2: 내장 함수 사용 (권장)
-- uuid_generate_v4() → gen_random_uuid()로 변경
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
```

### 4. Edge Function 배포 실패

**원인**: 환경변수 누락

**해결**:
```bash
# 환경변수 확인
supabase secrets list

# 환경변수 설정
supabase secrets set TOSS_CLIENT_KEY=xxx TOSS_SECRET_KEY=yyy

# 재배포
supabase functions deploy
```

### 5. Cron Job이 실행되지 않음

**원인 1**: pg_cron extension 미활성화
```sql
CREATE EXTENSION IF NOT EXISTS pg_cron;
```

**원인 2**: 잘못된 cron 표현식
```sql
-- ❌ 잘못된 예
'0 0 0 * * *'  -- 필드가 6개 (초를 포함하면 안됨)

-- ✅ 올바른 예
'0 0 * * *'    -- 필드가 5개
```

**원인 3**: 함수 URL 또는 인증키 오류
```sql
-- URL과 Authorization 키 확인
SELECT net.http_post(
  url := 'https://eunnaxqjyitxjdkrjaau.supabase.co/functions/v1/process-billing',
  headers := jsonb_build_object(
    'Authorization', 'Bearer YOUR_CORRECT_SERVICE_ROLE_KEY'
  ),
  body := '{}'::jsonb
);
```

---

## 자동화 체크리스트

### 최초 설정 (1회만)

- [ ] `supabase login` 실행
- [ ] `supabase link --project-ref eunnaxqjyitxjdkrjaau` 실행
- [ ] 환경변수 설정 (`supabase secrets set`)

### 배포 시 (매번)

- [ ] SQL 마이그레이션 파일 작성 (멱등성 보장)
- [ ] `supabase db push` 실행
- [ ] Edge Functions 수정 시 `supabase functions deploy` 실행
- [ ] Supabase Dashboard에서 테이블/Functions 확인

### CI/CD 설정 (선택)

- [ ] GitHub Actions workflow 파일 작성
- [ ] GitHub Secrets 등록 (SUPABASE_PROJECT_REF, SUPABASE_ACCESS_TOKEN)
- [ ] Push 시 자동 배포 테스트

---

**작성일**: 2026-01-01
**버전**: 1.0.0
