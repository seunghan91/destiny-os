# 토스페이먼츠 웹훅 등록 가이드

## ⚠️ 중요: 웹훅 등록은 수동으로만 가능

토스페이먼츠는 **웹훅 등록 API를 제공하지 않습니다**.
개발자센터 UI를 통해 **수동으로 등록**해야 합니다.

---

## 📋 웹훅 등록 절차

### 1단계: 토스페이먼츠 개발자센터 로그인

https://developers.tosspayments.com/ 접속

### 2단계: 웹훅 메뉴로 이동

1. 좌측 사이드바에서 **"웹훅(Webhook)"** 메뉴 클릭
2. **"웹훅 등록하기"** 버튼 클릭

### 3단계: 웹훅 정보 입력

#### 기본 정보

| 항목 | 값 |
|------|-----|
| **웹훅 이름** | `Destiny.OS 결제 웹훅` |
| **웹훅 URL** | `https://eunnaxqjyitxjdkrjaau.supabase.co/functions/v1/webhook` |
| **환경** | 테스트 환경 (개발 시) / 라이브 환경 (프로덕션) |

#### 등록할 이벤트 선택

다음 이벤트를 **모두 체크**하세요:

- ✅ **PAYMENT_STATUS_CHANGED** - 결제 상태 변경
  - 결제 승인, 취소, 실패 시 발생
  - 가장 중요한 이벤트

- ✅ **VIRTUAL_ACCOUNT_ISSUED** - 가상계좌 발급
  - 가상계좌 결제 시 발급 완료 알림

- ✅ **VIRTUAL_ACCOUNT_DEPOSIT** - 가상계좌 입금
  - 실제 입금 완료 시 알림

- ✅ **BILLING_KEY_ISSUED** - 빌링키 발급
  - 정기 결제용 빌링키 발급 완료

- ✅ **BILLING_KEY_DELETED** - 빌링키 삭제
  - 구독 해지 시 빌링키 삭제 알림

- ✅ **SETTLEMENT_COMPLETED** - 정산 완료
  - 판매자 정산 완료 알림

### 4단계: 등록 완료

1. **"등록하기"** 버튼 클릭
2. 등록 완료 확인 메시지 확인
3. 웹훅 목록에서 등록된 웹훅 확인

---

## 🧪 웹훅 테스트

### 로컬 개발 환경 테스트 (ngrok 사용)

로컬 서버는 외부에서 접근할 수 없으므로 ngrok을 사용합니다.

```bash
# 1. ngrok 설치
brew install ngrok  # macOS
# 또는 https://ngrok.com/download

# 2. Supabase Functions 로컬 실행
supabase functions serve webhook

# 3. ngrok으로 로컬 서버 노출
ngrok http 54321

# 4. ngrok이 생성한 URL을 웹훅 URL로 등록
# 예: https://abc123.ngrok.io/functions/v1/webhook
```

### 웹훅 수신 확인

```sql
-- Supabase SQL Editor에서 실행
SELECT * FROM webhook_events
ORDER BY created_at DESC
LIMIT 10;
```

---

## 🔒 웹훅 보안 검증

토스페이먼츠가 보낸 웹훅인지 검증해야 합니다.

### 검증 방법

웹훅 요청 헤더에 포함된 서명 값을 확인:

```typescript
// supabase/functions/webhook/index.ts
import { createHmac } from 'node:crypto';

Deno.serve(async (req) => {
  const signature = req.headers.get('tosspayments-webhook-signature');
  const transmissionTime = req.headers.get('tosspayments-webhook-transmission-time');
  const body = await req.text();

  // 서명 생성
  const expectedSignature = createHmac('sha256', Deno.env.get('TOSS_SECRET_KEY')!)
    .update(`${body}:${transmissionTime}`)
    .digest('hex');

  // 서명 검증
  if (signature !== expectedSignature) {
    return new Response('Invalid signature', { status: 401 });
  }

  // 정상 처리
  const payload = JSON.parse(body);
  // ...
});
```

