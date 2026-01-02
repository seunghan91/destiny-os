# 토스페이먼츠 통합 개발 가이드

> 출처: [토스페이먼츠 개발자센터](https://docs.tosspayments.com/guides/v2)

## 📑 목차
- [환경 설정하기](#환경-설정하기)
- [결제 흐름 이해하기](#결제-흐름-이해하기)
- [결제위젯 연동하기](#결제위젯-연동하기)
- [웹훅 연결하기](#웹훅-연결하기)
- [결제 취소하기](#결제-취소하기)

---

# 환경 설정하기

## 테스트 환경 주의점

토스페이먼츠는 개발자의 연동 편의를 위해 라이브 환경과 비슷한 테스트 환경을 제공하고 있습니다.

### 기본 원칙
- 테스트 환경에서는 카드 번호와 같은 실제 결제 정보를 입력해도, **결제는 가상으로 승인**됩니다.
- 따라서 테스트 환경에서는 실제 결제가 발생하지 않습니다.

### 테스트 환경 제약사항

#### 1. 가상계좌
- 테스트 환경에서는 가상계좌번호 앞에 **'X'가 붙습니다**.
- 테스트 환경에서 발급된 계좌로 직접 입금할 수 없지만, **테스트 결제내역 메뉴에서 입금처리**를 할 수 있습니다.
- 개발 연동 체험 상점의 테스트 키로 연동하면 **가상계좌 입금 안내 문자가 발송되지 않습니다**.
- 토스페이먼츠 전자결제 계약 이후에 확인할 수 있는 테스트 키로는 가상계좌 안내 문자가 발송됩니다.

#### 2. 영수증
- Payment 객체에 영수증 URL은 생성되지만 **실제 데이터는 제공되지 않습니다**.
- 영수증 샘플은 [결제 결과 안내 가이드](https://docs.tosspayments.com/guides/v2/learn/payment-results)에서 확인하세요.

#### 3. 자동결제(빌링)
- 카드 번호의 앞 여섯 자리(**BIN 번호**)만 유효해도 자동 결제가 등록됩니다.
- 라이브 환경에서는 전체 카드 번호가 유효해야 등록됩니다.
- 휴대폰 본인 인증번호로 `000000`을 입력하세요.
- **휴대폰 인증은 라이브 환경에서만 사용할 수 있습니다**.

#### 4. 계좌이체
- 계좌번호, 비밀번호, 계좌 소유주 이름, 보안카드와 OTP 정보를 **가상의 값으로 넣어** 테스트할 수 있습니다.
- 다만 사용자의 **공동 인증서는 실제로 인증이 되어야** 합니다.

#### 5. 지급대행
- 테스트 환경에서 잔액조회 API를 호출하면 응답으로 `availableAmount`만 돌아옵니다.
- 테스트 환경에서는 유효한 사업자번호로 **법인사업자(`CORPORATE`) 셀러만 등록**할 수 있습니다.
- 셀러의 상태가 `KYC_REQUIRED`로 바뀔 수는 있지만 테스트 KYC 수행이 불가능하기 때문에 `APPROVED` 상태로 바뀔 수는 없습니다.
- ⚠️ **지급대행 요청 API를 라이브 환경에서 테스트하면 수수료가 부과됩니다**.

#### 6. API 요청 제한
- 테스트 환경에서 각 API는 **분당 100건의 요청 제한**이 있습니다.

### 에러 재현하기

에러 대응을 위해 테스트 환경에서 API 에러를 재현하고 싶을 수 있습니다.

#### TossPayments-Test-Code 헤더 사용

`TossPayments-Test-Code` API 헤더를 사용하면 토스페이먼츠에서 일어나는 모든 에러를 테스트 환경에서도 라이브 환경과 똑같이 재현할 수 있습니다.

**사용 방법:**
1. `TossPayments-Test-Code` 헤더에 재현하고 싶은 에러 코드를 넣습니다.
2. API를 호출합니다.
3. 테스트한 에러 코드의 에러 객체가 응답으로 돌아옵니다.

### 결제 내역 확인

- **테스트 환경**: 개발자센터에서 확인
- **라이브 환경**: 상점관리자에서 확인

## 방화벽 설정

토스페이먼츠는 **HTTPS 통신과 TLS 버전 1.2 이상만 지원**합니다.

### 허용해야 할 IP 주소

서버에서 아래 토스페이먼츠 IP 주소를 허용해주세요.

| IP 주소 | 방향 |
|---------|------|
| 13.124.18.147 | INBOUND |
| 13.124.108.35 | INBOUND |
| 3.36.173.151 | INBOUND |
| 3.38.81.32 | INBOUND |
| 115.92.221.121* | INBOUND |
| 115.92.221.122* | INBOUND |
| 115.92.221.123* | INBOUND |
| 115.92.221.125* | INBOUND |
| 115.92.221.126* | INBOUND |
| 115.92.221.127* | INBOUND |

더 자세한 내용은 [방화벽 가이드](https://docs.tosspayments.com/guides/v2/get-started/firewall)에서 확인하세요.

## 지원 플랫폼 및 브라우저

토스페이먼츠 SDK가 지원하는 플랫폼·브라우저 환경입니다.

### 권장사항

토스페이먼츠 결제 서비스를 원활하게 이용하려면 **최신 버전의 브라우저를 사용하는 것을 권장**합니다.

- 최신 브라우저는 더 안전하고 안정적입니다.
- 결제 오류를 최소화할 수 있습니다.

### 지원 환경

| 플랫폼 환경 | 브라우저 환경 |
|------------|--------------|
| 데스크톱 브라우저 | - Chrome 72 이상<br>- Edge 79 이상<br>- Firefox 64 이상<br>- Safari 13 이상<br>- Whale 1.6.81.8 이상 |
| 모바일 웹 | Chrome, Safari, 삼성 인터넷 |
| 모바일 앱 | Android, iOS |

## API 버전 설정

### 중요: API 버전 설정

토스페이먼츠 MID의 API 버전을 올바르게 설정해야 합니다.

**설정 경로:**
1. 토스페이먼츠 상점관리자 로그인
2. 개발자센터 > 내 개발정보
3. 테스트/라이브 각각 설정
4. **API 버전을 `2022-07-27`로 설정**

⚠️ **API 버전을 다르게 설정하면 결제 승인/실패 시 실제 응답과 다른 응답을 받을 수 있습니다.**

---

# 결제 흐름 이해하기

카드 결제 과정의 세 가지 핵심 단계인 **요청, 인증, 승인**을 이해하고 결제 정보를 검증하는 방법을 알아보세요.

## 기본 결제 흐름

기본적으로 온라인 결제는 **요청, 인증, 승인** 세 가지 과정이 있습니다.

### 1️⃣ 결제 요청

**구매자**
- 주문서의 상품 정보, 결제 금액을 확인하고 **'결제하기' 버튼**을 클릭합니다.

**Client**
- '결제하기' 버튼의 클릭 이벤트로 토스페이먼츠 SDK의 **결제 요청 메서드**를 호출합니다.
- 결제 요청 메서드는 구매자가 선택한 결제수단의 결제창을 엽니다.

### 2️⃣ 구매자 정보 인증

**구매자**
- 결제창에 카드 번호, 만료일, CVC 등 결제 정보를 직접 입력하거나
- 앱카드, 간편결제 앱으로 **결제 정보를 불러옵니다**.

**카드사**
- 카드사는 구매자가 입력한 결제 정보를 확인하면서 구매자를 **카드 소유자로 인증**합니다.
- 인증 과정은 구매자와 상점을 보호하고, 부정거래나 사기 등을 방지하기 위해 꼭 필요합니다.

### 3️⃣ 결제 키 발급 및 리다이렉트

**토스페이먼츠**
- 인증이 성공하면 토스페이먼츠에서 **결제 키(`paymentKey`)**를 발급합니다.
- 결제 키는 각 결제에 고유한 값이고, 결제 인증이 끝나면 자동으로 발급됩니다.
- 토스페이먼츠에서 앱을 **성공 URL로 리다이렉트**합니다.
- 성공 URL의 쿼리 파라미터에는 결제 키(`paymentKey`), 주문번호(`orderId`), 금액(`amount`)이 포함됩니다.

### 4️⃣ 결제 승인

**Server**
- 인증된 결제를 승인해야 결제가 마무리됩니다.
- 성공 URL의 쿼리 파라미터 값이 결제 요청에 보낸 값과 동일한지 확인합니다.
- 결제 승인 API를 호출합니다.
- 카드사로 결제 승인 요청이 전달됩니다.

**카드사**
- 카드사는 **결제 금액을 구매자의 카드 한도 또는 은행 계좌에서 차감**합니다.
- 최종 결제 결과는 API 응답으로 확인할 수 있습니다.
- 실제로 결제 금액이 구매자의 결제수단에서 차감되었기 때문에 이제 상품 및 서비스를 구매자에게 제공합니다.

## 왜 요청과 승인을 분리했나요?

토스페이먼츠는 **데이터 정합성과 연동 편의를 위해서 요청과 승인을 따로 하는 방식**으로 설계했습니다.

### 분리의 장점

1. **데이터 정합성 보장**: 결제 요청과 승인 사이에 서버에서 직접 결제 정보를 검증할 수 있습니다.
2. **연동 편의성**: 웹훅 연동 없이도 결제 결과를 확실하게 받을 수 있습니다.
3. **보안 강화**: 클라이언트에서 결제 금액을 조작해 승인하는 행위를 방지할 수 있습니다.

### paymentKey란?

`paymentKey`는 각 결제를 식별하는 값입니다.
- 결제 인증이 완료되면 토스페이먼츠에서 고유한 `paymentKey`를 발급합니다.
- 성공 URL의 쿼리 파라미터로 전달됩니다.
- 결제 승인, 결제 취소, 결제 조회할 때 필요한 중요한 값입니다.

## 결제 정보 검증 흐름

### 요청 단계에서 정보 저장

`orderId`(주문번호)와 `amount`(최종 결제 금액)을 클라이언트에서 서버로 보내 임시로 저장합니다.

1. 구매자가 주문서에서 '결제하기' 버튼을 클릭해 결제를 요청합니다.
2. 주문번호와 최종 결제 금액을 서버 세션이나 데이터베이스에 임시로 저장합니다.
3. 결제 정보가 잘 저장되었다면 결제를 요청합니다.

### 승인 전 정보 검증

결제 요청, 인증까지 성공했다면 승인 요청을 하기 전에 정보를 검증합니다.

- 앞서 요청할 때 저장해 둔 정보와 인증 결과로 돌아온 정보가 같은지 검증합니다.
- 클라이언트에서 결제 금액을 조작해 승인하는 행위를 방지할 수 있습니다.

---

# 결제위젯 연동하기

## 결제위젯이란?

결제위젯은 토스페이먼츠만의 기본 결제서비스로, 수많은 상점을 분석해서 만든 **최적의 주문서 결제 UI**입니다.

### 주요 특징

#### 높은 구매 전환율
- PG 제공 화면을 생략하기 때문에 구매자 결제 시간, 이탈률이 줄어듭니다.
- 주문서에서 바로 사용 가능한 결제수단, 구매 혜택을 확인할 수 있습니다.

#### 코드 없는 운영
- 어드민에서 디자인, 결제수단 등을 직접 커스터마이징할 수 있습니다.
- 최초 1회 개발 연동이 끝나면 코드 없이 결제수단을 추가하고, UI 디자인을 쉽게 수정할 수 있습니다.

#### 간편한 연동
- 브라우저 스크립트에 결제위젯 SDK를 한 줄 추가하거나 npm 패키지를 설치해서 바로 연동을 시작할 수 있습니다.

## 5분 만에 결제 연동하기

### 1단계: SDK 추가

브라우저 스크립트 태그로 SDK를 추가합니다:

```html
<script src="https://js.tosspayments.com/v2/payment-widget"></script>
```

또는 npm 패키지로 설치:

```bash
npm install @tosspayments/payment-widget-sdk
```

### 2단계: 결제위젯 초기화

클라이언트 키를 사용해 결제위젯 인스턴스를 초기화합니다:

```javascript
const paymentWidget = PaymentWidget(clientKey, customerKey);
// customerKey: 고객을 식별하는 고유값
// 비회원 구매의 경우 'ANONYMOUS' 입력
```

### 3단계: 결제수단 영역 렌더링

결제수단을 표시할 영역을 만들고 렌더링합니다:

```html
<div id="payment-widget"></div>
```

```javascript
paymentWidget.renderPaymentMethods('#payment-widget', price);
// price: 결제될 금액
```

### 4단계: 약관 영역 렌더링

```html
<div id="agreement"></div>
```

```javascript
paymentWidget.renderAgreement('#agreement');
```

### 5단계: 결제 요청

결제 버튼 클릭 시 결제를 요청합니다:

```javascript
paymentWidget.requestPayment({
  orderId: 'unique-order-id',
  orderName: '상품명',
  successUrl: 'https://your-domain.com/success',
  failUrl: 'https://your-domain.com/fail',
});
```

### 6단계: 결제 승인 (서버)

성공 URL로 리다이렉트되면 서버에서 결제 승인 API를 호출합니다:

```javascript
// 1. 인증 헤더 생성
const encryptedSecretKey = btoa(secretKey + ':');

// 2. 결제 승인 API 호출
fetch('https://api.tosspayments.com/v1/payments/confirm', {
  method: 'POST',
  headers: {
    'Authorization': `Basic ${encryptedSecretKey}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    paymentKey: paymentKey,
    orderId: orderId,
    amount: amount,
  }),
});
```

⚠️ **성공 페이지로 리다이렉트된 후 10분 이내에 결제 승인 API를 호출해야 합니다.**

## 어드민 설정하기

### variantKey 사용하기

1. 토스페이먼츠 상점관리자의 **결제 UI 설정** 메뉴로 이동
2. 연동하고 싶은 결제 UI의 결제서비스 추가
3. 디자인 및 기능 변경
4. `variantKey` 복사
5. 결제위젯 렌더링 시 `variantKey`를 파라미터로 사용

```javascript
paymentWidget.renderPaymentMethods('#payment-widget', price, {
  variantKey: 'YOUR_VARIANT_KEY'
});
```

---

# 웹훅 연결하기

## 웹훅이란?

웹훅(Webhook)은 데이터가 변경되었을 때 실시간으로 알림을 받을 수 있는 기능입니다.

토스페이먼츠 결제, 브랜드페이, 지급대행 상태에 변경사항이 있을 때 웹훅으로 실시간 업데이트를 받을 수 있습니다.

## 웹훅 이벤트 타입

| 이벤트 타입 | 설명 |
|------------|------|
| `PAYMENT_STATUS_CHANGED` | 결제 상태 변경 이벤트 (모든 결제수단) |
| `DEPOSIT_CALLBACK` | 가상계좌 입금 및 입금 취소 이벤트 |
| `CANCEL_STATUS_CHANGED` | 결제 취소 상태 이벤트 |
| `METHOD_UPDATED` | 브랜드페이 고객 결제수단 변경 이벤트 |
| `CUSTOMER_STATUS_CHANGED` | 브랜드페이 고객 상태 변경 이벤트 |
| `payout.changed` | 지급대행 상태 변경 이벤트 |
| `seller.changed` | 셀러 상태 변경 이벤트 |
| `BILLING_DELETED` | 빌링키 삭제 이벤트 |

## 웹훅 등록하기

### 개발자센터에서 등록

1. 개발자센터의 **웹훅** 메뉴 선택
2. **웹훅 등록하기** 버튼 클릭
3. 웹훅 이름, 웹훅 URL 입력
4. 등록할 이벤트 선택
5. **등록하기** 버튼 클릭

⚠️ 웹훅은 상점아이디(MID)별로 설정할 수 있고, 각 상점아이디에 따로 전송됩니다.

## 웹훅 엔드포인트 구현

### 기본 구조

```javascript
app.post('/hook', (req, res) => {
  // 웹훅 이벤트 본문 확인
  const event = req.body;

  // 이벤트 처리 로직
  // ...

  // ⚠️ 중요: 반드시 200 응답을 10초 이내에 보내야 합니다
  res.sendStatus(200);
});
```

### 가상계좌 웹훅 예제

```javascript
app.post('/hook', async (req, res) => {
  const { eventType, data } = req.body;

  if (eventType === 'DEPOSIT_CALLBACK') {
    // 가상계좌 입금 처리
    const { orderId, paymentKey, status } = data;

    if (status === 'DONE') {
      // 입금 완료 처리
      await updateOrderStatus(orderId, 'paid');

      // 상품 배송 등 후속 처리
      await processOrder(orderId);
    }
  }

  // 성공 응답 필수!
  res.sendStatus(200);
});
```

## 웹훅 재전송 정책

웹훅 전송이 실패하면 **최대 7회(최초 전송으로부터 3일 19시간 후)까지** 재전송됩니다.

| 재전송 횟수 | 재전송 간격(분) |
|-----------|---------------|
| 1 | 1 |
| 2 | 4 |
| 3 | 16 |
| 4 | 64 |
| 5 | 256 |
| 6 | 1024 |
| 7 | 4096 |

### 전송 상태

- **전송 중**: 1~6회까지 전송 실패 상태
- **성공**: 200 응답을 받은 상태
- **실패**: 7회 전송까지 실패한 상태

⚠️ **웹훅을 잘 받았다면 10초 이내로 200 응답을 보내주세요.**

## 로컬 개발 환경에서 웹훅 테스트

### ngrok 사용하기

로컬 개발 환경은 외부에서 접근할 수 없기 때문에 ngrok 같은 도구를 사용해야 합니다.

1. ngrok 설치
2. 로컬 서버 포트 노출:
   ```bash
   ngrok http 8080
   ```
3. 생성된 HTTPS URL 확인:
   ```
   https://acd8-2001-xxxx.ngrok.io
   ```
4. 웹훅 URL로 등록:
   ```
   https://acd8-2001-xxxx.ngrok.io/hook
   ```

## 웹훅 전송 기록 확인

개발자센터 웹훅 목록에서 등록한 웹훅을 선택하면:
- 웹훅 상세 정보
- 전송 기록
- 이벤트 본문

을 확인할 수 있습니다.

## 가상계좌에 웹훅이 필수인 이유

가상계좌는 구매자가 결제를 완료하는 시점을 직접 결정하는 결제수단입니다.

- 구매자가 언제 입금할지 알 수 없습니다.
- 웹훅을 통해 입금 완료 알림을 실시간으로 받아야 합니다.
- 웹훅 없이는 입금 여부를 확인할 방법이 없습니다.

---

# 결제 취소하기

## 결제수단별 취소 정책

| 결제 수단 | 취소 기한 | 취소 소요 기간 |
|----------|----------|--------------|
| 카드 | 취소 기한은 없지만, 카드사별 결제 데이터 보관 기간이 달라서 1년을 초과하면 취소가 안될 수 있음 | 매입 전: 즉시 환불<br>매입 후/부분 취소: 영업일 기준 3~4일 |
| 계좌이체 | 180일 이내의 거래만 취소 가능 | 실시간 환불 |
| 가상계좌 | 상점마다 설정이 다를 수 있으나 보통 365일 동안 취소 가능 | 영업일 기준 총 2일<br>의심거래: 최대 영업일 기준 9일 |
| 휴대폰 | 통신사 정책으로 결제가 발생한 당월에만 취소 가능 | 당일 취소 |
| 해외 간편결제(PayPal) | 180일 이내의 거래만 취소 가능 | 영업일 기준 최대 5일<br>일부 환불: 카드 회사에 따라 최대 30일 |

## 전액 취소하기

### API 요청

```javascript
const encryptedSecretKey = btoa(secretKey + ':');

fetch(`https://api.tosspayments.com/v1/payments/${paymentKey}/cancel`, {
  method: 'POST',
  headers: {
    'Authorization': `Basic ${encryptedSecretKey}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    cancelReason: '고객 변심',
  }),
});
```

### 멱등키 사용 (권장)

중복 취소를 방지하기 위해 멱등키 헤더를 추가하세요:

```javascript
fetch(`https://api.tosspayments.com/v1/payments/${paymentKey}/cancel`, {
  method: 'POST',
  headers: {
    'Authorization': `Basic ${encryptedSecretKey}`,
    'Content-Type': 'application/json',
    'Idempotency-Key': 'unique-key-for-this-cancel',
  },
  body: JSON.stringify({
    cancelReason: '고객 변심',
  }),
});
```

### API 응답

```json
{
  "cancels": [
    {
      "transactionKey": "83C4BB8322374732B78614...",
      "cancelReason": "고객 변심",
      "canceledAt": "2023-01-01T00:00:00+09:00",
      "cancelAmount": 10000
    }
  ]
}
```

## 부분 취소하기

### API 요청

`cancelAmount` 파라미터에 취소할 금액을 추가합니다:

```javascript
fetch(`https://api.tosspayments.com/v1/payments/${paymentKey}/cancel`, {
  method: 'POST',
  headers: {
    'Authorization': `Basic ${encryptedSecretKey}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    cancelReason: '부분 환불',
    cancelAmount: 5000,  // 부분 취소 금액
  }),
});
```

### 여러 번 부분 취소

부분 취소를 여러 번 하면 `cancels` 필드에 취소 객체가 여러 개 생성됩니다:

```json
{
  "cancels": [
    {
      "transactionKey": "83C4BB8322374732B78614...",
      "cancelAmount": 3000
    },
    {
      "transactionKey": "9D5E7F9433485843C89725...",
      "cancelAmount": 2000
    }
  ]
}
```

⚠️ `cancelAmount`에 값을 넣지 않으면 전액 취소됩니다.

## 가상계좌 결제 취소

가상계좌 결제를 취소하면 **취소일+2일**에 은행에서 구매자의 계좌로 입금 처리됩니다.

### 입금 완료 후 취소

환불받을 계좌 정보를 `refundReceiveAccount`에 포함해서 요청합니다:

```javascript
fetch(`https://api.tosspayments.com/v1/payments/${paymentKey}/cancel`, {
  method: 'POST',
  headers: {
    'Authorization': `Basic ${encryptedSecretKey}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    cancelReason: '고객 변심',
    refundReceiveAccount: {
      bank: '88',  // 은행 코드
      accountNumber: '1234567890',
      holderName: '홍길동',
    },
  }),
});
```

### 입금 전 취소

일반 결제와 똑같이 취소하면 됩니다. `refundReceiveAccount` 파라미터를 추가할 필요 없습니다.

⚠️ **가상계좌는 발급된 금액을 바꿀 수 없기 때문에 부분 취소가 불가능합니다.**

## 결제위젯에서 환불 계좌 정보 받기

결제위젯 어드민에서 **가상계좌 환불 정보 입력 > 사용함**을 선택하면:

1. 구매자가 환불 계좌 정보를 입력하는 UI 제공
2. Payment 객체의 `virtualAccount.refundReceiveAccount` 필드에서 확인 가능

⚠️ **해당 정보는 결제창을 띄운 시점부터 30분 동안만 조회**할 수 있습니다.

```javascript
// 결제 승인 직후 응답을 저장
const payment = await confirmPayment();
const refundAccount = payment.virtualAccount.refundReceiveAccount;

// DB에 저장
await saveRefundAccount(orderId, refundAccount);
```

30분이 지나면 `refundReceiveAccount` 필드의 값은 `null`로 내려옵니다.

---

## 추가 리소스

- [토스페이먼츠 V2 개발가이드](https://docs.tosspayments.com/guides/v2)
- [API 레퍼런스](https://docs.tosspayments.com/reference)
- [SDK 레퍼런스](https://docs.tosspayments.com/reference/widget-sdk)
- [샌드박스](https://docs.tosspayments.com/sandbox)
- [실시간 문의 (Discord)](https://discord.com/invite/VdkfJnknD9)

---

*마지막 업데이트: 2025-01-01*
