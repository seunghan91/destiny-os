# 토스페이먼츠 연동 설계 문서

## 📋 목차

1. [개요](#개요)
2. [아키텍처 설계](#아키텍처-설계)
3. [데이터베이스 스키마](#데이터베이스-스키마)
4. [결제 흐름](#결제-흐름)
5. [구독 결제 시스템](#구독-결제-시스템)
6. [보안 설계](#보안-설계)
7. [구현 가이드](#구현-가이드)
8. [테스트 계획](#테스트-계획)

---

## 개요

### 프로젝트 정보
- **서비스명**: Destiny.OS (MBTI 운세 앱)
- **결제 방식**:
  - 단건 결제 (상세 운세 분석: 3,000원 ~ 5,000원)
  - 정기 구독 (프리미엄: 월 9,900원)
- **결제 제공자**: 토스페이먼츠 (Toss Payments)
- **백엔드**: Supabase (PostgreSQL + Edge Functions)
- **프론트엔드**: Flutter 3.10+

### 주요 기능
- 🔮 AI 상담 추가 결제 (1회 무료 후 유료)
- 📊 상세 운세 분석 리포트 구매
- 💳 프리미엄 구독 (월간 자동결제)
- 💕 궁합 분석 추가 구매

---

## 아키텍처 설계

### 시스템 구성도

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Payment UI   │  │ Subscription │  │ Purchase     │  │
│  │ (Widget SDK) │  │ Management   │  │ History      │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                            ↓
                   ┌────────────────┐
                   │ Supabase Edge  │
                   │   Functions    │
                   └────────────────┘
                   ↓               ↓
        ┌──────────────┐   ┌──────────────┐
        │ Toss Payments│   │  PostgreSQL  │
        │     API      │   │   Database   │
        └──────────────┘   └──────────────┘
```

### 레이어 구조 (Clean Architecture)

```
lib/
├── features/
│   └── payment/
│       ├── presentation/
│       │   ├── pages/
│       │   │   ├── payment_page.dart
│       │   │   ├── subscription_page.dart
│       │   │   └── purchase_history_page.dart
│       │   ├── widgets/
│       │   │   ├── toss_payment_widget.dart
│       │   │   ├── payment_method_selector.dart
│       │   │   └── subscription_card.dart
│       │   └── bloc/
│       │       ├── payment_bloc.dart
│       │       ├── payment_event.dart
│       │       └── payment_state.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── payment.dart
│       │   │   ├── subscription.dart
│       │   │   └── product.dart
│       │   ├── repositories/
│       │   │   └── payment_repository.dart
│       │   └── usecases/
│       │       ├── process_payment.dart
│       │       ├── create_subscription.dart
│       │       ├── cancel_subscription.dart
│       │       └── get_payment_history.dart
│       └── data/
│           ├── models/
│           │   ├── payment_model.dart
│           │   ├── subscription_model.dart
│           │   └── toss_payment_response.dart
│           ├── datasources/
│           │   ├── toss_payment_remote_datasource.dart
│           │   └── payment_local_datasource.dart
│           └── repositories/
│               └── payment_repository_impl.dart
```

---

## 데이터베이스 스키마

### Supabase PostgreSQL 테이블 설계

```sql
-- 1. 사용자 테이블 (확장)
ALTER TABLE users
ADD COLUMN subscription_tier VARCHAR(20) DEFAULT 'free',
ADD COLUMN subscription_status VARCHAR(20) DEFAULT 'inactive',
ADD COLUMN billing_key TEXT,
ADD COLUMN subscription_started_at TIMESTAMP,
ADD COLUMN subscription_expires_at TIMESTAMP;

-- 2. 상품 테이블
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  description TEXT,
  product_type VARCHAR(20) NOT NULL, -- 'single', 'subscription'
  price INTEGER NOT NULL, -- 원화 금액 (KRW)
  currency VARCHAR(3) DEFAULT 'KRW',
  features JSONB, -- 상품 특징 (JSON 배열)
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 3. 결제 내역 테이블
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),

  -- 토스페이먼츠 정보
  payment_key VARCHAR(200) UNIQUE NOT NULL,
  order_id VARCHAR(100) UNIQUE NOT NULL,
  order_name VARCHAR(100) NOT NULL,

  -- 결제 정보
  amount INTEGER NOT NULL,
  currency VARCHAR(3) DEFAULT 'KRW',
  payment_method VARCHAR(50), -- 'CARD', 'VIRTUAL_ACCOUNT', etc.
  payment_status VARCHAR(20) NOT NULL, -- 'PENDING', 'DONE', 'CANCELED', 'FAILED'

  -- 타임스탬프
  requested_at TIMESTAMP DEFAULT NOW(),
  approved_at TIMESTAMP,
  canceled_at TIMESTAMP,

  -- 추가 정보
  failure_code VARCHAR(50),
  failure_message TEXT,
  receipt_url TEXT,
  metadata JSONB, -- 추가 정보 (flexible)

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 4. 구독 내역 테이블
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),

  -- 빌링키 정보
  billing_key TEXT NOT NULL,
  customer_key VARCHAR(100) NOT NULL,

  -- 구독 상태
  status VARCHAR(20) NOT NULL, -- 'ACTIVE', 'PAUSED', 'CANCELED', 'EXPIRED'
  tier VARCHAR(20) NOT NULL, -- 'premium', 'pro'

  -- 구독 기간
  started_at TIMESTAMP NOT NULL,
  current_period_start TIMESTAMP NOT NULL,
  current_period_end TIMESTAMP NOT NULL,
  canceled_at TIMESTAMP,

  -- 결제 정보
  billing_cycle VARCHAR(20) DEFAULT 'monthly', -- 'monthly', 'yearly'
  next_billing_date TIMESTAMP,
  amount INTEGER NOT NULL,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 5. 구독 결제 내역 테이블
CREATE TABLE subscription_payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  subscription_id UUID REFERENCES subscriptions(id) ON DELETE CASCADE,
  payment_id UUID REFERENCES payments(id),

  billing_date TIMESTAMP NOT NULL,
  amount INTEGER NOT NULL,
  status VARCHAR(20) NOT NULL, -- 'SUCCESS', 'FAILED', 'PENDING'

  created_at TIMESTAMP DEFAULT NOW()
);

-- 6. 웹훅 이벤트 로그 테이블
CREATE TABLE webhook_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_type VARCHAR(50) NOT NULL,
  payment_key VARCHAR(200),

  payload JSONB NOT NULL,
  processed BOOLEAN DEFAULT false,
  processed_at TIMESTAMP,

  created_at TIMESTAMP DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_status ON payments(payment_status);
CREATE INDEX idx_payments_payment_key ON payments(payment_key);
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_next_billing ON subscriptions(next_billing_date);

-- Row Level Security (RLS) 설정
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_payments ENABLE ROW LEVEL SECURITY;

-- RLS 정책: 사용자는 자신의 결제 정보만 조회 가능
CREATE POLICY "Users can view own payments"
  ON payments FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view own subscriptions"
  ON subscriptions FOR SELECT
  USING (auth.uid() = user_id);
```

### 초기 상품 데이터

```sql
-- 상품 등록 (예시)
INSERT INTO products (name, description, product_type, price, features) VALUES
('AI 상담 1회', '사주/MBTI 기반 AI 맞춤 상담', 'single', 3000,
 '["GPT-4o 기반 상담", "개인화된 조언", "24시간 이내 답변"]'::jsonb),

('상세 운세 분석', '2026년 상세 월별 운세 리포트', 'single', 5000,
 '["12개월 상세 분석", "대운 타임라인", "PDF 다운로드"]'::jsonb),

('프리미엄 구독', '모든 기능 무제한 이용', 'subscription', 9900,
 '["무제한 AI 상담", "월별 운세 자동 업데이트", "광고 제거", "우선 지원"]'::jsonb);
```

---

## 결제 흐름

### 1. 일반 결제 (Single Payment) 흐름

```
┌─────────────┐
│   사용자    │
└─────────────┘
      │
      │ 1. 상품 선택 (AI 상담, 상세 분석 등)
      ▼
┌─────────────┐
│ Flutter App │
└─────────────┘
      │ 2. 결제 요청 (주문 생성)
      ▼
┌──────────────────┐
│ Edge Function:   │
│ create-payment   │
└──────────────────┘
      │ 3. 주문 정보 저장 (DB)
      │    - orderId, amount 임시 저장
      ▼
┌─────────────┐
│ PostgreSQL  │
└─────────────┘
      │
      │ 4. clientKey, orderId 반환
      ▼
┌─────────────┐
│ Flutter App │
│ (토스 위젯) │
└─────────────┘
      │ 5. 결제위젯 렌더링
      │    - 결제 수단 선택
      │    - 약관 동의
      │    - requestPayment() 호출
      ▼
┌──────────────┐
│ Toss Payments│
│   (인증)     │
└──────────────┘
      │ 6. 카드사 AppCard 본인인증
      │
      │ 7. 성공 시 successUrl로 리다이렉트
      │    (paymentKey, orderId, amount 포함)
      ▼
┌──────────────────┐
│ Edge Function:   │
│ confirm-payment  │
└──────────────────┘
      │ 8. 금액 검증
      │    - DB의 초기 금액 vs 반환된 금액 비교
      │
      │ 9. 토스 결제 승인 API 호출
      │    POST /payments/confirm
      │    Body: { paymentKey, orderId, amount }
      │    Header: Authorization: Basic {시크릿키}
      ▼
┌──────────────┐
│ Toss Payments│
│   (승인)     │
└──────────────┘
      │ 10. 승인 완료
      ▼
┌──────────────────┐
│ Edge Function    │
└──────────────────┘
      │ 11. 결제 정보 DB 저장
      │     - status: 'DONE'
      │     - approved_at 기록
      │     - receipt_url 저장
      ▼
┌─────────────┐
│ PostgreSQL  │
└─────────────┘
      │
      │ 12. 성공 응답
      ▼
┌─────────────┐
│ Flutter App │
│ (완료 화면) │
└─────────────┘
```

### 2. 구독 결제 (Subscription) 흐름

```
[초회 결제 - 빌링키 발급]

사용자 → Flutter App → Edge Function → Toss Payments
                            ↓
                      (빌링키 발급)
                            ↓
                   PostgreSQL 저장
                   (subscriptions 테이블)

[정기 결제 - 자동 청구]

┌──────────────────┐
│  Cron Job        │
│  (매일 자정 실행) │
└──────────────────┘
      │
      │ 1. next_billing_date가 오늘인 구독 조회
      ▼
┌──────────────────┐
│ Edge Function:   │
│ process-billing  │
└──────────────────┘
      │ 2. 각 구독마다 반복
      │    - billing_key 조회
      │    - 자동 결제 요청
      ▼
┌──────────────┐
│ Toss Payments│
│ (빌링 API)   │
└──────────────┘
      │ 3. 결제 처리
      ▼
┌──────────────────┐
│ Edge Function    │
└──────────────────┘
      │ 4. 결제 성공 시
      │    - payments 테이블 저장
      │    - subscription_payments 기록
      │    - next_billing_date 갱신 (+1개월)
      │    - current_period_end 갱신
      │
      │ 5. 결제 실패 시
      │    - 재시도 로직 (3회)
      │    - 실패 시 이메일 알림
      │    - status: 'PAUSED'
      ▼
┌─────────────┐
│ PostgreSQL  │
└─────────────┘
```

---

## 구독 결제 시스템

### 구독 상태 관리

```dart
enum SubscriptionStatus {
  active,    // 정상 활성
  paused,    // 일시 중지 (결제 실패 등)
  canceled,  // 사용자가 취소
  expired,   // 만료됨
}

enum SubscriptionTier {
  free,      // 무료
  premium,   // 프리미엄 (월 9,900원)
}
```

### 빌링키 발급 (Initial Subscription)

```dart
// presentation/bloc/payment_bloc.dart

Future<void> _onSubscribeRequested(
  SubscribeRequested event,
  Emitter<PaymentState> emit,
) async {
  emit(PaymentLoading());

  try {
    // 1. 고객 키 생성
    final customerKey = 'customer_${userId}_${DateTime.now().millisecondsSinceEpoch}';

    // 2. 결제위젯 초기화 및 결제 요청
    final paymentResult = await _processPaymentUseCase(
      PaymentParams(
        amount: event.subscriptionPrice,
        orderName: '${event.tier} 구독',
        customerKey: customerKey,
      ),
    );

    // 3. 빌링키 발급 요청 (Edge Function)
    final subscription = await _createSubscriptionUseCase(
      SubscriptionParams(
        paymentKey: paymentResult.paymentKey,
        customerKey: customerKey,
        tier: event.tier,
      ),
    );

    emit(SubscriptionSuccess(subscription));
  } catch (e) {
    emit(PaymentFailure(e.toString()));
  }
}
```

### Edge Function: 빌링키 발급 및 저장

```typescript
// supabase/functions/create-subscription/index.ts

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  try {
    const { paymentKey, customerKey, tier } = await req.json();

    // 1. 토스페이먼츠 빌링키 발급 API 호출
    const tossResponse = await fetch(
      `https://api.tosspayments.com/v1/billing/authorizations/${paymentKey}`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${btoa(Deno.env.get('TOSS_SECRET_KEY') + ':')}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          customerKey,
        }),
      }
    );

    if (!tossResponse.ok) {
      throw new Error('빌링키 발급 실패');
    }

    const billingData = await tossResponse.json();
    const billingKey = billingData.billingKey;

    // 2. Supabase DB에 저장
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    );

    const userId = req.headers.get('user-id'); // 인증 헤더에서 추출
    const productId = tier === 'premium'
      ? 'premium-product-uuid'
      : 'pro-product-uuid';

    const now = new Date();
    const nextBillingDate = new Date(now);
    nextBillingDate.setMonth(nextBillingDate.getMonth() + 1);

    const { data: subscription, error } = await supabase
      .from('subscriptions')
      .insert({
        user_id: userId,
        product_id: productId,
        billing_key: billingKey,
        customer_key: customerKey,
        status: 'ACTIVE',
        tier: tier,
        started_at: now.toISOString(),
        current_period_start: now.toISOString(),
        current_period_end: nextBillingDate.toISOString(),
        next_billing_date: nextBillingDate.toISOString(),
        amount: tier === 'premium' ? 9900 : 19900,
        billing_cycle: 'monthly',
      })
      .select()
      .single();

    if (error) throw error;

    // 3. users 테이블 업데이트
    await supabase
      .from('users')
      .update({
        subscription_tier: tier,
        subscription_status: 'active',
        billing_key: billingKey,
        subscription_started_at: now.toISOString(),
        subscription_expires_at: nextBillingDate.toISOString(),
      })
      .eq('id', userId);

    return new Response(
      JSON.stringify({ success: true, subscription }),
      { headers: { 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
```

### Edge Function: 정기 결제 자동 청구

```typescript
// supabase/functions/process-billing/index.ts

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '' // Service Role Key 사용
    );

    // 1. 오늘 결제해야 할 구독 조회
    const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD

    const { data: subscriptions, error: fetchError } = await supabase
      .from('subscriptions')
      .select('*')
      .eq('status', 'ACTIVE')
      .lte('next_billing_date', today);

    if (fetchError) throw fetchError;

    const results = [];

    // 2. 각 구독마다 자동 결제 처리
    for (const subscription of subscriptions) {
      try {
        // 2-1. 빌링키로 결제 요청
        const orderId = `subscription_${subscription.id}_${Date.now()}`;

        const tossResponse = await fetch(
          'https://api.tosspayments.com/v1/billing/' + subscription.billing_key,
          {
            method: 'POST',
            headers: {
              'Authorization': `Basic ${btoa(Deno.env.get('TOSS_SECRET_KEY') + ':')}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              customerKey: subscription.customer_key,
              amount: subscription.amount,
              orderId: orderId,
              orderName: `${subscription.tier} 구독 - ${today}`,
            }),
          }
        );

        const paymentData = await tossResponse.json();

        if (!tossResponse.ok) {
          throw new Error(paymentData.message || '결제 실패');
        }

        // 2-2. 결제 성공 시 DB 업데이트
        // payments 테이블에 저장
        const { data: payment } = await supabase
          .from('payments')
          .insert({
            user_id: subscription.user_id,
            product_id: subscription.product_id,
            payment_key: paymentData.paymentKey,
            order_id: orderId,
            order_name: `${subscription.tier} 구독`,
            amount: subscription.amount,
            payment_method: paymentData.method,
            payment_status: 'DONE',
            approved_at: new Date().toISOString(),
            receipt_url: paymentData.receiptUrl,
          })
          .select()
          .single();

        // subscription_payments 기록
        await supabase
          .from('subscription_payments')
          .insert({
            subscription_id: subscription.id,
            payment_id: payment.id,
            billing_date: today,
            amount: subscription.amount,
            status: 'SUCCESS',
          });

        // 다음 결제일 갱신 (+1개월)
        const nextBillingDate = new Date(subscription.next_billing_date);
        nextBillingDate.setMonth(nextBillingDate.getMonth() + 1);

        await supabase
          .from('subscriptions')
          .update({
            current_period_start: subscription.current_period_end,
            current_period_end: nextBillingDate.toISOString(),
            next_billing_date: nextBillingDate.toISOString(),
          })
          .eq('id', subscription.id);

        results.push({
          subscription_id: subscription.id,
          status: 'success'
        });

      } catch (error) {
        // 2-3. 결제 실패 시 처리
        console.error(`구독 ${subscription.id} 결제 실패:`, error);

        // subscription_payments 실패 기록
        await supabase
          .from('subscription_payments')
          .insert({
            subscription_id: subscription.id,
            billing_date: today,
            amount: subscription.amount,
            status: 'FAILED',
          });

        // 재시도 로직 (3회 실패 시 PAUSED)
        // TODO: 재시도 카운터 구현

        results.push({
          subscription_id: subscription.id,
          status: 'failed',
          error: error.message
        });
      }
    }

    return new Response(
      JSON.stringify({
        processed: subscriptions.length,
        results
      }),
      { headers: { 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
```

---

## 보안 설계

### 1. 시크릿 키 관리

**절대 규칙**:
- ❌ **Flutter 앱에 시크릿 키 포함 금지**
- ❌ **Git 커밋 금지**
- ✅ **Supabase Edge Functions 환경 변수로만 사용**

```bash
# Supabase 대시보드에서 설정
# Settings > Edge Functions > Environment variables

TOSS_CLIENT_KEY=test_gck_docs_Ovk5rk1EwkEbP0W43n07xlzm  # 공개 가능
TOSS_SECRET_KEY=test_sk_D5GePWvyJnrK0W0k6q8gLzN97Eoq  # 절대 비공개
```

### 2. 금액 검증 (Amount Validation)

**공격 시나리오 방지**:
- 클라이언트에서 금액 조작 시도 차단
- DB에 임시 저장된 금액과 반환된 금액 비교

```typescript
// Edge Function: confirm-payment
async function validatePaymentAmount(orderId: string, amount: number): Promise<boolean> {
  const { data } = await supabase
    .from('payments')
    .select('amount')
    .eq('order_id', orderId)
    .single();

  if (!data || data.amount !== amount) {
    throw new Error('결제 금액 불일치: 조작 의심');
  }

  return true;
}
```

### 3. 멱등성 보장 (Idempotency)

**중복 결제 방지**:

```typescript
// Edge Function에서 멱등성 체크
async function checkIdempotency(paymentKey: string): Promise<boolean> {
  const { data } = await supabase
    .from('payments')
    .select('payment_status')
    .eq('payment_key', paymentKey)
    .single();

  if (data && data.payment_status === 'DONE') {
    // 이미 승인된 결제
    return false; // 중복 처리 차단
  }

  return true; // 처리 가능
}
```

### 4. Row Level Security (RLS)

**데이터 접근 제어**:

```sql
-- 사용자는 자신의 결제 정보만 조회 가능
CREATE POLICY "Users can view own payments"
  ON payments FOR SELECT
  USING (auth.uid() = user_id);

-- 관리자는 모든 결제 조회 가능
CREATE POLICY "Admins can view all payments"
  ON payments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );
```

### 5. 웹훅 서명 검증

**웹훅 위조 방지**:

```typescript
// 토스페이먼츠 웹훅 서명 검증
import { createHmac } from 'https://deno.land/std@0.168.0/node/crypto.ts';

function verifyWebhookSignature(
  payload: string,
  signature: string,
  secret: string
): boolean {
  const computedSignature = createHmac('sha256', secret)
    .update(payload)
    .digest('hex');

  return computedSignature === signature;
}
```

---

## 구현 가이드

### 1. Flutter 패키지 설치

```yaml
# pubspec.yaml
dependencies:
  # 토스페이먼츠 위젯 SDK
  tosspayments_widget_sdk_flutter: ^2.1.2

  # Supabase
  supabase_flutter: ^2.8.3

  # 상태 관리
  flutter_bloc: ^9.1.1

  # 의존성 주입
  get_it: ^8.0.3
```

### 2. Android 설정

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
  <application
    android:usesCleartextTraffic="true">
    <!-- AppCard 앱 실행을 위한 설정 -->
  </application>

  <uses-permission android:name="android.permission.INTERNET" />
</manifest>
```

```gradle
// android/app/build.gradle
android {
  defaultConfig {
    minSdkVersion 19  // 최소 요구사항
  }
}
```

### 3. iOS 설정

```xml
<!-- ios/Runner/Info.plist -->
<dict>
  <key>NSAppTransportSecurity</key>
  <dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
  </dict>

  <!-- 카드사 앱 URL Scheme -->
  <key>LSApplicationQueriesSchemes</key>
  <array>
    <string>hdcardappcardansimclick</string>
    <string>smhyundaiansimclick</string>
    <!-- 기타 카드사 앱... -->
  </array>
</dict>
```

### 4. Flutter 결제 위젯 구현

```dart
// presentation/widgets/toss_payment_widget.dart

import 'package:flutter/material.dart';
import 'package:tosspayments_widget_sdk_flutter/tosspayments_widget_sdk_flutter.dart';

class TossPaymentWidget extends StatefulWidget {
  final int amount;
  final String orderName;
  final String customerKey;
  final Function(PaymentResult) onSuccess;
  final Function(PaymentResult) onFail;

  const TossPaymentWidget({
    Key? key,
    required this.amount,
    required this.orderName,
    required this.customerKey,
    required this.onSuccess,
    required this.onFail,
  }) : super(key: key);

  @override
  State<TossPaymentWidget> createState() => _TossPaymentWidgetState();
}

class _TossPaymentWidgetState extends State<TossPaymentWidget> {
  late PaymentWidget _paymentWidget;
  PaymentMethodWidgetControl? _paymentMethodWidgetControl;
  AgreementWidgetControl? _agreementWidgetControl;

  @override
  void initState() {
    super.initState();
    _initializePaymentWidget();
  }

  void _initializePaymentWidget() {
    _paymentWidget = PaymentWidget(
      clientKey: 'test_gck_docs_Ovk5rk1EwkEbP0W43n07xlzm', // 클라이언트 키
      customerKey: widget.customerKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('결제하기')),
      body: Column(
        children: [
          // 결제 금액 표시
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '결제 금액: ${widget.amount.toStringAsFixed(0)}원',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // 결제 수단 선택 UI
          Expanded(
            child: PaymentMethodWidget(
              paymentWidget: _paymentWidget,
              selector: 'payment-method', // HTML selector ID
              amount: Amount(
                value: widget.amount,
                currency: 'KRW',
                country: 'KR',
              ),
              onLoadEnd: (control) {
                setState(() {
                  _paymentMethodWidgetControl = control;
                });
              },
            ),
          ),

          // 약관 동의 UI
          AgreementWidget(
            paymentWidget: _paymentWidget,
            selector: 'agreement',
            onLoadEnd: (control) {
              setState(() {
                _agreementWidgetControl = control;
              });
            },
          ),

          // 결제하기 버튼
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _requestPayment,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('결제하기'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPayment() async {
    // 약관 동의 확인
    final agreementStatus = await _agreementWidgetControl?.getAgreementStatus();
    if (agreementStatus != null && !agreementStatus) {
      _showDialog('필수 약관에 동의해주세요.');
      return;
    }

    // 결제 요청
    final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';

    final result = await _paymentWidget.requestPayment(
      paymentInfo: PaymentInfo(
        orderId: orderId,
        orderName: widget.orderName,
      ),
    );

    if (result.success != null) {
      widget.onSuccess(result);
    } else if (result.fail != null) {
      widget.onFail(result);
    }
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
```

### 5. 결제 BLoC 구현

```dart
// presentation/bloc/payment_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tosspayments_widget_sdk_flutter/model/payment_result.dart';

// Events
abstract class PaymentEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class PaymentRequested extends PaymentEvent {
  final PaymentResult result;
  PaymentRequested(this.result);

  @override
  List<Object?> get props => [result];
}

class SubscribeRequested extends PaymentEvent {
  final String tier;
  final int subscriptionPrice;

  SubscribeRequested({
    required this.tier,
    required this.subscriptionPrice,
  });

  @override
  List<Object?> get props => [tier, subscriptionPrice];
}

// States
abstract class PaymentState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}
class PaymentLoading extends PaymentState {}
class PaymentSuccess extends PaymentState {
  final String receiptUrl;
  PaymentSuccess(this.receiptUrl);

  @override
  List<Object?> get props => [receiptUrl];
}
class PaymentFailure extends PaymentState {
  final String message;
  PaymentFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final ConfirmPaymentUseCase confirmPaymentUseCase;
  final CreateSubscriptionUseCase createSubscriptionUseCase;

  PaymentBloc({
    required this.confirmPaymentUseCase,
    required this.createSubscriptionUseCase,
  }) : super(PaymentInitial()) {
    on<PaymentRequested>(_onPaymentRequested);
    on<SubscribeRequested>(_onSubscribeRequested);
  }

  Future<void> _onPaymentRequested(
    PaymentRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());

    try {
      final result = event.result;
      if (result.success == null) {
        throw Exception(result.fail?.message ?? '결제 실패');
      }

      // Edge Function으로 결제 승인 요청
      final payment = await confirmPaymentUseCase(
        ConfirmPaymentParams(
          paymentKey: result.success!.paymentKey,
          orderId: result.success!.orderId,
          amount: result.success!.amount,
        ),
      );

      emit(PaymentSuccess(payment.receiptUrl));
    } catch (e) {
      emit(PaymentFailure(e.toString()));
    }
  }

  Future<void> _onSubscribeRequested(
    SubscribeRequested event,
    Emitter<PaymentState> emit,
  ) async {
    // 구독 로직 (앞서 구현한 코드 참조)
    // ...
  }
}
```

---

## 테스트 계획

### 1. 단위 테스트 (Unit Tests)

```dart
// test/features/payment/domain/usecases/confirm_payment_test.dart

void main() {
  group('ConfirmPayment UseCase', () {
    test('should confirm payment with valid params', () async {
      // Arrange
      final mockRepo = MockPaymentRepository();
      final useCase = ConfirmPayment(mockRepo);

      when(() => mockRepo.confirmPayment(any()))
          .thenAnswer((_) async => Right(tPayment));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, Right(tPayment));
      verify(() => mockRepo.confirmPayment(tParams));
    });
  });
}
```

### 2. 통합 테스트 (Integration Tests)

```dart
// integration_test/payment_flow_test.dart

void main() {
  group('Payment Flow Integration Test', () {
    testWidgets('should complete payment successfully', (tester) async {
      await tester.pumpWidget(MyApp());

      // 1. 상품 선택
      await tester.tap(find.text('AI 상담 구매'));
      await tester.pumpAndSettle();

      // 2. 결제하기 버튼 클릭
      await tester.tap(find.text('결제하기'));
      await tester.pumpAndSettle();

      // 3. 결제 수단 선택
      // (토스 위젯 내부이므로 자동화 어려움)

      // 4. 결제 완료 확인
      expect(find.text('결제가 완료되었습니다'), findsOneWidget);
    });
  });
}
```

### 3. 토스페이먼츠 테스트 환경 활용

**테스트 카드 정보**:
```
카드 번호: 5570-7512-3456-1234 (Mastercard)
유효 기간: 12/25
CVC: 123
비밀번호: 00
```

**특정 에러 재현**:
```bash
# API 요청 헤더에 추가
TossPayments-Test-Code: INVALID_CARD_EXPIRATION
```

---

## 공식 문서 링크

### 토스페이먼츠
- 📘 **개발자 센터**: https://docs.tosspayments.com
- 📦 **Flutter SDK**: https://pub.dev/packages/tosspayments_widget_sdk_flutter
- 🔑 **API 레퍼런스**: https://docs.tosspayments.com/reference
- 💬 **Discord 커뮤니티**: https://discord.gg/tosspayments

### Supabase
- 📗 **Edge Functions**: https://supabase.com/docs/guides/functions
- 🗄️ **PostgreSQL**: https://supabase.com/docs/guides/database
- 🔐 **Row Level Security**: https://supabase.com/docs/guides/auth/row-level-security

---

## 다음 단계

1. ✅ **전자결제 신청 완료** (토스페이먼츠 가맹점 등록)
2. ⏳ **Supabase 프로젝트 생성 및 테이블 설정**
3. ⏳ **Edge Functions 배포**
4. ⏳ **Flutter 결제 UI 구현**
5. ⏳ **테스트 환경에서 검증**
6. ⏳ **프로덕션 배포**

---

**작성일**: 2026-01-01
**작성자**: Claude Code
**버전**: 1.0.0
