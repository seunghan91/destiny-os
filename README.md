# Destiny.OS

> 사주(四柱) + MBTI 하이브리드 운세 앱

**Destiny.OS**는 전통적인 사주 명리학과 현대적인 MBTI 성격 유형을 결합하여 개인화된 운세 분석을 제공하는 Flutter 앱입니다.

## ✨ 주요 기능

- 🔮 **사주 분석**: 만세력 기반 정확한 사주 명식 산출 (60갑자, 24절기, 십성)
- 🧩 **MBTI Gap 분석**: 사주에서 도출한 MBTI vs 실제 MBTI 비교
- 🐴 **2026년 운세**: 병오년(丙午年) 화기 에너지 분석
- ⏱️ **대운 타임라인**: 10년 단위 인생 흐름 예측 (순행/역행)
- 💕 **궁합 분석**: 천간합, 육합, 삼합, 충, 형, 파, 해 기반 관계 분석
- 🤖 **AI 상담**: GPT-4o 또는 Gemini 기반 맞춤 상담
- 🔔 **푸시 알림**: Firebase Cloud Messaging 기반 일일 운세 알림
- 📤 **공유 기능**: 결과를 이미지로 저장 및 SNS 공유

## 🚀 시작하기

### 1. 프로젝트 클론

```bash
git clone https://github.com/your-username/mbti_luck.git
cd mbti_luck
```

### 2. 패키지 설치

```bash
flutter pub get
```

### 3. 환경 변수 설정 (선택)

AI 상담 기능을 사용하려면 API 키가 필요합니다.

```bash
# .env 파일 생성
cp .env.example .env

# .env 파일을 열고 API 키 입력
# BIZROUTER_API_KEY=your_key_here
```

**자세한 설정 방법**: [환경 변수 설정 가이드](docs/ENV_SETUP.md)

> **참고**: API 키 없이도 앱은 정상 작동하며, AI 상담 기능만 로컬 응답으로 대체됩니다.

### 4. Firebase 설정 (선택)

푸시 알림 기능을 사용하려면 Firebase 프로젝트 설정이 필요합니다.

```bash
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 프로젝트 구성
flutterfire configure
```

**자세한 설정 방법**: [Firebase 설정 가이드](docs/FIREBASE_SETUP.md)

> **참고**: Firebase 설정 없이도 앱은 정상 작동하며, 푸시 알림 기능만 비활성화됩니다.

### 5. 앱 실행

```bash
# iOS
flutter run

# Android
flutter run

# 웹 (개발용)
flutter run -d chrome
```

## 📚 프로젝트 문서

- [프로젝트 로드맵](docs/todo/ROADMAP.md) - 구현 현황 및 계획
- [PRD (Product Requirements Document)](docs/todo/PRD.md) - 제품 요구사항
- [기술 명세서](docs/todo/TECH_SPEC.md) - 기술 스택 및 아키텍처
- [환경 변수 설정](docs/ENV_SETUP.md) - API 키 설정 가이드
- [Firebase 설정](docs/FIREBASE_SETUP.md) - 푸시 알림 설정 가이드
- [기능 명세](docs/todo/01-features.md) - 상세 기능 설명
- [데이터 모델](docs/todo/03-data-model.md) - 데이터베이스 스키마

## 🛠️ 기술 스택

### Core
- **Flutter** 3.10+ / Dart 3.10+
- **Clean Architecture** (Presentation - Domain - Data)

### State Management
- **flutter_bloc** 9.1.1 - BLoC 패턴
- **get_it** 8.0.3 - 의존성 주입

### Navigation & UI
- **go_router** 15.1.2 - 선언적 라우팅
- **fl_chart** 0.70.2 - 차트 시각화
- **google_fonts** 6.2.1 - Pretendard 폰트

### Backend & Storage
- **supabase_flutter** 2.8.3 - 백엔드 서비스 (선택)
- **firebase_core** 3.8.1 - Firebase 기본 SDK
- **firebase_messaging** 15.1.5 - 푸시 알림 (FCM)
- **shared_preferences** 2.3.5 - 로컬 저장소
- **flutter_secure_storage** 9.2.4 - 보안 저장소

### Business Logic
- **lunar** 1.3.12 - 만세력 계산 (핵심 라이브러리)
- **dio** 5.8.0+1 - HTTP 클라이언트
- **dartz** 0.10.1 - 함수형 프로그래밍

### AI Integration
- **BizRouter** (권장) - GPT-4o + Gemini 2.5 Flash
- **OpenAI API** (폴백) - GPT-4o-mini

## 📁 프로젝트 구조

```
lib/
├── app/                    # 앱 진입점
├── core/                   # 공통 기능
│   ├── config/            # 환경 설정
│   ├── constants/         # 상수 (색상, 폰트, 사주 상수)
│   ├── di/                # 의존성 주입
│   ├── router/            # 라우팅
│   ├── theme/             # 테마 시스템
│   └── utils/             # 유틸리티
├── features/              # 기능별 모듈 (Clean Architecture)
│   ├── saju/              # 사주 분석
│   ├── mbti/              # MBTI 분석
│   ├── fortune_2026/      # 2026년 운세
│   ├── daewoon/           # 대운 타임라인
│   ├── compatibility/     # 궁합 분석
│   ├── ai_consultation/   # AI 상담
│   ├── onboarding/        # 온보딩
│   ├── share/             # 공유 기능
│   └── settings/          # 설정
└── shared/                # 공유 위젯
```

## 🎨 디자인 시스템

- **컬러**: Toss 디자인 시스템 기반
- **타이포그래피**: Pretendard (9개 웨이트)
- **애니메이션**: flutter_animate 4.5.2

## 🧪 테스트

```bash
# Unit 테스트
flutter test

# Widget 테스트
flutter test test/widget/

# Integration 테스트
flutter test integration_test/
```

## 📦 빌드

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# 환경 변수와 함께 빌드
flutter build apk --release \
  --dart-define=BIZROUTER_API_KEY=your_key_here
```

## 🤝 기여하기

이 프로젝트는 개인 프로젝트입니다. 버그 리포트나 기능 제안은 환영합니다!

## 📄 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다.

## 📞 문의

- 이메일: your-email@example.com
- GitHub: [@your-username](https://github.com/your-username)

---

**Made with ❤️ and Flutter**
