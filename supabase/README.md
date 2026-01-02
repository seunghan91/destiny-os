# Supabase Setup for Destiny.OS

토스페이먼츠 결제 연동 Edge Functions 및 데이터베이스 스키마

## 📂 프로젝트 구조

```
supabase/
├── functions/                 # Edge Functions
│   ├── confirm-payment/       # 결제 승인
│   ├── create-subscription/   # 구독 생성
│   ├── process-billing/       # 정기 결제
│   └── webhook/               # 웹훅 수신
├── migrations/                # DB 마이그레이션
└── DEPLOYMENT_GUIDE.md        # 배포 가이드
```

---

## 🚀 Edge Functions (결제 시스템)

### Functions 목록

| Function | 목적 | 엔드포인트 |
|----------|------|-----------|
| `confirm-payment` | 결제 승인 | `POST /functions/v1/confirm-payment` |
| `create-subscription` | 구독 생성 | `POST /functions/v1/create-subscription` |
| `process-billing` | 정기 결제 | Cron Job (자동) |
| `webhook` | 웹훅 수신 | `POST /functions/v1/webhook` |

### 빠른 배포

```bash
# 모든 함수 배포
supabase functions deploy

# 로컬 테스트
supabase functions serve
```

**상세 가이드**: [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)
**설계 문서**: [TOSS_PAYMENTS_INTEGRATION.md](../docs/TOSS_PAYMENTS_INTEGRATION.md)

---

## 🎯 Migration 실행 방법

### 방법 1: Supabase 대시보드 (권장)

1. 브라우저에서 Supabase SQL Editor 열기:
   ```
   https://supabase.com/dashboard/project/rmqsukldnmileszpndgh/sql/new
   ```

2. `migrations/20260101_create_consultations.sql` 파일 내용 복사

3. SQL Editor에 붙여넣기

4. **Run** 버튼 클릭

### 방법 2: Supabase CLI (로컬)

```bash
# 1. Supabase 로그인 (브라우저 인증)
supabase login

# 2. 프로젝트 연결
supabase link --project-ref rmqsukldnmileszpndgh

# 3. Migration 실행
supabase db push
```

## 📊 데이터베이스 스키마

### `consultations` 테이블

| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| `id` | UUID | 기본 키 (자동 생성) |
| `user_id` | TEXT | 기기 ID 또는 사용자 ID |
| `saju_info` | JSONB | 사주 정보 (생년월일, 시간 등) |
| `mbti_type` | TEXT | MBTI 유형 (예: INFP) |
| `consultation_type` | TEXT | 상담 타입 (saju/mbti/combined/compatibility) |
| `messages` | JSONB | 상담 대화 내역 배열 |
| `fortune_score` | INTEGER | 운세 점수 (0-100) |
| `created_at` | TIMESTAMP | 생성일 |
| `updated_at` | TIMESTAMP | 수정일 |

### 인덱스
- `idx_consultations_user_id`: 사용자별 조회 최적화
- `idx_consultations_created_at`: 생성일 기준 정렬 최적화
- `idx_consultations_type`: 상담 타입별 조회 최적화
- `idx_consultations_mbti`: MBTI 타입별 조회 최적화

### RLS (Row Level Security)
- ✅ **SELECT**: 모든 사용자 조회 가능 (익명 포함)
- ✅ **INSERT**: 모든 사용자 생성 가능 (익명 포함)
- 🔒 **UPDATE**: 자신의 기록만 수정 가능
- 🔒 **DELETE**: 자신의 기록만 삭제 가능

## 🧪 테스트 쿼리

### 상담 기록 생성
```sql
INSERT INTO consultations (
  user_id,
  saju_info,
  mbti_type,
  consultation_type,
  messages,
  fortune_score
) VALUES (
  'test-device-123',
  '{"birth_date": "1990-05-15", "birth_time": "14:30", "gender": "M"}'::jsonb,
  'INFP',
  'combined',
  '[{"role": "user", "content": "오늘의 운세는?", "timestamp": "2026-01-01T00:00:00Z"}]'::jsonb,
  85
);
```

### 상담 기록 조회
```sql
-- 모든 상담 기록
SELECT * FROM consultations ORDER BY created_at DESC;

-- 특정 사용자의 상담 기록
SELECT * FROM consultations WHERE user_id = 'test-device-123';

-- MBTI 타입별 평균 운세 점수
SELECT mbti_type, AVG(fortune_score) as avg_score
FROM consultations
WHERE mbti_type IS NOT NULL
GROUP BY mbti_type;
```

## 🔑 환경 변수 설정

`.env` 파일에 다음 값이 설정되어 있는지 확인:

```bash
SUPABASE_URL=https://rmqsukldnmileszpndgh.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 📱 Flutter에서 사용하기

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

// 상담 기록 저장
final response = await Supabase.instance.client
  .from('consultations')
  .insert({
    'user_id': 'device-123',
    'saju_info': {
      'birth_date': '1990-05-15',
      'birth_time': '14:30',
      'gender': 'M',
    },
    'mbti_type': 'INFP',
    'consultation_type': 'combined',
    'messages': [
      {'role': 'user', 'content': '오늘의 운세는?'},
    ],
    'fortune_score': 85,
  });

// 상담 기록 조회
final data = await Supabase.instance.client
  .from('consultations')
  .select()
  .eq('user_id', 'device-123')
  .order('created_at', ascending: false);
```

## 🚀 다음 단계

1. ✅ Migration 실행 완료
2. 🔄 Flutter 앱에서 Supabase 연동 테스트
3. 📊 상담 기록 저장/조회 기능 구현
4. 🎨 UI에 상담 기록 표시
