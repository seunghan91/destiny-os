# Supabase Edge Functions 배포 가이드

## 📋 사전 준비

### 1. Supabase CLI 설치

```bash
# Homebrew (macOS)
brew install supabase/tap/supabase

# npm
npm install -g supabase

# 버전 확인
supabase --version
```

### 2. Supabase 프로젝트 생성

1. https://supabase.com 접속
2. 새 프로젝트 생성
3. 프로젝트 URL 및 API 키 확인

### 3. 로컬 프로젝트 초기화

```bash
cd mbti_luck

# Supabase 로그인
supabase login

# 프로젝트 연결
supabase link --project-ref YOUR_PROJECT_REF

# 초기화 확인
supabase status
```

---

## 🔐 환경 변수 설정

### Supabase 대시보드에서 설정

1. Supabase 대시보드 → Settings → Edge Functions
2. Environment variables 섹션

```bash
# 토스페이먼츠 API 키
TOSS_CLIENT_KEY=test_gck_docs_Ovk5rk1EwkEbP0W43n07xlzm  # 테스트 환경
TOSS_SECRET_KEY=test_sk_YOUR_SECRET_KEY_HERE            # 테스트 환경

# 프로덕션 환경
TOSS_CLIENT_KEY=live_gck_YOUR_CLIENT_KEY_HERE           # 라이브 환경
TOSS_SECRET_KEY=live_sk_YOUR_SECRET_KEY_HERE            # 라이브 환경

# 웹훅 서명 검증용 (선택)
TOSS_WEBHOOK_SECRET=your_webhook_secret_here

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
```

### CLI로 설정 (대안)

```bash
# 시크릿 설정
supabase secrets set TOSS_SECRET_KEY=test_sk_YOUR_SECRET_KEY_HERE
supabase secrets set TOSS_CLIENT_KEY=test_gck_YOUR_CLIENT_KEY_HERE

# 시크릿 확인
supabase secrets list
```

---

## 🚀 Edge Functions 배포

### 1. 개별 함수 배포

```bash
# confirm-payment 배포
supabase functions deploy confirm-payment

# create-subscription 배포
supabase functions deploy create-subscription

# process-billing 배포
supabase functions deploy process-billing

# webhook 배포
supabase functions deploy webhook
```

### 2. 모든 함수 한 번에 배포

```bash
# 모든 Edge Functions 배포
supabase functions deploy
```

### 3. 배포 확인

```bash
# 배포된 함수 목록 확인
supabase functions list

# 함수 로그 확인 (실시간)
supabase functions logs confirm-payment --tail
```

---

## 🗄️ 데이터베이스 스키마 설정

### 1. SQL 마이그레이션 생성

```bash
# 새 마이그레이션 파일 생성
supabase migration new payment_tables
```

### 2. 마이그레이션 파일 편집

파일 위치: `supabase/migrations/YYYYMMDDHHMMSS_payment_tables.sql`

```sql
-- 설계 문서의 SQL 복사/붙여넣기
-- (TOSS_PAYMENTS_INTEGRATION.md의 데이터베이스 스키마 섹션 참조)

-- 예시:
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  -- ...
);

-- ... (나머지 테이블)
```

### 3. 마이그레이션 실행

```bash
# 로컬 데이터베이스에 적용
supabase db reset

# 원격 데이터베이스에 적용
supabase db push
```

### 4. 초기 데이터 삽입

```bash
# Supabase 대시보드 → Database → SQL Editor

-- 상품 등록
INSERT INTO products (name, description, product_type, price, features) VALUES
('AI 상담 1회', '사주/MBTI 기반 AI 맞춤 상담', 'single', 3000,
 '["GPT-4o 기반 상담", "개인화된 조언", "24시간 이내 답변"]'::jsonb),

('상세 운세 분석', '2026년 상세 월별 운세 리포트', 'single', 5000,
 '["12개월 상세 분석", "대운 타임라인", "PDF 다운로드"]'::jsonb),

('프리미엄 구독', '모든 기능 무제한 이용', 'subscription', 9900,
 '["무제한 AI 상담", "월별 운세 자동 업데이트", "광고 제거", "우선 지원"]'::jsonb);
```

---

## ⏰ Cron Job 설정 (정기 결제 자동 실행)

### Supabase 대시보드에서 설정

1. Database → Extensions → pg_cron 활성화
2. SQL Editor에서 Cron Job 등록

