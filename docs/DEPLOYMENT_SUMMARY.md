# 🚀 Destiny.OS 결제 시스템 배포 완료 요약

## ✅ 완료된 작업

### 1. Supabase 프로젝트 연결 ✅
```bash
supabase link --project-ref eunnaxqjyitxjdkrjaau
```
- 기존 프로젝트 활용 (새로 생성하지 않음)
- Project URL: https://eunnaxqjyitxjdkrjaau.supabase.co

---

### 2. 환경변수 설정 ✅
```bash
supabase secrets set \
  TOSS_CLIENT_KEY=test_gck_docs_Ovk5rk1EwkEbP0W43n07xlzm \
  TOSS_SECRET_KEY=test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R
```
- 토스페이먼츠 테스트 키 등록 완료
- SUPABASE_SERVICE_ROLE_KEY는 자동으로 사용 가능

---

### 3. Edge Functions 배포 ✅

4개 함수 자동 배포 완료:

| 함수명 | 용도 | 크기 | 상태 |
|--------|------|------|------|
| **confirm-payment** | 결제 승인 | 67.96kB | ✅ 배포 완료 |
| **create-subscription** | 구독 생성 | 68.27kB | ✅ 배포 완료 |
| **process-billing** | 정기 결제 처리 | 69.16kB | ✅ 배포 완료 |
| **webhook** | 웹훅 수신 | 497.1kB | ✅ 배포 완료 |

**배포 명령어**:
```bash
supabase functions deploy confirm-payment
supabase functions deploy create-subscription
supabase functions deploy process-billing
supabase functions deploy webhook
```

**확인 URL**: https://supabase.com/dashboard/project/eunnaxqjyitxjdkrjaau/functions

---

### 4. 데이터베이스 마이그레이션 자동 실행 ✅

**실행된 마이그레이션**:
- `20260101000500_payment_system.sql` (통합 마이그레이션)

**생성된 테이블**:
1. ✅ **users** - 사용자 정보 및 구독 상태
2. ✅ **products** - 상품 목록 (초기 데이터 3개 포함)
3. ✅ **payments** - 결제 내역
4. ✅ **subscriptions** - 구독 정보
5. ✅ **subscription_payments** - 구독 결제 기록
6. ✅ **webhook_events** - 웹훅 로그

**배포 명령어**:
```bash
echo "Y" | supabase db push
```

**자동화 문제 해결**:
- ❌ **문제**: 기존 마이그레이션과 충돌 (policy already exists)
- ✅ **해결**: 기존 파일 임시 백업 → 새 파일만 push → 복원
- ❌ **문제**: UUID 함수 에러 (uuid_generate_v4 does not exist)
- ✅ **해결**: `gen_random_uuid()` 내장 함수로 변경

---

### 5. Cron Job 자동 설정 ✅

**등록된 작업**:
- **이름**: `daily-subscription-billing`
- **스케줄**: `0 0 * * *` (매일 자정 UTC = 한국시간 09:00)
- **동작**: `process-billing` 함수 자동 호출

**확인 방법**:
```sql
SELECT * FROM cron.job WHERE jobname = 'daily-subscription-billing';
```

---

### 6. 문서 작성 완료 ✅

| 문서명 | 경로 | 용도 |
|--------|------|------|
| **통합 가이드** | `docs/TOSS_PAYMENTS_INTEGRATION.md` | 전체 통합 설계 |
| **환경 가이드** | `docs/TOSS_PAYMENTS_ENVIRONMENT_GUIDE.md` | 테스트/라이브 환경 |
| **배포 가이드** | `supabase/DEPLOYMENT_GUIDE.md` | Edge Functions 배포 |
| **프로젝트 설정** | `supabase/SUPABASE_PROJECT_SETUP.md` | Supabase 초기 설정 |
| **자동화 가이드** | `supabase/AUTOMATION_GUIDE.md` | ⭐ 자동화 완벽 가이드 |
| **웹훅 등록** | `docs/WEBHOOK_REGISTRATION_GUIDE.md` | ⭐ 웹훅 수동 등록 방법 |
| **배포 요약** | `docs/DEPLOYMENT_SUMMARY.md` | 이 문서 |

---

## ⏳ 수동 작업 필요 (API 지원 안됨)

