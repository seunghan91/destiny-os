# Firebase Cloud Messaging 설정 가이드

Destiny.OS 앱에서 푸시 알림 기능을 사용하기 위한 Firebase 설정 가이드입니다.

## 📋 목차

1. [Firebase 프로젝트 생성](#1-firebase-프로젝트-생성)
2. [FlutterFire CLI 설정](#2-flutterfire-cli-설정)
3. [iOS 설정](#3-ios-설정)
4. [Android 설정](#4-android-설정)
5. [테스트](#5-테스트)
6. [문제 해결](#6-문제-해결)

---

## 1. Firebase 프로젝트 생성

### 1.1 Firebase Console 접속

1. [Firebase Console](https://console.firebase.google.com/)에 접속합니다
2. **"프로젝트 추가"** 버튼을 클릭합니다
3. 프로젝트 정보를 입력합니다:
   - **프로젝트 이름**: `destiny-os` (또는 원하는 이름)
   - **Google Analytics**: 선택사항 (권장: 활성화)
   - **Analytics 위치**: Korea
   - **데이터 공유 설정**: 필요에 따라 선택

4. **프로젝트 만들기** 클릭 후 완료될 때까지 대기 (약 30초)

### 1.2 Firebase 프로젝트 설정 확인

- 프로젝트가 생성되면 Firebase 콘솔 대시보드로 이동합니다
- 좌측 메뉴에서 **프로젝트 설정** (⚙️ 아이콘)을 클릭합니다
- **프로젝트 ID**를 확인합니다 (예: `destiny-os-12345`)

---

## 2. FlutterFire CLI 설정

FlutterFire CLI는 Firebase 설정을 자동화하는 공식 도구입니다.

### 2.1 Firebase CLI 설치

```bash
# Node.js가 설치되어 있어야 합니다 (https://nodejs.org/)
npm install -g firebase-tools

# 설치 확인
firebase --version
```

### 2.2 Firebase 로그인

```bash
firebase login
```

- 브라우저에서 Google 계정으로 로그인합니다
- Firebase 프로젝트에 접근할 수 있는 계정을 사용하세요

### 2.3 FlutterFire CLI 설치

```bash
dart pub global activate flutterfire_cli
```

### 2.4 FlutterFire 설정 실행

프로젝트 루트 디렉토리에서 실행:

```bash
cd /path/to/mbti_luck
flutterfire configure
```

**설정 과정**:

1. **Firebase 프로젝트 선택**:
   - 방금 생성한 프로젝트 선택 (예: `destiny-os`)
   - 또는 새 프로젝트 생성 옵션 선택

2. **플랫폼 선택**:
   ```
   ? Which platforms should your configuration support?
   ◉ iOS
   ◉ Android
   ◯ Web (선택사항)
   ```
   - iOS와 Android 모두 선택 (스페이스바로 선택)
   - Enter를 눌러 확인

3. **iOS Bundle ID 입력**:
   ```
   ? What iOS bundle id do you want to use for this configuration?
   com.example.destinyOs (기본값)
   ```
   - 기본값 사용 또는 원하는 Bundle ID 입력
   - 예: `com.yourcompany.destinyos`

4. **Android Package Name 확인**:
   ```
   ✓ Android package name: com.example.destiny_os (자동 감지)
   ```

5. **자동 생성 완료**:
   ```
   ✓ Creating Firebase project destiny-os...
   ✓ Registering iOS app...
   ✓ Registering Android app...
   ✓ Downloading configuration files...
   ✓ Writing lib/firebase_options.dart...
   ```

### 2.5 생성된 파일 확인

FlutterFire CLI가 다음 파일들을 자동으로 생성/업데이트합니다:

- ✅ `lib/firebase_options.dart` - Firebase 설정 파일
- ✅ `ios/Runner/GoogleService-Info.plist` - iOS 설정
- ✅ `android/app/google-services.json` - Android 설정

---

## 3. iOS 설정

### 3.1 Podfile 업데이트

`ios/Podfile` 파일을 열고 **플랫폼 버전을 확인**합니다:

```ruby
# iOS 12.0 이상 필요
platform :ios, '12.0'
```

### 3.2 Pod 설치

```bash
cd ios
pod install
cd ..
```

### 3.3 APNs (Apple Push Notification service) 인증 설정

Firebase Cloud Messaging은 iOS에서 APNs를 사용합니다.

#### 3.3.1 Apple Developer 계정 설정

1. [Apple Developer Console](https://developer.apple.com/)에 로그인
2. **Certificates, Identifiers & Profiles** 메뉴로 이동
3. **Keys** → **+** 버튼 클릭
4. Key 정보 입력:
   - **Key Name**: Firebase Cloud Messaging Key
   - **Apple Push Notifications service (APNs)** 체크박스 선택
5. **Continue** → **Register** 클릭
6. **Download** 버튼으로 `.p8` 파일 다운로드
7. **Key ID**를 복사 (예: `AB12CD34EF`)

#### 3.3.2 Firebase에 APNs 인증 키 등록

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택 → **프로젝트 설정** → **클라우드 메시징** 탭
3. **Apple 앱 구성** 섹션에서 **APNs 인증 키 업로드** 클릭
4. 다운로드한 `.p8` 파일 업로드
5. **Key ID**와 **Team ID** 입력:
   - **Key ID**: 방금 복사한 Key ID (예: `AB12CD34EF`)
   - **Team ID**: Apple Developer 계정의 Team ID
     - [Membership 페이지](https://developer.apple.com/account/#/membership/)에서 확인

### 3.4 Xcode 설정

1. `ios/Runner.xcworkspace`를 Xcode로 엽니다:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Signing & Capabilities** 탭에서:
   - **+ Capability** 버튼 클릭
   - **Push Notifications** 추가
   - **Background Modes** 추가 후 다음 항목 체크:
     - ✅ Remote notifications
     - ✅ Background fetch

3. **Bundle Identifier** 확인:
   - General 탭에서 Bundle Identifier가 FlutterFire CLI에서 입력한 값과 일치하는지 확인

---

## 4. Android 설정

### 4.1 google-services.json 확인

FlutterFire CLI가 자동으로 생성한 파일이 있는지 확인:

```
android/app/google-services.json
```

### 4.2 build.gradle 설정

#### 4.2.1 프로젝트 수준 build.gradle

`android/build.gradle` 파일 확인:

```gradle
buildscript {
    dependencies {
        // Google Services 플러그인 (이미 추가되어 있음)
        classpath 'com.google.gms:google-services:4.4.2'
    }
}
```

#### 4.2.2 앱 수준 build.gradle

`android/app/build.gradle` 파일 **최하단에** 다음 줄이 있는지 확인:

```gradle
apply plugin: 'com.google.gms.google-services'
```

**없으면** 파일 맨 아래에 추가합니다.

### 4.3 Android 알림 아이콘 설정 (선택사항)

푸시 알림에 사용할 커스텀 아이콘을 설정할 수 있습니다:

1. `android/app/src/main/res/` 디렉토리에 아이콘 파일 추가:
   ```
   drawable-mdpi/ic_notification.png
   drawable-hdpi/ic_notification.png
   drawable-xhdpi/ic_notification.png
   drawable-xxhdpi/ic_notification.png
   drawable-xxxhdpi/ic_notification.png
   ```

2. `android/app/src/main/AndroidManifest.xml`에 메타데이터 추가:
   ```xml
   <application>
       <!-- 기존 코드... -->

       <meta-data
           android:name="com.google.firebase.messaging.default_notification_icon"
           android:resource="@drawable/ic_notification" />

       <meta-data
           android:name="com.google.firebase.messaging.default_notification_color"
           android:resource="@color/colorPrimary" />
   </application>
   ```

---

## 5. 테스트

### 5.1 앱 실행

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android
```

### 5.2 FCM 토큰 확인

앱 실행 후 콘솔 로그에서 FCM 토큰을 확인:

```
✅ Firebase initialized successfully
✅ FCM Token: eA1B2C3D4E5F6G7H8I9J0K...
```

### 5.3 테스트 알림 전송

#### Firebase Console에서 테스트

1. [Firebase Console](https://console.firebase.google.com/) → **Cloud Messaging** 메뉴
2. **첫 번째 캠페인 만들기** 또는 **새 알림** 클릭
3. 알림 내용 입력:
   - **알림 제목**: "테스트 알림"
   - **알림 텍스트**: "Firebase 푸시 알림이 성공적으로 설정되었습니다!"
4. **테스트 메시지 전송** 클릭
5. 콘솔에 표시된 **FCM 토큰**을 입력
6. **테스트** 버튼 클릭

#### 결과 확인

- **포그라운드**: 콘솔 로그에 메시지 표시
  ```
  📱 Foreground message received
     Title: 테스트 알림
     Body: Firebase 푸시 알림이 성공적으로 설정되었습니다!
  ```

- **백그라운드**: 시스템 알림 트레이에 알림 표시

### 5.4 토픽 구독 테스트

앱 설정 페이지에서 **"오늘의 운세 알림"** 토글을 활성화하면:

```
✅ Subscribed to topic: daily_fortune
알림이 활성화되었습니다 ✅
```

Firebase Console에서 **토픽 대상** 알림을 보낼 수 있습니다:
- 대상: 토픽
- 토픽 이름: `daily_fortune`

---

## 6. 문제 해결

### 6.1 iOS 빌드 오류

#### "GoogleService-Info.plist not found"

**해결 방법**:
```bash
# FlutterFire CLI 재실행
flutterfire configure

# Pod 재설치
cd ios
pod deintegrate
pod install
cd ..
```

#### "APNs token not available"

**원인**: 시뮬레이터는 APNs를 지원하지 않습니다.

**해결 방법**: 실제 iOS 기기에서 테스트하세요.

### 6.2 Android 빌드 오류

#### "google-services.json is missing"

**해결 방법**:
```bash
# FlutterFire CLI 재실행
flutterfire configure
```

**수동 복사**:
1. Firebase Console → 프로젝트 설정 → 일반
2. Android 앱 → `google-services.json` 다운로드
3. `android/app/` 디렉토리에 복사

#### "Plugin with id 'com.google.gms.google-services' not found"

**해결 방법**:

`android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.2'
    }
}
```

`android/app/build.gradle` 최하단:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 6.3 알림이 수신되지 않음

#### iOS

1. **APNs 키 확인**:
   - Firebase Console → 프로젝트 설정 → 클라우드 메시징
   - APNs 인증 키가 올바르게 업로드되었는지 확인

2. **권한 확인**:
   - iOS 설정 → Destiny.OS → 알림 → 허용됨

3. **실제 기기 사용**: 시뮬레이터는 푸시 알림을 지원하지 않습니다

#### Android

1. **google-services.json 확인**:
   - `android/app/google-services.json` 파일 존재 여부
   - `applicationId`가 일치하는지 확인

2. **권한 확인** (Android 13+):
   - 설정 → 앱 → Destiny.OS → 알림 → 허용됨

3. **빌드 재시도**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### 6.4 "Firebase initialization failed"

**원인**: `firebase_options.dart`가 올바르게 생성되지 않았습니다.

**해결 방법**:
```bash
# FlutterFire CLI 재실행
flutterfire configure

# 또는 수동으로 생성
# lib/firebase_options.dart 파일을 확인하고
# apiKey, appId 등의 값이 YOUR_*_KEY가 아닌 실제 값인지 확인
```

---

## 📚 추가 참고 자료

- [Firebase Cloud Messaging 공식 문서](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire 공식 문서](https://firebase.flutter.dev/docs/overview)
- [APNs 설정 가이드](https://firebase.google.com/docs/cloud-messaging/ios/client)
- [Android 알림 설정](https://firebase.google.com/docs/cloud-messaging/android/client)

---

## 🎯 다음 단계

Firebase 설정이 완료되었다면:

1. **서버 연동**: FCM 토큰을 Supabase 또는 백엔드 서버에 저장
2. **예약 알림**: Cloud Functions로 매일 아침 운세 알림 자동 발송
3. **개인화**: 사용자별 맞춤 알림 설정
4. **딥링크**: 알림 탭 시 특정 화면으로 이동

---

**Made with ❤️ and Firebase**
