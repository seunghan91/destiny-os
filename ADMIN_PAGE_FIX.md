# 어드민 페이지 궁합 조회 로직 개선

## 🎯 목적
firebase_uid가 같은 사용자의 여러 user_results row가 있을 때, 모든 궁합 기록을 조회하도록 개선

## 📝 수정 위치
파일: `lib/features/admin/presentation/pages/admin_page.dart`
함수: `_showCompatibilityResults()` (약 260-280번 라인)

## 🔧 수정 내용

### 현재 코드 (Line 260-270)
```dart
/// 사용자의 궁합 분석 결과 조회
Future<void> _showCompatibilityResults(
  String userResultId,
  String userName,
) async {
  try {
    final compatibilities = await _supabase!
        .from('compatibility_results')
        .select()
        .eq('user_result_id', userResultId)
        .order('created_at', ascending: false);

    if (!mounted) return;
```

### 수정 후 코드
```dart
/// 사용자의 궁합 분석 결과 조회
Future<void> _showCompatibilityResults(
  String userResultId,
  String userName,
) async {
  try {
    // 1. 해당 user_results의 firebase_uid 확인
    final userResult = await _supabase!
        .from('user_results')
        .select('firebase_uid')
        .eq('id', userResultId)
        .maybeSingle();

    List<dynamic> compatibilities = [];

    // 2. firebase_uid가 있으면 같은 firebase_uid를 가진 모든 user_results의 궁합 기록 조회
    if (userResult != null && userResult['firebase_uid'] != null) {
      final firebaseUid = userResult['firebase_uid'] as String;

      // 같은 firebase_uid를 가진 모든 user_results 찾기
      final allUserResults = await _supabase!
          .from('user_results')
          .select('id')
          .eq('firebase_uid', firebaseUid);

      if (allUserResults.isNotEmpty) {
        final userResultIds = allUserResults
            .map((ur) => ur['id'] as String)
            .toList();

        // 모든 user_result_id에 대한 궁합 기록 조회
        compatibilities = await _supabase!
            .from('compatibility_results')
            .select()
            .in_('user_result_id', userResultIds)
            .order('created_at', ascending: false);
      }
    } else {
      // firebase_uid가 없으면 기존 방식대로 조회
      compatibilities = await _supabase!
          .from('compatibility_results')
          .select()
          .eq('user_result_id', userResultId)
          .order('created_at', ascending: false);
    }

    if (!mounted) return;
```

## 🔍 수정 내용 설명

### 기존 문제
- 어드민 페이지에서 사용자 클릭 시 해당 `user_results.id`만으로 궁합 기록 조회
- 같은 사용자(firebase_uid)가 여러 `user_results` row를 가진 경우, 일부 기록만 보임

### 개선 사항
1. **firebase_uid 확인**: 클릭한 user_results의 firebase_uid 조회
2. **관련 row 검색**: 같은 firebase_uid를 가진 모든 user_results 찾기
3. **통합 조회**: 모든 관련 user_result_id의 궁합 기록을 하나로 합쳐서 조회
4. **호환성 유지**: firebase_uid가 없는 비로그인 사용자는 기존 방식대로 동작

### 장점
- ✅ 중복 row 문제 해결
- ✅ 모든 궁합 기록 표시
- ✅ 비로그인 사용자 호환성 유지
- ✅ 성능 영향 최소화 (2-3번의 쿼리만 추가)

## 📌 주의사항
- Linter/Formatter가 자동 실행되는 환경에서는 파일 저장 시 자동 포맷팅됨
- 수정 후 `flutter analyze` 실행하여 문법 오류 확인
- 테스트: 로그인 사용자의 궁합 기록이 모두 표시되는지 확인

## 🚀 적용 방법
1. 에디터에서 `lib/features/admin/presentation/pages/admin_page.dart` 열기
2. Line 260-270 부분 찾기 (함수명: `_showCompatibilityResults`)
3. 위의 "수정 후 코드"로 교체
4. 저장 후 `flutter analyze` 실행
5. 앱 재시작 후 테스트
