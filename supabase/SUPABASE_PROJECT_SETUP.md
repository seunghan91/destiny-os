# Supabase 프로젝트 생성 가이드

## 📋 목차

1. [Supabase 계정 생성](#supabase-계정-생성)
2. [새 프로젝트 생성](#새-프로젝트-생성)
3. [프로젝트 설정](#프로젝트-설정)
4. [API 키 및 URL 확인](#api-키-및-url-확인)
5. [데이터베이스 설정](#데이터베이스-설정)
6. [로컬 환경 설정](#로컬-환경-설정)

---

## Supabase 계정 생성

### 1. Supabase 웹사이트 접속

https://supabase.com 접속

### 2. 회원가입

**방법 1: GitHub 계정으로 가입 (권장)**
- "Start your project" 클릭
- "Continue with GitHub" 선택
- GitHub 계정 연동 승인

**방법 2: 이메일로 가입**
- 이메일 주소 입력
- 비밀번호 설정
- 이메일 인증 완료

---

## 새 프로젝트 생성

### 1. 대시보드 접속

로그인 후 자동으로 대시보드로 이동

### 2. "New Project" 클릭

좌측 상단 또는 중앙의 "New Project" 버튼 클릭

### 3. 프로젝트 정보 입력

#### mbti_luck 프로젝트 설정 예시

| 항목 | 값 | 설명 |
|------|-----|------|
| **Organization** | 기존 조직 선택 또는 새로 생성 | 무료 플랜은 조직당 2개 프로젝트 |
| **Project name** | `destiny-os-production` | 프로젝트 이름 |
| **Database Password** | 강력한 비밀번호 생성 | **반드시 안전하게 보관** |
| **Region** | `Northeast Asia (Seoul)` | 한국 서울 리전 선택 (낮은 지연시간) |
| **Pricing Plan** | `Free` | 무료 플랜 (프로토타입용) |

```
프로젝트명 추천:
- 개발: destiny-os-dev
- 스테이징: destiny-os-staging
- 프로덕션: destiny-os-production
```

### 4. "Create new project" 클릭

프로젝트 생성 중... (약 2-3분 소요)

---

## 프로젝트 설정

### 1. 프로젝트 대시보드 확인

생성 완료 후 자동으로 프로젝트 대시보드로 이동

### 2. 주요 메뉴 소개

```
├── Home - 프로젝트 개요 및 통계
├── Table Editor - 데이터베이스 테이블 관리
├── SQL Editor - SQL 쿼리 실행
├── Database - 스키마, 백업, 연결 설정
├── Authentication - 사용자 인증 관리
├── Storage - 파일 저장소
├── Edge Functions - 서버리스 함수
├── Logs - 로그 및 모니터링
└── Settings - 프로젝트 설정
```

---

## API 키 및 URL 확인

### 1. Settings > API 메뉴 이동

좌측 사이드바 하단 **Settings** → **API** 클릭

### 2. Project URL 복사

```
https://YOUR_PROJECT_REF.supabase.co
```

예시:
```
https://rmqsukldnmileszpndgh.supabase.co
```

### 3. API Keys 복사

#### anon (public) key
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```
- **용도**: Flutter 앱에서 사용 (공개 가능)
- **권한**: RLS 정책에 따른 제한된 접근

#### service_role key
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```
- **용도**: Edge Functions, 백엔드에서만 사용
- **권한**: 모든 데이터 접근 가능 (RLS 우회)
- ⚠️ **절대 클라이언트에 노출 금지**

### 4. `.env` 파일에 저장

Flutter 프로젝트 루트에 `.env` 파일 생성:

```bash
# Supabase Configuration
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here

# 토스페이먼츠 (나중에 추가)
TOSS_CLIENT_KEY=
TOSS_SECRET_KEY=
```

⚠️ **`.env` 파일을 `.gitignore`에 추가**:

```gitignore
# .gitignore
.env
.env.local
.env.*.local
```

---

## 데이터베이스 설정

### 1. SQL Editor 열기

좌측 메뉴 **SQL Editor** → **New query** 클릭

### 2. 결제 시스템 테이블 생성

`docs/TOSS_PAYMENTS_INTEGRATION.md` 파일의 SQL 스크립트 복사

또는 `supabase/migrations/` 폴더의 마이그레이션 파일 실행

```sql
-- 1. users 테이블 확장
ALTER TABLE users
ADD COLUMN subscription_tier VARCHAR(20) DEFAULT 'free',
ADD COLUMN subscription_status VARCHAR(20) DEFAULT 'inactive',
-- ... (전체 SQL은 TOSS_PAYMENTS_INTEGRATION.md 참조)
```

### 3. Run 버튼 클릭

SQL 실행 후 성공 메시지 확인

### 4. Table Editor에서 테이블 확인

좌측 메뉴 **Table Editor** → 생성된 테이블 확인:
- `products`
- `payments`
- `subscriptions`
- `subscription_payments`
- `webhook_events`

---

## 로컬 환경 설정

### 1. Supabase CLI 설치

```bash
# macOS (Homebrew)
brew install supabase/tap/supabase

# npm (모든 OS)
npm install -g supabase

# 설치 확인
supabase --version
```

### 2. Supabase 로그인

```bash
supabase login
```

브라우저에서 자동으로 인증 페이지 열림 → 승인

### 3. 프로젝트 연결

```bash
cd /Users/seunghan/mbti_luck

# 프로젝트 연결
supabase link --project-ref YOUR_PROJECT_REF

# 예시:
# supabase link --project-ref rmqsukldnmileszpndgh
```

**Project Ref 확인 방법**:
- Supabase 대시보드 → Settings → General
- Project Reference ID 복사

### 4. 연결 확인

```bash
supabase status
```

출력 예시:
```
         API URL: https://YOUR_PROJECT_REF.supabase.co
          DB URL: postgresql://...
      Studio URL: https://supabase.com/dashboard/project/YOUR_PROJECT_REF
    Inbucket URL: http://...
```

### 5. Flutter 프로젝트에 Supabase 초기화

`lib/core/config/supabase_config.dart` 생성:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }
}

// 전역 인스턴스
final supabase = Supabase.instance.client;
```

`lib/main.dart`에서 초기화:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 파일 로드
  await dotenv.load(fileName: '.env');

  // Supabase 초기화
  await SupabaseConfig.initialize();

  runApp(MyApp());
}
```

---

## 프로젝트 설정 체크리스트

### ✅ 완료 확인

- [ ] Supabase 계정 생성
- [ ] 새 프로젝트 생성 (서울 리전)
- [ ] Database Password 안전하게 저장
- [ ] Project URL 복사
- [ ] anon key 복사
- [ ] service_role key 복사
- [ ] `.env` 파일 생성 및 키 저장
- [ ] `.gitignore`에 `.env` 추가
- [ ] 결제 시스템 테이블 생성 (SQL 실행)
- [ ] Supabase CLI 설치
- [ ] 로컬 프로젝트 연결
- [ ] Flutter 앱에서 Supabase 초기화

---

## 무료 플랜 제한사항

Supabase 무료 플랜의 주요 제한:

| 항목 | 무료 플랜 | Pro 플랜 |
|------|----------|---------|
| **프로젝트 수** | 조직당 2개 | 무제한 |
| **데이터베이스** | 500MB | 8GB |
| **파일 스토리지** | 1GB | 100GB |
| **월간 대역폭** | 5GB | 250GB |
| **Edge Functions** | 500K 호출/월 | 2M 호출/월 |
| **일시 중지** | 7일 비활성 시 | 없음 |

⚠️ **무료 프로젝트는 7일 동안 활동이 없으면 자동으로 일시 중지됩니다.**
- 대시보드 접속 또는 API 호출로 재활성화 가능

---

## 다음 단계

1. ✅ **Supabase 프로젝트 생성 완료**
2. ⏳ **Edge Functions 배포** ([DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) 참조)
3. ⏳ **토스페이먼츠 연동 테스트**
4. ⏳ **Flutter 앱 결제 기능 구현**

---

## 문제 해결

### Q: 프로젝트가 생성되지 않아요
- 이메일 인증을 완료했는지 확인
- 무료 플랜은 조직당 2개 프로젝트 제한
- 기존 프로젝트 삭제 후 재시도

### Q: API 키가 보이지 않아요
- Settings → API 메뉴 확인
- 페이지 새로고침 시도

### Q: Database Password를 잊어버렸어요
- Settings → Database → Database Settings
- "Reset database password" 클릭
- 새 비밀번호 생성 및 저장

### Q: SQL 실행 중 오류가 발생해요
- 테이블이 이미 존재하는지 확인
- SQL 문법 오류 확인
- Logs 메뉴에서 상세 오류 확인

---

**작성일**: 2026-01-01
**버전**: 1.0.0
