# Firebase Console Apple 로그인 최종 설정

## ✅ 확인된 모든 정보

```
Service ID:     com.destinyos.destinyOs.signin
Team ID:        AVMJBATWAT
Key ID:         4K4X83K4D2
Private Key:    assets/apple/AuthKey_4K4X83K4D2.p8
```

---

## 🔥 Firebase Console 설정 방법

### 1. Firebase Console 접속
🔗 https://console.firebase.google.com/project/destiny-os-2026/authentication/providers

### 2. Apple Provider 설정
1. **Sign-in method** 탭 클릭
2. **Apple** 찾아서 클릭
3. 이미 Enabled 상태라면 **연필(Edit) 아이콘** 클릭
4. 아직 비활성화면 **사용 설정** 토글 ON

### 3. OAuth code flow configuration 입력

**Service ID:**
```
com.destinyos.destinyOs.signin
```

**Apple 팀 ID:**
```
AVMJBATWAT
```

**키 ID:**
```
4K4X83K4D2
```

**비공개 키:**
```
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgphiMamXBuB/Jfb6u
ffEAIjgh85sKpiGAgtMtaDV6p7mgCgYIKoZIzj0DAQehRANCAASGiq2gt3gpeJMy
Jftl4n/Srfw9qPQl5BWbWKn7wS+5S2qPbdfprQoQBmKFTmv7L5Tcn6OWmx6ff/4E
DhMwBRba
-----END PRIVATE KEY-----
```

**⚠️ 주의:**
- `-----BEGIN PRIVATE KEY-----` 부터
- `-----END PRIVATE KEY-----` 까지
- **전체를 복사/붙여넣기** 해야 합니다!

### 4. 저장
**저장** 또는 **Save** 버튼 클릭

---

## 📋 승인 콜백 URL 확인

Firebase에서 표시하는 승인 콜백 URL:
```
https://destiny-os-2026.firebaseapp.com/__/auth/handler
```

**이미 Apple Developer Console에 등록 완료:**

Service ID (`com.destinyos.destinyOs.signin`) 설정에서:
- ✅ Domains: `destiny-os-2026.web.app`
- ✅ Return URLs: `https://destiny-os-2026.web.app/__/auth/handler`

**추가 작업 필요 없음!** ✅

---

## ✅ 전체 설정 체크리스트

### Apple Developer Console ✅
- [x] **App ID 확인**: `com.destinyos.destinyOs`
- [x] **Service ID 생성**: `com.destinyos.destinyOs.signin`
- [x] **Sign In with Apple 활성화**: Service ID에서 Configure
- [x] **Web Authentication Configuration**:
  - Primary App ID: `com.destinyos.destinyOs`
  - Domains: `destiny-os-2026.web.app`
  - Return URLs: `https://destiny-os-2026.web.app/__/auth/handler`
- [x] **Key 생성**: `Destiny OS Auth Key`
- [x] **Key ID 확인**: `4K4X83K4D2`
- [x] **Private Key 다운로드**: `AuthKey_4K4X83K4D2.p8`

### Firebase Console (지금 할 것!) 🔥
- [ ] **Apple Provider 활성화**
- [ ] **Service ID 입력**: `com.destinyos.destinyOs.signin`
- [ ] **Team ID 입력**: `AVMJBATWAT`
- [ ] **Key ID 입력**: `4K4X83K4D2`
- [ ] **Private Key 입력**: `.p8 파일 전체 내용`
- [ ] **저장** 클릭

### Firebase Console 추가 설정 (이미 완료!) ✅
- [x] **Authorized domains**:
  - `destiny-os-2026.web.app`
  - `destiny-os-2026.firebaseapp.com`
  - `localhost`

### Google Cloud Console (필요 시)
- [ ] **OAuth Redirect URIs**:
  - `https://destiny-os-2026.web.app/__/auth/handler`
  - `https://destiny-os-2026.firebaseapp.com/__/auth/handler`

---

## 🚀 테스트 준비

### Firebase 설정 완료 후:
1. ✅ 코드 빌드 (이미 완료)
2. ✅ Firebase 배포 (이미 완료)
3. 🔜 웹에서 Apple 로그인 테스트

### 테스트 환경
- ✅ **데스크탑 Chrome/Safari**: Popup 방식
- ✅ **모바일 Safari/Chrome**: Redirect 방식
- ❌ **localhost**: Apple 웹 로그인 불가 (배포 환경에서만 테스트)

---

## 🎯 최종 확인

Firebase Console Apple 설정 화면에서:
```
Apple
사용 설정됨

OAuth code flow configuration:
Service ID: com.destinyos.destinyOs.signin
Team ID: AVMJBATWAT ✓
Key ID: 4K4X83K4D2 ✓
Private Key: ********** ✓

승인 콜백 URL:
https://destiny-os-2026.firebaseapp.com/__/auth/handler
```

모두 ✓ 표시되면 설정 완료! 🎉

---

## 🔐 보안 주의사항

**.p8 Private Key 파일:**
- ⚠️ **절대 Git에 커밋하지 마세요!**
- ⚠️ **안전한 곳에 백업 보관**
- ⚠️ **공개 저장소에 노출 금지**

**.gitignore 확인:**
```
assets/apple/*.p8
*.p8
```

---

## 📞 문제 발생 시

### Firebase 저장 시 에러
**"Invalid private key"**:
- Private Key 전체가 복사되었는지 확인
- `-----BEGIN PRIVATE KEY-----`부터 `-----END PRIVATE KEY-----`까지 모두 포함

**"Invalid team ID"**:
- Team ID는 정확히 `AVMJBATWAT` (대소문자 구분)

**"Invalid service ID"**:
- Service ID는 정확히 `com.destinyos.destinyOs.signin`
- Apple Developer에서 생성한 값과 일치해야 함

### 로그인 테스트 실패
**"Invalid redirect URI"**:
- Apple Service ID의 Return URLs 재확인
- `https://destiny-os-2026.web.app/__/auth/handler` 정확히 입력되었는지

**localhost에서 테스트 불가**:
- Apple 웹 로그인은 HTTPS 필수
- 배포된 도메인 `https://destiny-os-2026.web.app`에서 테스트

---

## 💡 다음 단계

1. ✅ Firebase Console에 Apple 설정 입력
2. 🔜 Google Cloud Console OAuth 설정 확인
3. 🔜 웹에서 로그인 테스트
4. 🔜 모바일에서 로그인 테스트

모든 설정 정보가 준비되었으니, Firebase Console에서 입력하기만 하면 됩니다! 🚀
