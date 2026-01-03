# 웹 SSO 로그인 설정 가이드 (Google & Apple)

## 🎯 현재 상황 분석

### 문제점
1. **authDomain 불일치**: `destiny-os-2026.firebaseapp.com` (설정) vs `destiny-os-2026.web.app` (실제 도메인)
2. **웹에서 signInWithPopup만 사용**: 모바일/PWA/Safari 환경에서 실패 가능성 높음
3. **Redirect fallback 없음**: getRedirectResult 처리 누락

### 우선순위 수정 사항
- [HIGH] Firebase Auth Authorized domains 설정
- [HIGH] authDomain을 실제 도메인으로 변경
- [HIGH] signInWithRedirect fallback 추가
- [HIGH] Apple Service ID 설정 (웹용)
- [MEDIUM] Google Cloud OAuth Redirect URI 확인

---

## 📋 Step 1: Firebase Console 설정

### 1-1. Authorized Domains 추가
🔗 [Firebase Console → Authentication → Settings → Authorized domains](https://console.firebase.google.com/project/destiny-os-2026/authentication/settings)

**필수 도메인:**
- ✅ `destiny-os-2026.web.app`
- ✅ `destiny-os-2026.firebaseapp.com`
- ✅ `localhost` (개발용)

**확인 방법:**
1. Firebase Console 접속
2. Authentication → Settings 메뉴
3. Authorized domains 섹션에 위 3개 도메인 모두 등록되어 있는지 확인

### 1-2. Sign-in Method 활성화
🔗 [Firebase Console → Authentication → Sign-in method](https://console.firebase.google.com/project/destiny-os-2026/authentication/providers)

**Google:**
- Status: ✅ Enabled
- Web SDK configuration: 자동으로 설정됨

**Apple:**
- Status: ✅ Enabled
- Service ID: `com.destinyos.destinyOs.signin` (나중에 생성)
- OAuth code flow configuration: 설정 필요 (아래 참조)

---

## 📋 Step 2: Google Cloud Console 설정

### 2-1. OAuth 2.0 Client 설정
🔗 [Google Cloud Console → APIs & Services → Credentials](https://console.cloud.google.com/apis/credentials?project=destiny-os-2026)

**Web client (Auto-created by Google Service) 선택 후 편집:**

**Authorized JavaScript origins:**
```
https://destiny-os-2026.web.app
https://destiny-os-2026.firebaseapp.com
http://localhost
http://localhost:5000
```

**Authorized redirect URIs:**
```
https://destiny-os-2026.web.app/__/auth/handler
https://destiny-os-2026.firebaseapp.com/__/auth/handler
http://localhost/__/auth/handler
```

⚠️ **중요:** `/__/auth/handler`는 Firebase Auth가 사용하는 표준 redirect path입니다.

---

## 📋 Step 3: Apple Developer 설정 (가장 중요!)

### 3-1. Service ID 생성
🔗 [Apple Developer → Identifiers → Service IDs](https://developer.apple.com/account/resources/identifiers/serviceId/add/)

#### 1) Service ID 등록
```
Description: Destiny OS Web Sign In
Identifier: com.destinyos.destinyOs.signin
```

**Save** 클릭 후 다시 해당 Service ID 클릭하여 편집

#### 2) Sign In with Apple 활성화
- ✅ **Sign In with Apple** 체크박스 활성화
- **Configure** 버튼 클릭

#### 3) Web Authentication Configuration
**Primary App ID:**
```
com.destinyos.destinyOs
```
(기존 iOS 앱 Bundle ID와 연결)

**Domains and Subdomains:**
```
destiny-os-2026.web.app
```

**Return URLs:**
```
https://destiny-os-2026.web.app/__/auth/handler
```

⚠️ **주의사항:**
- HTTPS 필수 (http:// 불가)
- localhost는 지원 안 됨 (테스트는 배포 도메인에서)
- Return URL은 정확히 `/__/auth/handler`로 끝나야 함

**Continue** → **Save** → **Done**

### 3-2. Key 생성 (이미 있으면 Skip)
🔗 [Apple Developer → Keys](https://developer.apple.com/account/resources/authkeys/list)

1. **Create a Key** (+) 클릭
2. Key Name: `Destiny OS Auth Key`
3. ✅ **Sign In with Apple** 체크
4. **Configure** → Primary App ID 선택
5. **Save** → **Continue** → **Register**
6. **Download** (⚠️ 한 번만 다운로드 가능!)

다운로드한 `.p8` 파일 저장:
```
AuthKey_XXXXXXXXXX.p8
```

**Key ID 복사:** `XXXXXXXXXX` (10자리)
**Team ID 확인:** Apple Developer 우측 상단 (10자리)

### 3-3. Firebase Console에 Apple 설정 입력
🔗 [Firebase Console → Authentication → Sign-in method → Apple](https://console.firebase.google.com/project/destiny-os-2026/authentication/providers)

**OAuth code flow configuration:**
```
Service ID: com.destinyos.destinyOs.signin
Team ID: [Your 10-digit Team ID]
Key ID: [Your 10-digit Key ID]
Private Key: [AuthKey_XXXXXXXXXX.p8 파일 내용 전체 복사]
```

**Save** 클릭

---

## 📋 Step 4: authDomain 수정

### 4-1. firebase_options.dart 수정
**현재 (문제):**
```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyDBLkjvI3cEJh71UN7KaVvoiNLNy1Iih3o',
  appId: '1:16973939404:web:2cf031a507fd1a861df869',
  messagingSenderId: '16973939404',
  projectId: 'destiny-os-2026',
  authDomain: 'destiny-os-2026.firebaseapp.com', // ❌ 문제
  storageBucket: 'destiny-os-2026.firebasestorage.app',
);
```

**수정 (권장):**
```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyDBLkjvI3cEJh71UN7KaVvoiNLNy1Iih3o',
  appId: '1:16973939404:web:2cf031a507fd1a861df869',
  messagingSenderId: '16973939404',
  projectId: 'destiny-os-2026',
  authDomain: 'destiny-os-2026.web.app', // ✅ 실제 도메인으로 수정
  storageBucket: 'destiny-os-2026.firebasestorage.app',
);
```

---

## 📋 Step 5: signInWithRedirect Fallback 추가

### 5-1. auth_service.dart 수정
현재 웹에서는 `signInWithPopup`만 사용하고 있는데, 이는:
- 팝업 차단 환경에서 실패
- PWA standalone 모드에서 불안정
- 모바일 브라우저에서 UX 문제

**권장 패턴:**
1. 데스크탑: signInWithPopup 시도
2. 실패 시 또는 모바일: signInWithRedirect
3. 앱 시작 시 getRedirectResult 확인

---

## 📋 Step 6: 테스트 체크리스트

### 6-1. 데스크탑 브라우저 (Chrome/Edge)
- [ ] Google 로그인 - 팝업 방식
- [ ] Apple 로그인 - 팝업 방식
- [ ] 로그아웃 후 재로그인

### 6-2. 모바일 브라우저 (Safari/Chrome)
- [ ] Google 로그인 - 리다이렉트 방식
- [ ] Apple 로그인 - 리다이렉트 방식
- [ ] PWA 설치 후 로그인

### 6-3. 예상 에러 시나리오
| 에러 코드 | 원인 | 해결 방법 |
|----------|------|----------|
| `unauthorized-domain` | Authorized domains 누락 | Firebase Console에 도메인 추가 |
| `redirect_uri_mismatch` | OAuth Redirect URI 불일치 | Google Cloud Console에서 URI 추가 |
| `popup-blocked` | 브라우저 팝업 차단 | signInWithRedirect로 fallback |
| `operation-not-allowed` | Sign-in method 비활성화 | Firebase Console에서 활성화 |

---

## 🔍 디버깅 가이드

### 로그인 실패 시 확인 순서
1. **브라우저 콘솔 확인** (F12 → Console)
   - Firebase Auth 에러 메시지 확인
   - 에러 코드 기록

2. **Network 탭 확인** (F12 → Network)
   - `accounts.google.com` 또는 `appleid.apple.com` 호출 실패 여부
   - 401/403 응답 확인

3. **Firebase Console Logs**
   - Authentication → Users: 사용자 생성 여부
   - Authentication → Sign-in method: Provider 활성화 상태

4. **도메인 설정 재확인**
   - Firebase Authorized domains
   - Google OAuth Redirect URIs
   - Apple Return URLs

---

## 📌 Quick Start (최소 설정)

최소한으로 동작하게 하려면:

1. ✅ Firebase Console → Authorized domains에 `destiny-os-2026.web.app` 추가
2. ✅ `authDomain: 'destiny-os-2026.web.app'`로 수정
3. ✅ Google Cloud Console → Redirect URIs에 `https://destiny-os-2026.web.app/__/auth/handler` 추가
4. ✅ Apple Service ID 생성 및 Return URL 설정
5. ✅ Firebase Console → Apple 설정에 Service ID/Team ID/Key 입력

이 5단계만 완료하면 기본 로그인은 동작할 것입니다.

---

## 🆘 문제 발생 시

### Google 로그인 실패
1. Google Cloud Console → Credentials 확인
2. Redirect URI가 정확히 `/__/auth/handler`로 끝나는지 확인
3. Firebase Authorized domains에 도메인 등록 확인

### Apple 로그인 실패
1. Apple Service ID → Return URL이 HTTPS인지 확인
2. Firebase Console → Apple 설정에서 Service ID 정확성 확인
3. Private Key (.p8) 파일 내용이 올바르게 입력되었는지 확인
4. **중요:** 로컬(localhost)에서는 Apple 웹 로그인 불가 → 배포 도메인에서만 테스트

### 팝업 차단 문제
1. signInWithRedirect로 변경 (코드 수정 필요)
2. 앱 시작 시 getRedirectResult 처리 추가

---

## 📚 참고 문서
- [Firebase Auth - Authorized Domains](https://firebase.google.com/docs/auth/web/redirect-best-practices)
- [Google OAuth - Redirect URIs](https://developers.google.com/identity/protocols/oauth2/web-server#uri-validation)
- [Apple Sign In - Configure Web](https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_js/configuring_your_webpage_for_sign_in_with_apple)
