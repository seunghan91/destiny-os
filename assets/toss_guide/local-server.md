---
url: 'https://developers-apps-in-toss.toss.im/development/local-server.md'
description: >-
  앱인토스 개발 서버를 연결하는 방법을 안내합니다. Metro 서버 실행, iOS/Android 시뮬레이터 및 실기기에서 로컬 서버 연결
  방법을 확인하세요.
---

# 개발 서버 연결하기

::: tip 준비가 필요해요

개발 서버를 연결하려면 **앱인토스 샌드박스 앱**이 필요해요. 아래 가이드를 먼저 확인해주세요.

* [iOS 환경설정 문서 바로가기](/development/client/ios)
* [Android 환경설정 문서 바로가기](/development/client/android)

:::

## Metro 서버 실행하기

Bedrock으로 스캐폴딩된 서비스는 `dev` 스크립트를 사용해서 로컬 서버를 실행할 수 있어요. 서비스의 루트 디렉터리에서 아래 명령어를 실행해 주세요.

::: code-group

```sh [npm]
npm run dev
```

```sh [pnpm]
pnpm run dev
```

```sh [yarn]
yarn dev
```

:::

명령어를 실행하면 아래와 같은 화면이 표시돼요.

![Metro 실행 예시](/assets/local-develop-js-1.B_LK2Zlw.png)

## iOS 시뮬레이터에서 실행하기

1. **앱인토스 샌드박스 앱**을 실행해요.
2. 샌드박스 앱에서 스킴을 실행해요. 예를 들어 서비스 이름이 `kingtoss`라면, `intoss://kingtoss`를 입력하고 "Bedrock 열기" 버튼을 눌러주세요.
3. Metro 서버가 실행 중이라면 시뮬레이터와 자동으로 연결돼요. 화면 상단에 `Bundling {n}%...`가 표시되면 연결이 성공한 거예요.

아래는 iOS 시뮬레이터에서 로컬 서버를 연결한 후 "Hello Bedrock!"을 표시하는 예시예요.

## iOS 실기기에서 실행하기

### 서버 주소 입력하기

아이폰에서 **앱인토스 샌드박스 앱**을 실행하려면 로컬 서버와 같은 와이파이에 연결되어 있어야 해요. 아래 단계를 따라 설정하세요.

1. **샌드박스 앱**을 실행하면 **"로컬 네트워크" 권한 요청 메시지**가 표시돼요. 이때 **"허용"** 버튼을 눌러주세요.

2) **샌드박스 앱**에서 서버 주소를 입력하는 화면이 나타나요.

3) 컴퓨터에서 로컬 서버 IP 주소를 확인하고, 해당 주소를 입력한 뒤 저장해주세요.

   * IP 주소는 한 번 저장하면 앱을 다시 실행해도 변경되지 않아요.
   * macOS를 사용하는 경우, 터미널에서 `ipconfig getifaddr en0` 명령어로 로컬 서버의 IP 주소를 확인할 수 있어요.

4) **"Bedrock 열기"** 버튼을 눌러주세요.

5) 화면 상단에 `Bundling {n}%...` 텍스트가 표시되면 로컬 서버에 성공적으로 연결된 거예요.

::: details "로컬 네트워크"를 수동으로 허용하는 방법
**"로컬 네트워크" 권한을 허용하지 못한 경우, 아래 방법으로 수동 설정이 가능해요.**

1. 아이폰의 \[설정] 앱에서 **"앱인토스"** 를 검색해 이동해요.
2. **"로컬 네트워크"** 옵션을 찾아 켜주세요.

:::

## Android에서 실행하기

### Android 실기기 또는 에뮬레이터 연결하기

1. Android 실기기(휴대폰 또는 태블릿)를 컴퓨터와 USB로 연결하세요. ([USB 연결 가이드](/development/client/android.html#기기-연결하기))

2. `adb` 명령어를 사용해서 `8081` 포트와 `5173`포트를 연결하고 연결 상태를 확인해요.

   **8081 포트, 5173 포트 연결하기**

   기기가 하나만 연결되어 있다면 아래 명령어만 실행해도 돼요.

   ```shell
   adb reverse tcp:8081 tcp:8081
   adb reverse tcp:5173 tcp:5173
   ```

   특정 기기를 연결하려면 `-s` 옵션과 디바이스 아이디를 추가해요.

   ```shell
   adb -s {디바이스아이디} reverse tcp:8081 tcp:8081
   # 예시: adb -s R3CX30039GZ reverse tcp:8081 tcp:8081
   adb -s {디바이스아이디} reverse tcp:5173 tcp:5173
   # 예시: adb -s R3CX30039GZ reverse tcp:5173 tcp:5173
   ```

   **연결 상태 확인하기**

   연결된 기기와 포트를 확인하려면 아래 명령어를 사용하세요.

   ```shell
   adb reverse --list
   # 연결된 경우 예시: UsbFfs tcp:8081 tcp:8081

   ```

   특정 기기를 확인하려면 `-s` 옵션을 추가해요.

   ```shell
   adb -s {디바이스아이디} reverse --list
   # 예시: adb -s R3CX30039GZ reverse --list

   # 연결된 경우 예시: UsbFfs tcp:8081 tcp:8081
   ```

3. **앱인토스 샌드박스 앱**에서 스킴을 실행하세요. 예를 들어, 서비스 이름이 `kingtoss`라면 `intoss://kingtoss`를 입력하고 실행 버튼을 누르세요.

4. Metro 서버가 실행 중이라면 실기기 또는 에뮬레이터와 자동으로 연결돼요. 화면 상단에 번들링 프로세스가 진행 중이면 연결이 완료된 거예요.

   아래는 Android 실기기에서 로컬 서버를 연결한 후 "Hello Bedrock!"을 표시하는 예시예요.

### 자주 쓰는 `adb` 명령어

개발 중에 자주 쓰는 `adb` 명령어를 정리했어요.

#### 연결 끊기

```shell
adb kill-server
```

#### 8081 포트 연결하기

```shell
adb reverse tcp:8081 tcp:8081
adb reverse tcp:5173 tcp:5173
# 특정 기기 연결: adb -s {디바이스아이디} reverse tcp:8081 tcp:8081
```

#### 연결 상태 확인하기

```shell
adb reverse --list
# 특정 기기 확인: adb -s {디바이스아이디} reverse --list
```

### 트러블슈팅

::: details Q. Metro 개발 서버가 열려 있는데 `잠시 문제가 생겼어요`라는 메시지가 표시돼요.

개발 서버에 제대로 연결되지 않은 문제일 수 있어요. `adb` 연결을 끊고 다시 `8081` 포트를 연결하세요.
:::

::: details Q. PC웹에서 Not Found 오류가 발생해요.

8081 포트는 샌드박스 내에서 인식하기 위한 포트예요.\
PC웹에서 8081 포트는 Not Found 오류가 발생해요.
:::
