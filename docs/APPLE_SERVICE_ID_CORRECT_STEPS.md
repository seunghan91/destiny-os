# Apple Service ID 올바른 설정 절차 (공식 문서 기준)

## 🔍 현재 상황
Service ID는 생성했지만, **아직 "Sign in with Apple" 설정을 안 한 상태**입니다.

---

## ✅ 정확한 단계별 절차

### Step 1: Service ID 생성 (✅ 이미 완료)
🔗 https://developer.apple.com/account/resources/identifiers/serviceId/add/

```
Description: Destiny OS Web Sign In
Identifier: com.destinyos.destinyOs.signin
```

**Continue** → **Register** 클릭

**이 단계까지 완료하셨습니다!**

---

### Step 2: Service ID 다시 선택 ⭐ (지금 해야 할 것)
🔗 https://developer.apple.com/account/resources/identifiers/list/serviceId

1. **Identifiers** 목록에서
2. 필터를 **"Services IDs"**로 변경 (우측 상단 드롭다운)
3. 방금 생성한 **`com.destinyos.destinyOs.signin`** 클릭

---

### Step 3: Sign In with Apple 활성화 ⭐
Service ID 상세 페이지에서:

1. **✅ Sign In with Apple** 체크박스 클릭 (활성화)
2. 오른쪽에 **Configure** 버튼이 나타남
3. **Configure** 버튼 클릭

**이제 Web Authentication Configuration 모달이 나타납니다!**

---

### Step 4: Web Authentication Configuration 설정 ⭐

**모달 화면 구성:**

```
Web Authentication Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Primary App ID:
┌────────────────────────────────────┐
│ com.destinyos.destinyOs            │  ← 드롭다운에서 선택
└────────────────────────────────────┘

Website URLs
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Domains and Subdomains:
┌────────────────────────────────────┐
│ destiny-os-2026.web.app            │  ← 입력 (https:// 없이)
└────────────────────────────────────┘

Return URLs:
┌──────────────────────────────────────────────────────┐
│ https://destiny-os-2026.web.app/__/auth/handler     │  ← 입력 (https:// 포함)
└──────────────────────────────────────────────────────┘
```

**입력 값:**
- **Primary App ID**: `com.destinyos.destinyOs` (드롭다운에서 선택)
- **Domains and Subdomains**: `destiny-os-2026.web.app` (프로토콜 없이)
- **Return URLs**: `https://destiny-os-2026.web.app/__/auth/handler` (전체 URL)

**Done** 클릭

---

### Step 5: 저장
1. **Continue** 클릭
2. **Save** 클릭

---

## 🎯 설정 완료 확인

**Identifiers → Services IDs → `com.destinyos.destinyOs.signin` 클릭**

확인 사항:
```
Sign In with Apple: Enabled ✅ (파란색)
Configure 버튼 옆에 "Enabled" 표시
```

**Configure** 버튼을 다시 클릭하여 내용 확인:
- Primary App ID: `com.destinyos.destinyOs`
- Domains: `destiny-os-2026.web.app`
- Return URLs: `https://destiny-os-2026.web.app/__/auth/handler`

---

## ❌ 자주 하는 실수

### 실수 1: Service ID 생성만 하고 설정 안 함
```
✅ Service ID 생성 (Register)
❌ Sign In with Apple 활성화 안 함  ← 이 단계를 놓침!
```

### 실수 2: App ID Configuration 화면 혼동
**App ID Configuration 화면이 나오면:**
- "Group with an existing primary App ID" 선택
- `com.destinyos.destinyOs` 선택
- **Continue** 클릭
- 그러면 **Web Authentication Configuration**이 나옴

### 실수 3: Return URL 형식 오류
```
❌ destiny-os-2026.web.app/__/auth/handler
❌ http://destiny-os-2026.web.app/__/auth/handler
✅ https://destiny-os-2026.web.app/__/auth/handler
```

---

## 📸 화면 예시

### 1. Service ID 목록 화면
```
Identifiers
┌─────────────────────────────────────────────┐
│ Filter: [Services IDs ▼]                    │
│                                              │
│ □ com.destinyos.destinyOs.signin            │  ← 클릭
│   Destiny OS Web Sign In                    │
│                                              │
└─────────────────────────────────────────────┘
```

### 2. Service ID 상세 화면
```
Edit your Services ID Configuration

Description: Destiny OS Web Sign In
Identifier: com.destinyos.destinyOs.signin

Sign In with Apple
┌────────────────────────────────────────────┐
│ ☑ Sign In with Apple         [Configure]  │  ← 체크 + Configure 클릭
└────────────────────────────────────────────┘
```

### 3. Web Authentication Configuration 모달
```
┌─────────────────────────────────────────────┐
│ Web Authentication Configuration            │
│─────────────────────────────────────────────│
│ Primary App ID:                             │
│ [com.destinyos.destinyOs          ▼]       │
│                                              │
│ Website URLs                                 │
│                                              │
│ Domains and Subdomains:                     │
│ [destiny-os-2026.web.app           ]       │
│                                              │
│ Return URLs:                                │
│ [https://destiny-os-2026.web.app/__/auth/handler] │
│                                              │
│                          [Cancel]  [Done]   │
└─────────────────────────────────────────────┘
```

---

## 🚀 다음 단계

### Service ID 설정 완료 후:

**Firebase Console에 Apple 설정 입력**
🔗 https://console.firebase.google.com/project/destiny-os-2026/authentication/providers

```
Service ID: com.destinyos.destinyOs.signin
Team ID: [Apple Developer 우측 상단 10자리 코드]
Key ID: [생성한 Key의 10자리 ID]
Private Key: [.p8 파일 내용 전체 복사]
```

---

## 🔍 트러블슈팅

### Q: Configure 버튼이 안 보여요
**A:** "Sign In with Apple" 체크박스를 먼저 클릭하세요. 그러면 Configure 버튼이 나타납니다.

### Q: App ID Configuration 화면이 나와요
**A:** 이것이 정상입니다! "Group with existing primary App ID" 선택 → Continue하면 Web Authentication Configuration이 나옵니다.

### Q: "Invalid domain" 에러가 나요
**A:** Domains 입력 시 `https://` 를 빼고 입력하세요. `destiny-os-2026.web.app`만 입력.

### Q: Return URL이 저장 안 돼요
**A:** Return URL은 반드시 `https://`로 시작해야 합니다. `http://`나 프로토콜 없이는 안 됩니다.

---

## 📚 공식 문서
https://developer.apple.com/help/account/capabilities/configure-sign-in-with-apple-for-the-web

---

## 요약

**지금 해야 할 것:**
1. ✅ https://developer.apple.com/account/resources/identifiers/list/serviceId 접속
2. ✅ 필터: "Services IDs" 선택
3. ✅ `com.destinyos.destinyOs.signin` 클릭
4. ✅ "Sign In with Apple" 체크박스 클릭
5. ✅ "Configure" 버튼 클릭
6. ✅ Web Authentication Configuration 입력
7. ✅ Done → Continue → Save

이 순서대로 하시면 Web Authentication Configuration 화면이 나타납니다!
