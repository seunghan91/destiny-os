# 웹 SSO 설정 빠른 체크리스트

## ✅ 완료된 코드 수정 (2026-01-03)

### 1. authDomain 수정 ✅
```dart
// firebase_options.dart
authDomain: 'destiny-os-2026.web.app' // ✅ 실제 도메인으로 변경
```

### 2. signInWithRedirect Fallback 추가 ✅
```dart
// auth_service.dart
// Popup 차단 시 자동으로 Redirect로 전환
```

### 3. getRedirectResult 처리 추가 ✅
```dart
// main.dart
// 앱 시작 시 Redirect 로그인 결과 자동 확인
```

---

## 🔧 Firebase/Google/Apple Console 설정 (수동 필요)

### Firebase Console 체크리스트

#### 1. Authorized Domains 추가 필수
🔗 https://console.firebase.google.com/project/destiny-os-2026/authentication/settings

```
✅ destiny-os-2026.web.app
✅ destiny-os-2026.firebaseapp.com
✅ localhost
```

#### 2. Sign-in Method 활성화
🔗 https://console.firebase.google.com/project/destiny-os-2026/authentication/providers

- Google: ✅ Enabled
- Apple: ✅ Enabled (Service ID 설정 필요)

---

### Google Cloud Console 체크리스트

🔗 https://console.cloud.google.com/apis/credentials?project=destiny-os-2026

**Web client (Auto-created by Google Service) 편집:**

**Authorized JavaScript origins:**
```
https://destiny-os-2026.web.app
https://destiny-os-2026.firebaseapp.com
http://localhost
```

**Authorized redirect URIs:**
```
https://destiny-os-2026.web.app/__/auth/handler
https://destiny-os-2026.firebaseapp.com/__/auth/handler
http://localhost/__/auth/handler
```

---

### Apple Developer Console 체크리스트

#### 1. Service ID 생성
🔗 https://developer.apple.com/account/resources/identifiers/serviceId/add/

```
Description: Destiny OS Web Sign In
Identifier: com.destinyos.destinyOs.signin
```

**Sign In with Apple 활성화:**
- Primary App ID: `com.destinyos.destinyOs`
- Domains: `destiny-os-2026.web.app`
- Return URLs: `https://destiny-os-2026.web.app/__/auth/handler`

#### 2. Key 생성 (필요 시)
🔗 https://developer.apple.com/account/resources/authkeys/list

- Key Name: `Destiny OS Auth Key`
- Sign In with Apple 활성화
- `.p8` 파일 다운로드 및 보관

#### 3. Firebase Console에 Apple 설정 입력
🔗 https://console.firebase.google.com/project/destiny-os-2026/authentication/providers

```
Service ID: com.destinyos.destinyOs.signin
Team ID: [10-digit Team ID]
Key ID: [10-digit Key ID]
Private Key: [.p8 파일 내용 전체]
```

---

## 🚀 배포 후 테스트

### 테스트 시나리오

1. **데스크탑 Chrome (Popup)**
   - Google 로그인 → 팝업 열림 → 성공
   - Apple 로그인 → 팝업 열림 → 성공

2. **모바일 Safari (Redirect)**
   - Google 로그인 → 페이지 리다이렉트 → 성공
   - Apple 로그인 → 페이지 리다이렉트 → 성공

3. **팝업 차단 환경**
   - 브라우저 팝업 차단 설정
   - 로그인 시도 → Redirect로 자동 전환
   - "로그인 중입니다. 잠시 후 페이지가 새로고침됩니다." 메시지 표시
   - 페이지 리로드 후 로그인 성공

### 예상 에러 및 해결

| 에러 메시지 | 원인 | 해결 방법 |
|------------|------|----------|
| "허용되지 않은 도메인" | Authorized domains 누락 | Firebase Console에서 도메인 추가 |
| "로그인 설정에 문제" | Redirect URI 불일치 | Google Cloud Console에서 URI 추가 |
| "Apple 로그인 실패" | Service ID/Return URL 오류 | Apple Developer 설정 재확인 |
| "팝업 차단" | 브라우저 설정 | 자동 Redirect로 전환됨 (정상) |

---

## 📋 설정 완료 확인

### 1단계: Firebase Console
- [ ] Authorized domains 3개 등록
- [ ] Google Sign-in 활성화
- [ ] Apple Sign-in 활성화
- [ ] Apple Service ID/Team ID/Key 입력

### 2단계: Google Cloud Console
- [ ] JavaScript origins 3개 등록
- [ ] Redirect URIs 3개 등록

### 3단계: Apple Developer
- [ ] Service ID 생성 및 활성화
- [ ] Domains 설정: `destiny-os-2026.web.app`
- [ ] Return URLs 설정: `/__/auth/handler`
- [ ] Key 생성 및 다운로드 (필요 시)

### 4단계: 코드 배포
- [x] authDomain 수정
- [x] signInWithRedirect fallback 추가
- [x] getRedirectResult 처리 추가

### 5단계: 테스트
- [ ] 데스크탑 Google 로그인
- [ ] 데스크탑 Apple 로그인
- [ ] 모바일 Google 로그인
- [ ] 모바일 Apple 로그인
- [ ] 팝업 차단 시 동작

---

## 🔍 디버깅 팁

### 브라우저 콘솔 확인
```javascript
// F12 → Console
// Firebase Auth 에러 코드 확인
```

### 로그 확인
```dart
// Flutter 로그
✅ Google Sign-In successful (Web/Popup)
✅ Apple Sign-In successful (Web/Popup)
✅ Redirect Sign-In successful
⚠️ Popup failed, fallback to redirect
```

### 네트워크 탭 확인
```
F12 → Network
- accounts.google.com 호출
- appleid.apple.com 호출
- 401/403 에러 확인
```

---

## 📞 문제 발생 시

1. **Google 로그인 실패**
   - Google Cloud Console Redirect URI 재확인
   - Firebase Authorized domains 재확인

2. **Apple 로그인 실패**
   - Apple Service ID Return URL 재확인 (HTTPS 필수!)
   - Firebase Apple 설정 재확인 (Service ID/Team ID/Key)
   - **중요:** localhost에서는 Apple 웹 로그인 불가 → 배포 환경에서 테스트

3. **팝업 차단 문제**
   - 정상 동작: Redirect로 자동 전환
   - 페이지 리로드 후 로그인 완료

---

## 📚 상세 문서

전체 가이드: [WEB_SSO_SETUP_GUIDE.md](./WEB_SSO_SETUP_GUIDE.md)
