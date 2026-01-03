# Apple 인증 정보 확인 방법 (Team ID, Key ID, Private Key)

## 🎯 Firebase Console에서 요구하는 정보

Firebase Console → Authentication → Sign-in method → Apple에서 다음 3가지를 입력해야 합니다:

```
1. Apple 팀 ID (Team ID)         - 10자리 영숫자
2. 키 ID (Key ID)                 - 10자리 영숫자
3. 비공개 키 (Private Key)        - .p8 파일 전체 내용
```

---

## 1️⃣ Apple 팀 ID (Team ID) 확인

### 방법 1: Apple Developer 우측 상단
🔗 https://developer.apple.com/account

1. Apple Developer에 로그인
2. **우측 상단에 이름/계정 정보** 영역
3. 이름 아래에 **10자리 코드** 표시 (예: `AVMJBATWAT`)

### 방법 2: Membership 페이지
🔗 https://developer.apple.com/account/#!/membership

**Team ID** 항목에서 확인

**예시:**
```
Team ID: AVMJBATWAT
```

---

## 2️⃣ 키 ID (Key ID) 생성 및 확인

### Key 생성 (아직 안 했다면)
🔗 https://developer.apple.com/account/resources/authkeys/list

#### Step 1: Key 생성
1. **Keys** 메뉴 클릭
2. **+** (추가) 버튼 클릭
3. **Key Name** 입력: `Destiny OS Auth Key` (원하는 이름)
4. **✅ Sign In with Apple** 체크
5. **Configure** 클릭

#### Step 2: Primary App ID 연결
```
Primary App ID: com.destinyos.destinyOs  ← 선택
```

**Save** → **Continue** → **Register**

#### Step 3: Key ID 확인 및 다운로드
**화면에 표시되는 정보:**
```
Key ID: XXXXXXXXXX  ← 이 10자리 코드 복사!

Download Your Key
This is the only time you will be able to download this key.
```

**⚠️ 중요:**
1. **Key ID를 복사**해서 저장
2. **Download** 버튼 클릭하여 `.p8` 파일 다운로드
3. **한 번만 다운로드 가능!** 잃어버리면 새로 생성해야 함

**다운로드된 파일명:**
```
AuthKey_XXXXXXXXXX.p8
```

### 이미 Key를 생성했다면
🔗 https://developer.apple.com/account/resources/authkeys/list

**Keys** 목록에서 확인:
```
Name: Destiny OS Auth Key
Key ID: XXXXXXXXXX  ← 여기 있음
```

**⚠️ 주의:** 이미 생성한 Key의 `.p8` 파일을 잃어버렸다면:
- **다시 다운로드 불가**
- 새로운 Key를 생성해야 함

---

## 3️⃣ 비공개 키 (Private Key) 확인

### .p8 파일 열기
다운로드한 `AuthKey_XXXXXXXXXX.p8` 파일을 텍스트 에디터로 열기:

**파일 내용 예시:**
```
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...
(여러 줄의 암호화된 텍스트)
...xJ5wPJdBnL2MT1vQ==
-----END PRIVATE KEY-----
```

**전체 내용을 복사** (BEGIN부터 END까지 모두 포함)

---

## 🔥 Firebase Console에 입력

### Firebase Console 설정
🔗 https://console.firebase.google.com/project/destiny-os-2026/authentication/providers

**Apple Provider → Edit:**

```
Service ID:
┌────────────────────────────────────┐
│ com.destinyos.destinyOs.signin     │
└────────────────────────────────────┘

Apple 팀 ID:
┌────────────────────────────────────┐
│ AVMJBATWAT                         │  ← 확인한 Team ID
└────────────────────────────────────┘

키 ID:
┌────────────────────────────────────┐
│ XXXXXXXXXX                         │  ← 확인한 Key ID
└────────────────────────────────────┘

비공개 키:
┌────────────────────────────────────┐
│ -----BEGIN PRIVATE KEY-----        │
│ MIGTAgEAMBMGByqGSM49AgEGCCq...    │  ← .p8 파일 전체 내용
│ ...                                │
│ -----END PRIVATE KEY-----          │
└────────────────────────────────────┘
```

**Save** 클릭

---

## 📋 승인 콜백 URL (Return URL)

Firebase에서 표시하는 메시지:
```
"설정을 완료하려면 이 승인 콜백 URL을 Apple Developer Console의
앱 구성에 추가하세요"
```

**이미 완료했습니다!** ✅

Service ID 설정에서 **Return URLs**로 이미 입력한 것이 바로 이것입니다:
```
https://destiny-os-2026.web.app/__/auth/handler
```

**확인 방법:**
🔗 https://developer.apple.com/account/resources/identifiers/list/serviceId

1. `com.destinyos.destinyOs.signin` 클릭
2. **Configure** 클릭
3. **Return URLs**에 `https://destiny-os-2026.web.app/__/auth/handler` 있는지 확인

---

## ✅ 전체 체크리스트

### Apple Developer Console
- [x] **Team ID 확인**: 우측 상단 또는 Membership 페이지
- [ ] **Key 생성**: Keys → + → Sign In with Apple
- [ ] **Key ID 확인**: Key 생성 시 화면에 표시
- [ ] **Private Key 다운로드**: AuthKey_XXXXXXXXXX.p8 파일
- [x] **Service ID 설정**: Return URLs에 콜백 URL 등록

### Firebase Console
- [ ] **Service ID 입력**: `com.destinyos.destinyOs.signin`
- [ ] **Team ID 입력**: Apple Developer에서 확인한 값
- [ ] **Key ID 입력**: Key 생성 시 확인한 값
- [ ] **Private Key 입력**: .p8 파일 전체 내용 복사/붙여넣기
- [ ] **Save** 클릭

---

## 🚨 자주 하는 실수

### 1. Private Key를 잃어버림
**해결:** 새로운 Key를 생성하고 새 Key ID와 Private Key를 사용

### 2. Private Key 일부만 복사
```
❌ 잘못된 예:
MIGTAgEAMBMGByqGSM49AgEGCCq...

✅ 올바른 예:
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCq...
...
-----END PRIVATE KEY-----
```

### 3. Team ID와 Key ID 혼동
```
Team ID: 계정 우측 상단 (예: AVMJBATWAT)
Key ID: Keys 목록에 표시 (예: ABC123XYZ9)
```

### 4. Return URL을 Service ID에 등록 안 함
Firebase 메시지를 보고 새로 등록해야 한다고 생각하지만, **이미 Service ID Configure에서 등록했으면 완료**입니다.

---

## 💡 요약

**지금 해야 할 것:**

1. ✅ **Team ID**: 우측 상단에 이미 보이는 `AVMJBATWAT`
2. 🔑 **Key 생성 (아직 안 했다면)**:
   - https://developer.apple.com/account/resources/authkeys/list
   - + 버튼 → Sign In with Apple → Configure → Register
   - **Key ID 복사** (10자리)
   - **Download** 클릭 (.p8 파일)
3. 📄 **.p8 파일 열어서 전체 내용 복사**
4. 🔥 **Firebase Console에 입력**:
   - Service ID: `com.destinyos.destinyOs.signin`
   - Team ID: `AVMJBATWAT`
   - Key ID: (생성한 Key의 ID)
   - Private Key: (.p8 파일 전체 내용)
   - **Save**

이렇게 하면 Apple 로그인 설정 완료! 🎉
