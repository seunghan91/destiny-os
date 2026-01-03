# firebase_uid Field Status

## 현황
✅ **이미 구현됨 - 추가 작업 불필요**

## 필드 정보

| 항목 | 값 |
|------|-----|
| **필드명** | `firebase_uid` |
| **테이블** | `user_results` |
| **데이터타입** | `uuid` (또는 text) |
| **설명** | Firebase Authentication 사용자의 고유 ID |
| **저장 시점** | 운세 분석 완료 후 (DestinyBloc) |

## 저장 위치

### DestinyBloc (`lib/features/saju/presentation/bloc/destiny_bloc.dart`)
```dart
final response = await supabase.from('user_results').insert({
  'firebase_uid': user?.id,  // ✅ Firebase Auth UID 저장
  'birth_date': event.birthDateTime.toIso8601String(),
  'birth_hour': event.birthDateTime.hour,
  'is_lunar': event.isLunar,
  'gender': event.gender,
  'mbti': event.mbtiType,
  'name': event.name,
  'created_at': DateTime.now().toIso8601String(),
}).select('id');
```

## 사용 예시

### Admin 페이지에서 조회
```dart
final user = _users[index];
// firebase_uid는 각 레코드에 포함되어 있음
print(user['firebase_uid']);  // Firebase UID
```

## 보안 참고사항

- Firebase UID는 고유 식별자이므로 민감한 정보
- RLS 정책에서 `firebase_uid`를 기반으로 접근 제어 가능
- Admin 페이지에서 조회할 때 적절한 인증/인가 확인 필수

## 추가 필드 확인

현재 `user_results` 테이블 스키마:
- ✅ `id` (primary key)
- ✅ `firebase_uid` (Firebase Auth ID)
- ✅ `birth_date` (생년월일)
- ✅ `birth_hour` (출생 시간)
- ✅ `is_lunar` (음력 여부)
- ✅ `gender` (성별)
- ✅ `mbti` (MBTI 타입)
- ✅ `name` (이름)
- ✅ `created_at` (생성 시간)
- 🟡 `use_night_subhour` (야자시 사용 여부 - **추가 필요**, 별도 migration으로 처리)
