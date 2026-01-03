-- =====================================================
-- user_results.firebase_uid에 UNIQUE 제약 추가
-- 중복 방지 및 데이터 무결성 강화
-- =====================================================

-- 1. 기존 중복 데이터 정리 (가장 최신 것만 남기고 나머지 삭제)
-- firebase_uid가 중복된 경우, created_at이 가장 최신인 row만 유지
DO $$
DECLARE
  duplicate_uid TEXT;
  keep_id UUID;
BEGIN
  -- firebase_uid가 중복된 케이스 찾기
  FOR duplicate_uid IN
    SELECT firebase_uid
    FROM user_results
    WHERE firebase_uid IS NOT NULL
    GROUP BY firebase_uid
    HAVING COUNT(*) > 1
  LOOP
    -- 가장 최신 row의 id 찾기
    SELECT id INTO keep_id
    FROM user_results
    WHERE firebase_uid = duplicate_uid
    ORDER BY created_at DESC
    LIMIT 1;

    -- 나머지 row 삭제 (CASCADE로 관련 데이터도 삭제됨)
    DELETE FROM user_results
    WHERE firebase_uid = duplicate_uid
      AND id != keep_id;

    RAISE NOTICE 'Cleaned up duplicates for firebase_uid: %', duplicate_uid;
  END LOOP;
END $$;

-- 2. UNIQUE 제약 추가 (firebase_uid가 NULL이 아닌 경우에만)
-- NULL 값은 중복 허용 (비로그인 사용자)
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_results_firebase_uid_unique
  ON user_results(firebase_uid)
  WHERE firebase_uid IS NOT NULL;

-- 3. 주석 추가
COMMENT ON INDEX idx_user_results_firebase_uid_unique IS
  'Firebase UID의 유일성을 보장하는 인덱스. NULL 값은 제외하여 비로그인 사용자의 중복 생성을 허용합니다.';