### 토스페이먼츠 웹훅 URL 등록

**이유**: 토스페이먼츠는 웹훅 등록 API를 제공하지 않음

**등록 방법**:
1. https://developers.tosspayments.com/ 로그인
2. 좌측 **"웹훅(Webhook)"** 메뉴 클릭
3. **"웹훅 등록하기"** 클릭
4. 정보 입력:
   - **웹훅 이름**: `Destiny.OS 결제 웹훅`
   - **웹훅 URL**: `https://eunnaxqjyitxjdkrjaau.supabase.co/functions/v1/webhook`
   - **이벤트**: 모두 선택 (6개)
5. **"등록하기"** 클릭

**상세 가이드**: `docs/WEBHOOK_REGISTRATION_GUIDE.md` 참조

---

## 🎯 다음 단계 (Flutter 앱 개발)

### 1. Flutter 패키지 설치
```yaml
dependencies:
  supabase_flutter: ^2.0.0
  tosspayments_widget: ^1.0.0  # 토스페이먼츠 Flutter SDK
  flutter_bloc: ^8.1.0
```

### 2. Supabase 초기화
```dart
await Supabase.initialize(
  url: dotenv.env['SUPABASE_URL']!,
  anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
);
```

### 3. 결제 플로우 구현

#### 단건 결제 (AI 상담, 운세 분석)
```dart
// 1. 결제 위젯 띄우기
final result = await TossPayments.requestPayment(
  amount: 3000,
  orderId: 'order_${DateTime.now().millisecondsSinceEpoch}',
  orderName: 'AI 상담 1회',
  successUrl: 'myapp://payment/success',
  failUrl: 'myapp://payment/fail',
);

// 2. 승인 API 호출 (Edge Function)
final response = await supabase.functions.invoke(
  'confirm-payment',
  body: {
    'paymentKey': result.paymentKey,
    'orderId': result.orderId,
    'amount': result.amount,
  },
);
```

#### 구독 결제 (프리미엄)
```dart
// 1. 빌링키 발급
final billingKey = await TossPayments.issueBillingKey(
  customerKey: 'user_${userId}',
);

// 2. 구독 생성 (Edge Function)
final response = await supabase.functions.invoke(
  'create-subscription',
  body: {
    'userId': userId,
    'productId': productId,
    'billingKey': billingKey,
  },
);
```

---

## 🧪 테스트 시나리오

### 1. 단건 결제 테스트
- [ ] 상품 목록 조회 (products 테이블)
- [ ] 결제 위젯 띄우기
- [ ] 테스트 카드로 결제 (토스페이먼츠 제공)
- [ ] 결제 승인 API 호출 성공
- [ ] payments 테이블에 데이터 저장 확인
- [ ] webhook_events 테이블에 로그 확인

**테스트 카드 정보**:
```
카드번호: 4214-2120-0000-0003
유효기간: 12/29
CVC: 123
비밀번호: 앞 2자리 12
```

### 2. 구독 결제 테스트
- [ ] 빌링키 발급
- [ ] 구독 생성 API 호출
- [ ] subscriptions 테이블에 데이터 저장 확인
- [ ] 첫 결제 성공 확인
- [ ] Cron job 실행 확인 (다음날 자정)
- [ ] 정기 결제 성공 확인

### 3. 웹훅 테스트
- [ ] 결제 상태 변경 시 웹훅 수신
- [ ] webhook_events 테이블에 로그 저장
- [ ] 10초 이내 200 응답 확인
- [ ] 서명 검증 성공

---

## 📊 모니터링 및 로그 확인

### Supabase Dashboard

**Tables** (데이터 확인):
- https://supabase.com/dashboard/project/eunnaxqjyitxjdkrjaau/editor

**Functions** (로그 확인):
- https://supabase.com/dashboard/project/eunnaxqjyitxjdkrjaau/functions

**Logs** (실시간 모니터링):
- https://supabase.com/dashboard/project/eunnaxqjyitxjdkrjaau/logs

### SQL로 확인