```sql
-- 매일 자정(KST)에 정기 결제 처리
-- 참고: Supabase는 UTC 기준이므로 한국 시간 00:00 = UTC 15:00 (전날)

SELECT cron.schedule(
  'process-billing-daily',           -- 작업 이름
  '0 15 * * *',                      -- 매일 15:00 UTC (한국 시간 자정)
  $$
  SELECT
    net.http_post(
      url:='https://YOUR_PROJECT_REF.supabase.co/functions/v1/process-billing',
      headers:='{"Content-Type": "application/json", "Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb,
      body:='{}'::jsonb
    ) AS request_id;
  $$
);

-- Cron Job 목록 확인
SELECT * FROM cron.job;

-- Cron Job 삭제 (필요 시)
SELECT cron.unschedule('process-billing-daily');
```

---

## 🌐 웹훅 URL 등록

### 토스페이먼츠 개발자센터

1. https://developers.tosspayments.com 로그인
2. Webhook 메뉴 → 웹훅 등록
3. 웹훅 URL 입력:

```
https://YOUR_PROJECT_REF.supabase.co/functions/v1/webhook
```

4. 이벤트 선택:
   - ✅ PAYMENT_STATUS_CHANGED
   - ✅ DEPOSIT_CALLBACK
   - ✅ CANCEL_STATUS_CHANGED
   - ✅ BILLING_DELETED

5. 테스트 전송 확인

---

## 🧪 테스트

### 1. 로컬 테스트 (개발 환경)

```bash
# Edge Functions 로컬 실행
supabase functions serve

# 다른 터미널에서 테스트
curl -i --location --request POST \
  'http://localhost:54321/functions/v1/confirm-payment' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"paymentKey":"test_key","orderId":"test_order","amount":9900}'
```

### 2. 원격 테스트 (배포 후)

```bash
# confirm-payment 테스트
curl -i --location --request POST \
  'https://YOUR_PROJECT_REF.supabase.co/functions/v1/confirm-payment' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"paymentKey":"test_key","orderId":"test_order","amount":9900}'
```

### 3. Flutter 앱 연동 테스트

```dart
// lib/core/config/supabase_config.dart

final supabase = Supabase.instance.client;

// Edge Function 호출
final response = await supabase.functions.invoke(
  'confirm-payment',
  body: {
    'paymentKey': paymentKey,
    'orderId': orderId,
    'amount': amount,
  },
);

print(response.data);
```

---

## 📊 모니터링 및 로그

### 1. Edge Functions 로그 확인

```bash
# 실시간 로그
supabase functions logs confirm-payment --tail

# 특정 시간대 로그
supabase functions logs confirm-payment --since 1h

# 모든 함수 로그
supabase functions logs --tail
```

### 2. 웹훅 로그 확인

```sql
-- Supabase SQL Editor

-- 최근 웹훅 이벤트
SELECT * FROM webhook_events
ORDER BY created_at DESC
LIMIT 20;

-- 처리 실패한 이벤트
SELECT * FROM webhook_events
WHERE processed = false
ORDER BY created_at DESC;
```

### 3. 결제 통계

```sql
-- 오늘 결제 건수 및 금액
SELECT
  COUNT(*) as payment_count,
  SUM(amount) as total_amount,
  payment_status
FROM payments
WHERE DATE(created_at) = CURRENT_DATE
GROUP BY payment_status;

-- 구독 현황
SELECT
  status,
  COUNT(*) as count
FROM subscriptions
GROUP BY status;
```

---

## 🔄 업데이트 및 롤백

### 함수 업데이트

```bash
# 함수 코드 수정 후 재배포
supabase functions deploy confirm-payment

# 버전 확인
supabase functions list
```

### 데이터베이스 롤백

```bash
# 마이그레이션 롤백 (1단계 이전)
supabase db reset --db-url YOUR_DATABASE_URL

# 특정 마이그레이션까지 롤백
supabase migration repair --status reverted VERSION
```

---

## ⚠️ 주의사항

### 보안
- ❌ **시크릿 키를 Git에 커밋하지 마세요**
- ✅ **환경 변수로만 관리하세요**
- ✅ **프로덕션 배포 전 RLS 정책 확인**

### 성능
- Edge Functions는 **10초 타임아웃** 제한
- 긴 작업은 **비동기 처리** 또는 **백그라운드 작업** 사용

### 비용
- Supabase 무료 플랜: **500K Edge Function 호출/월**
- 초과 시 과금 발생, 대시보드에서 사용량 모니터링

---

## 📚 참고 링크

- [Supabase Edge Functions 공식 문서](https://supabase.com/docs/guides/functions)
- [토스페이먼츠 API 문서](https://docs.tosspayments.com)
- [Supabase CLI 레퍼런스](https://supabase.com/docs/reference/cli/introduction)

---

**배포 완료 체크리스트**:

- [ ] Supabase 프로젝트 생성
- [ ] 환경 변수 설정
- [ ] 데이터베이스 스키마 적용
- [ ] Edge Functions 배포
- [ ] Cron Job 설정
- [ ] 웹훅 URL 등록
- [ ] 테스트 환경 검증
- [ ] 프로덕션 배포
