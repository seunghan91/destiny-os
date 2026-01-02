# SSO 로그인 설정 가이드

mbti_luck 프로젝트의 Google/Apple 로그인 설정 가이드입니다.

## 1. Firebase 프로젝트 설정

### 1.1 Firebase Console 접속
1. [Firebase Console](https://console.firebase.google.com) 접속
2. 기존 프로젝트 선택 또는 새 프로젝트 생성

### 1.2 Authentication 활성화
1. 좌측 메뉴에서 **Build > Authentication** 선택
2. **Sign-in method** 탭 클릭
3. 다음 제공자 활성화:

#### Google 로그인
- **Google** 클릭 → **사용 설정** 토글
- 프로젝트 지원 이메일 입력
- **저장**

#### Apple 로그인
- **Apple** 클릭 → **사용 설정** 토글
- Services ID 입력 (Apple Developer에서 생성)
- **저장**

---

## 2. Google 로그인 설정

### 2.1 웹 (Web)
Firebase에서 Google 로그인을 활성화하면 자동 설정됩니다.

### 2.2 Android
1. Firebase Console에서 **프로젝트 설정 > 앱 추가 > Android**
2. 패키지명 입력: `com.example.destiny_os` (실제 패키지명으로 변경)
3. SHA-1 인증서 지문 추가:
   ```bash
   # 디버그 키
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # 릴리즈 키
   keytool -list -v -keystore your-release-key.keystore -alias your-alias
   ```
4. `google-services.json` 다운로드 → `android/app/` 폴더에 저장

### 2.3 iOS
1. Firebase Console에서 **프로젝트 설정 > 앱 추가 > iOS**
2. Bundle ID 입력
3. `GoogleService-Info.plist` 다운로드 → `ios/Runner/` 폴더에 저장
4. `ios/Runner/Info.plist`에 URL 스킴 추가:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <!-- GoogleService-Info.plist의 REVERSED_CLIENT_ID 값 -->
         <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
       </array>
     </dict>
   </array>
   ```

---

## 3. Apple 로그인 설정

### 3.1 Apple Developer 설정
1. [Apple Developer Console](https://developer.apple.com) 접속
2. **Certificates, Identifiers & Profiles** 선택

#### App ID 생성/수정
1. **Identifiers > App IDs** 선택
2. 앱 선택 또는 새로 생성
3. **Capabilities**에서 **Sign In with Apple** 체크
4. **Edit** 클릭 → **Enable as a primary App ID** 선택

#### Service ID 생성 (웹용)
1. **Identifiers > Services IDs** 선택
2. **+** 클릭하여 새 Service ID 생성
3. **Sign In with Apple** 체크 → **Configure**
4. Primary App ID 선택
5. Domains: `destiny-os-2026.firebaseapp.com`
6. Return URLs: `https://destiny-os-2026.firebaseapp.com/__/auth/handler`

#### Key 생성
1. **Keys** 선택 → **+** 클릭
2. Key Name 입력
3. **Sign In with Apple** 체크 → **Configure**
4. Primary App ID 선택
5. **Register** → Key 다운로드 (.p8 파일)
6. **Key ID** 메모

### 3.2 Firebase에 Apple 설정
1. Firebase Console > Authentication > Sign-in method > Apple
2. 입력:
   - **Services ID**: 위에서 생성한 Service ID
   - **Apple Team ID**: Apple Developer 계정의 Team ID
   - **Key ID**: 위에서 생성한 Key ID
   - **Private Key**: .p8 파일 내용

### 3.3 iOS 설정
1. Xcode에서 프로젝트 열기
2. **Signing & Capabilities** 탭
3. **+ Capability** → **Sign In with Apple** 추가
4. `ios/Runner/Info.plist` 확인

---

## 4. Supabase 테이블 설정

### 4.1 마이그레이션 실행
Supabase Dashboard > SQL Editor에서 다음 파일 실행:

```
supabase/migrations/20260102_user_profiles_credits.sql
```

또는 Supabase CLI 사용:
```bash
supabase db push
```

### 4.2 테이블 확인
- `user_profiles`: 사용자 프로필 (Firebase UID 연동)
- `user_credits`: 사용권 잔액
- `credit_transactions`: 거래 이력

---

## 5. 환경 변수 설정

### 5.1 `.env` 파일 (이미 설정된 경우 확인)
```env
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# Firebase는 firebase_options.dart에서 자동 관리됨
```

### 5.2 Firebase 설정 갱신
```bash
flutterfire configure
```

---

## 6. 테스트

### 6.1 로컬 테스트
```bash
# 웹
flutter run -d chrome

# iOS 시뮬레이터
flutter run -d ios

# Android 에뮬레이터
flutter run -d android
```

### 6.2 확인 사항
- [ ] Google 로그인 팝업이 정상 표시되는지
- [ ] Apple 로그인 버튼이 표시되는지 (iOS에서만)
- [ ] 로그인 후 프로필 정보가 표시되는지
- [ ] 크레딧 잔액이 표시되는지
- [ ] 로그아웃이 정상 동작하는지

---

## 7. 트러블슈팅

### Google 로그인 실패
- SHA-1 인증서가 Firebase에 등록되었는지 확인
- `google-services.json` 파일이 최신인지 확인
- 웹의 경우 승인된 도메인 목록 확인

### Apple 로그인 실패
- Service ID의 Return URL이 정확한지 확인
- Key가 만료되지 않았는지 확인
- iOS에서 Capability가 추가되었는지 확인

### Supabase 연결 실패
- RLS 정책이 올바르게 설정되었는지 확인
- API 키가 올바른지 확인

---

## 8. 프로덕션 체크리스트

- [ ] Firebase 프로젝트가 프로덕션 모드인지 확인
- [ ] Apple Developer에서 앱이 배포용으로 설정되었는지 확인
- [ ] SHA-1 릴리즈 키가 Firebase에 등록되었는지 확인
- [ ] 환경 변수가 프로덕션 값으로 설정되었는지 확인
- [ ] Supabase RLS 정책이 보안적으로 적절한지 확인