```sql
-- 최근 결제 내역
SELECT * FROM payments
ORDER BY created_at DESC
LIMIT 10;

-- 활성 구독
SELECT * FROM subscriptions
WHERE status = 'ACTIVE'
ORDER BY created_at DESC;

-- 웹훅 로그
SELECT * FROM webhook_events
ORDER BY created_at DESC
LIMIT 20;

-- Cron job 실행 이력
SELECT * FROM cron.job_run_details
WHERE jobid = (
  SELECT jobid FROM cron.job
  WHERE jobname = 'daily-subscription-billing'
)
ORDER BY start_time DESC
LIMIT 10;
```

---

## 🔒 보안 체크리스트

### 환경변수 관리
- ✅ `.env` 파일을 `.gitignore`에 추가
- ✅ Service Role Key는 서버에서만 사용
- ✅ Anon Key만 Flutter 앱에 포함
- ⚠️ 프로덕션 배포 시 라이브 키로 교체 필요

### API 보안
- ✅ RLS (Row Level Security) 활성화
- ✅ 사용자는 자신의 데이터만 조회 가능
- ✅ Edge Functions에서 결제 검증
- ✅ 웹훅 서명 검증 구현

### 결제 보안
- ✅ 금액 검증 (DB 금액과 비교)
- ✅ 중복 결제 방지 (payment_key 중복 체크)
- ✅ 웹훅 멱등성 보장
- ✅ 10초 내 응답 (타임아웃 방지)

---

## 🚨 알려진 이슈 및 해결 방법

### 이슈 1: SQL 마이그레이션 충돌
**증상**: "policy already exists" 에러

**원인**: 기존 마이그레이션과 중복된 정책 생성

**해결**:
```sql
-- ❌ 잘못된 코드
CREATE POLICY "policy_name" ...;

-- ✅ 올바른 코드
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'table_name'
    AND policyname = 'policy_name'
  ) THEN
    CREATE POLICY "policy_name" ...;
  END IF;
END $$;
```

### 이슈 2: UUID 함수 에러
**증상**: "function uuid_generate_v4() does not exist"

**원인**: uuid-ossp extension 미활성화

**해결**:
```sql
-- 방법 1: Extension 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 방법 2: 내장 함수 사용 (권장)
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
```

### 이슈 3: Cron Job 실행 안됨
**증상**: 정기 결제가 자동 실행되지 않음

**원인**: pg_cron extension 미활성화 또는 잘못된 cron 표현식

**해결**:
```sql
-- 1. Extension 확인
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 2. Cron 표현식 확인 (5개 필드)
'0 0 * * *'  -- ✅ 올바름
'0 0 0 * * *'  -- ❌ 잘못됨 (필드 6개)

-- 3. 실행 이력 확인
SELECT * FROM cron.job_run_details
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'daily-subscription-billing')
ORDER BY start_time DESC;
```

---

## 📚 참고 문서

### 토스페이먼츠
- [공식 문서](https://docs.tosspayments.com/)
- [환경 가이드](https://docs.tosspayments.com/guides/environment)
- [웹훅 가이드](https://docs.tosspayments.com/guides/v2/webhook)

### Supabase
- [Edge Functions](https://supabase.com/docs/guides/functions)
- [Database](https://supabase.com/docs/guides/database)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)

### 프로젝트 문서
- [자동화 가이드](../supabase/AUTOMATION_GUIDE.md) ⭐
- [웹훅 등록 가이드](./WEBHOOK_REGISTRATION_GUIDE.md) ⭐
- [통합 가이드](./TOSS_PAYMENTS_INTEGRATION.md)

---

## ✅ 최종 체크리스트

### 백엔드 (완료)
- [x] Supabase 프로젝트 연결
- [x] 환경변수 설정
- [x] Edge Functions 배포 (4개)
- [x] SQL 마이그레이션 자동 실행
- [x] Cron Job 자동 설정
- [x] 자동화 문서 작성

### 수동 작업 (필요)
- [ ] 토스페이먼츠 개발자센터 웹훅 URL 등록

### 프론트엔드 (다음 단계)
- [ ] Flutter 패키지 설치
- [ ] Supabase 초기화
- [ ] 결제 플로우 구현
- [ ] 구독 플로우 구현
- [ ] 테스트 시나리오 실행

---

**작성일**: 2026-01-01
**배포 완료 시각**: 자동화 완료
**버전**: 1.0.0

**🎉 축하합니다! 백엔드 결제 시스템 배포가 완료되었습니다!**
