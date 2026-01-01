# 환경 변수 설정 가이드

Destiny.OS 앱에서 AI 상담 기능을 사용하려면 API 키를 설정해야 합니다.

---

## 📋 필요한 API 키

### 1️⃣ BizRouter API (권장) ⭐

**BizRouter란?**
- OpenAI, Google AI, Anthropic 등 여러 AI 모델을 하나의 API로 사용
- 가격이 저렴하고 관리가 편리
- GPT-4o (상담용) + Gemini 2.5 Flash (분석용) 조합 사용

**가입 방법:**
1. https://bizrouter.ai 접속
2. 회원가입 후 대시보드 이동
3. API Keys 메뉴에서 키 생성
4. 생성된 키를 복사

**가격:**
- GPT-4o: 입력 $2.5/1M 토큰, 출력 $10/1M 토큰
- Gemini 2.5 Flash: 입력 $0.075/1M 토큰, 출력 $0.3/1M 토큰
- 예상 비용: 상담 1회당 약 $0.01~0.03

---

### 2️⃣ OpenAI API (폴백용 - 선택)

**언제 필요한가?**
- BizRouter를 사용하지 않을 경우
- 직접 OpenAI API만 사용하고 싶을 경우

**가입 방법:**
1. https://platform.openai.com 접속
2. 회원가입 후 API Keys 메뉴
3. Create new secret key
4. 생성된 키를 복사 (단 한 번만 표시됨!)

**가격:**
- GPT-4o-mini: 입력 $0.15/1M 토큰, 출력 $0.6/1M 토큰
- 예상 비용: 상담 1회당 약 $0.005~0.015

---

### 3️⃣ Supabase (선택)

**언제 필요한가?**
- 사용자 데이터를 클라우드에 저장하고 싶을 경우
- Edge Functions를 사용하고 싶을 경우
- 현재는 로컬 저장소만 사용하므로 **선택사항**

**가입 방법:**
1. https://supabase.com 접속
2. 프로젝트 생성
3. Settings > API 에서 URL과 anon key 복사

---

## 🛠️ 설정 방법

### 방법 1: .env 파일 사용 (권장) 👍

로컬 개발에 가장 편리한 방법입니다.

#### 1단계: .env 파일 생성
```bash
# 프로젝트 루트 디렉토리에서
cp .env.example .env
```

#### 2단계: .env 파일 수정
```bash
# .env 파일을 텍스트 에디터로 열고 실제 키 입력

# BizRouter (권장)
BIZROUTER_API_KEY=your_actual_bizrouter_api_key_here

# OpenAI (선택 - BizRouter가 없을 경우)
OPENAI_API_KEY=your_actual_openai_api_key_here

# Supabase (선택)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_actual_supabase_anon_key_here

# 개발 모드 (API 실패 시 로컬 응답 사용)
USE_LOCAL_FALLBACK=true
```

#### 3단계: 앱 실행
```bash
flutter run
```

✅ **완료!** .env 파일이 자동으로 로드됩니다.

---

### 방법 2: --dart-define 사용 (배포용)

릴리즈 빌드나 CI/CD에서 사용하는 방법입니다.

```bash
# iOS 실행
flutter run --dart-define=BIZROUTER_API_KEY=your_key_here

# Android 실행
flutter run --dart-define=BIZROUTER_API_KEY=your_key_here

# 여러 키 설정
flutter run \
  --dart-define=BIZROUTER_API_KEY=your_bizrouter_key \
  --dart-define=OPENAI_API_KEY=your_openai_key \
  --dart-define=SUPABASE_ANON_KEY=your_supabase_key

# 릴리즈 빌드
flutter build apk --release \
  --dart-define=BIZROUTER_API_KEY=your_key_here
```

---

### 방법 3: 환경변수 없이 로컬 응답만 사용

API 키 없이도 앱은 정상 동작합니다. AI 상담 기능만 로컬 응답으로 대체됩니다.

**로컬 응답 기능:**
- 키워드 기반 지능형 응답
- 이직, 연애, 재물, 건강, 운세 등 카테고리별 답변
- 사주 정보와 MBTI를 고려한 맞춤 조언

```dart
// lib/features/ai_consultation/data/services/ai_consultation_service.dart:234
String _generateLocalResponse(...) {
  // 키워드 기반 응답 생성
}
```

---

## 🔍 API 키 우선순위

시스템은 다음 우선순위로 API 키를 찾습니다:

1. **--dart-define** (최우선)
2. **.env 파일**
3. **기본값** (빈 문자열)

예를 들어:
```bash
# .env 파일에 BIZROUTER_API_KEY=test123

# 이 명령으로 실행하면
flutter run --dart-define=BIZROUTER_API_KEY=production456

# 실제 사용되는 키는: production456 (--dart-define 우선)
```

---

## 🧪 환경변수 확인 방법

앱을 실행하고 콘솔 로그를 확인하세요:

```
✅ .env file loaded successfully
✅ Supabase initialized successfully
```

또는

```
⚠️  .env file not found - using --dart-define or defaults
⚠️  Supabase key not found - running in offline mode
```

---

## 🚨 주의사항

### ⚠️ .env 파일은 Git에 커밋하지 마세요!

`.gitignore`에 이미 추가되어 있습니다:
```gitignore
# Environment variables
.env
.env.local
.env.*.local
```

### ⚠️ API 키 노출 주의

- 공개 저장소에 업로드 금지
- 스크린샷이나 로그에 노출 금지
- 키가 노출되었다면 즉시 재생성

### ⚠️ 프로덕션 빌드

**절대 .env 파일로 프로덕션 빌드하지 마세요!**

프로덕션 빌드는 반드시 `--dart-define` 사용:
```bash
# ❌ 잘못된 방법
flutter build apk --release
# .env 파일이 APK에 포함될 수 있음

# ✅ 올바른 방법
flutter build apk --release \
  --dart-define=BIZROUTER_API_KEY=$BIZROUTER_API_KEY
```

---

## 📊 비용 예상

### 월간 사용자 1,000명 기준

**BizRouter 사용 시:**
- 사용자당 상담 2회
- 1회당 토큰: 입력 500, 출력 300
- GPT-4o: (500 × $2.5 + 300 × $10) / 1M × 2,000 = $8.5/월
- Gemini Flash: 거의 무료 수준
- **총 비용: 약 $10/월**

**OpenAI 직접 사용 시:**
- GPT-4o-mini 사용
- (500 × $0.15 + 300 × $0.6) / 1M × 2,000 = $0.51/월
- **총 비용: 약 $1/월**

---

## 🔧 문제 해결

### Q1. "⚠️  .env file not found" 오류
```bash
# .env 파일이 없는 경우
cp .env.example .env
# 그리고 API 키 입력
```

### Q2. AI 상담이 작동하지 않음
```dart
// lib/core/config/env_config.dart 확인
debugPrint('Has BizRouter: ${EnvConfig.hasBizRouterKey}');
debugPrint('Has OpenAI: ${EnvConfig.hasOpenAiKey}');
```

### Q3. Flutter 재시작 후에도 적용 안됨
```bash
# Clean & rebuild
flutter clean
flutter pub get
flutter run
```

---

## 📚 추가 자료

- [BizRouter 공식 문서](https://docs.bizrouter.ai)
- [OpenAI API 문서](https://platform.openai.com/docs)
- [Supabase 공식 문서](https://supabase.com/docs)
- [flutter_dotenv 패키지](https://pub.dev/packages/flutter_dotenv)

---

**설정 완료 후 AI 상담 기능을 즐겨보세요! 🎉**