---

## 📊 웹훅 이벤트 타입

### PAYMENT_STATUS_CHANGED

결제 상태가 변경될 때 발생합니다.

```json
{
  "eventType": "PAYMENT_STATUS_CHANGED",
  "data": {
    "paymentKey": "tviva20240101000001...",
    "orderId": "order_123456",
    "status": "DONE",
    "approvedAt": "2024-01-01T10:00:00+09:00",
    "totalAmount": 9900
  }
}
```

**처리 로직**:
- `status = DONE` → payments 테이블 업데이트 (approved_at 설정)
- `status = CANCELED` → canceled_at 설정
- `status = FAILED` → failure_code, failure_message 저장

### VIRTUAL_ACCOUNT_DEPOSIT

가상계좌 입금 완료 시 발생합니다.

```json
{
  "eventType": "VIRTUAL_ACCOUNT_DEPOSIT",
  "data": {
    "paymentKey": "tviva20240101000002...",
    "orderId": "order_123456",
    "secret": "secret_key_...",
    "depositedAt": "2024-01-01T10:00:00+09:00"
  }
}
```

**처리 로직**:
- 입금 확인 후 결제 승인 API 호출
- payments 테이블 업데이트

### BILLING_KEY_ISSUED

정기 결제용 빌링키 발급 완료 시 발생합니다.

```json
{
  "eventType": "BILLING_KEY_ISSUED",
  "data": {
    "billingKey": "billing_key_...",
    "customerKey": "customer_123",
    "issuedAt": "2024-01-01T10:00:00+09:00"
  }
}
```

**처리 로직**:
- subscriptions 테이블에 billing_key 저장
- 구독 상태를 ACTIVE로 변경

---

## 🚨 웹훅 재전송 정책

토스페이먼츠는 웹훅 전송 실패 시 **최대 7회까지 재전송**합니다.

### 재전송 조건

- 200 응답을 받지 못한 경우
- 10초 이내에 응답하지 않은 경우
- 네트워크 오류 발생 시

### 재전송 간격

1. 1분 후
2. 5분 후
3. 10분 후
4. 30분 후
5. 1시간 후
6. 2시간 후
7. 4시간 후

### 멱등성 보장

동일한 웹훅이 여러 번 전송될 수 있으므로 **멱등성**을 보장해야 합니다.

```typescript
// ✅ 올바른 예: payment_key로 중복 체크
const existingPayment = await supabase
  .from('payments')
  .select('id')
  .eq('payment_key', data.paymentKey)
  .single();

if (existingPayment.data) {
  // 이미 처리된 웹훅
  return new Response('OK', { status: 200 });
}

// 새로운 웹훅 처리
await supabase.from('payments').insert({
  payment_key: data.paymentKey,
  // ...
});
```

---

## ✅ 체크리스트

### 웹훅 등록 완료 확인

- [ ] 토스페이먼츠 개발자센터 로그인
- [ ] 웹훅 URL 등록: `https://eunnaxqjyitxjdkrjaau.supabase.co/functions/v1/webhook`
- [ ] 모든 이벤트 타입 선택 (6개)
- [ ] 테스트 환경에서 웹훅 등록 완료
- [ ] 웹훅 수신 테스트 성공
- [ ] webhook_events 테이블에 로그 저장 확인

### 프로덕션 배포 시 추가 작업

- [ ] 라이브 환경에서 웹훅 URL 재등록
- [ ] 라이브 Secret Key로 서명 검증 테스트
- [ ] 웹훅 모니터링 알림 설정

---

## 📚 참고 문서

- [토스페이먼츠 웹훅 가이드](https://docs.tosspayments.com/guides/v2/webhook)
- [웹훅 이벤트 상세](https://docs.tosspayments.com/reference/using-api/webhook-events)

---

**작성일**: 2026-01-01
**버전**: 1.0.0
