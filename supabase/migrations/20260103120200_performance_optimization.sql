-- =====================================================
-- 성능 최적화 및 모니터링 인덱스 추가
-- =====================================================

-- 1. user_results 성능 인덱스
-- firebase_uid 조회 최적화 (이미 UNIQUE 인덱스가 있지만 명시적으로 추가)
CREATE INDEX IF NOT EXISTS idx_user_results_firebase_uid
  ON user_results(firebase_uid)
  WHERE firebase_uid IS NOT NULL;

-- created_at DESC 정렬 최적화 (어드민 페이지용)
CREATE INDEX IF NOT EXISTS idx_user_results_created_at_desc
  ON user_results(created_at DESC);

-- MBTI 필터링 최적화
CREATE INDEX IF NOT EXISTS idx_user_results_mbti
  ON user_results(mbti)
  WHERE mbti IS NOT NULL;

-- 성별 필터링 최적화
CREATE INDEX IF NOT EXISTS idx_user_results_gender
  ON user_results(gender);

-- 음력/양력 필터링 최적화
CREATE INDEX IF NOT EXISTS idx_user_results_is_lunar
  ON user_results(is_lunar);

-- 2. compatibility_results 성능 인덱스
-- user_result_id + created_at 복합 인덱스 (가장 많이 사용되는 쿼리)
CREATE INDEX IF NOT EXISTS idx_compatibility_user_result_created_at
  ON compatibility_results(user_result_id, created_at DESC);

-- partner_name 검색 최적화 (부분 일치 검색용)
-- pg_trgm 확장 활성화 시도
DO $$
BEGIN
  CREATE EXTENSION IF NOT EXISTS pg_trgm;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'pg_trgm extension not available, skipping GIN index';
END $$;

-- GIN 인덱스 생성 (pg_trgm이 있을 때만)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_trgm') THEN
    CREATE INDEX IF NOT EXISTS idx_compatibility_partner_name
      ON compatibility_results USING gin(partner_name gin_trgm_ops)
      WHERE partner_name IS NOT NULL;
  ELSE
    -- 대체: 일반 B-tree 인덱스 (완전 일치 검색용)
    CREATE INDEX IF NOT EXISTS idx_compatibility_partner_name
      ON compatibility_results(partner_name)
      WHERE partner_name IS NOT NULL;
  END IF;
END $$;

-- overall_score 범위 검색 최적화 (점수별 필터링용)
CREATE INDEX IF NOT EXISTS idx_compatibility_overall_score
  ON compatibility_results(overall_score DESC);

-- 3. 통계 정보 갱신
ANALYZE user_results;
ANALYZE compatibility_results;

-- 4. 주석 추가
COMMENT ON INDEX idx_user_results_firebase_uid IS
  'Firebase UID 조회 성능 최적화';

COMMENT ON INDEX idx_user_results_created_at_desc IS
  '최신순 정렬 성능 최적화 (어드민 페이지)';

COMMENT ON INDEX idx_user_results_mbti IS
  'MBTI 필터링 성능 최적화';

COMMENT ON INDEX idx_compatibility_user_result_created_at IS
  '사용자별 궁합 기록 조회 성능 최적화 (가장 많이 사용되는 쿼리)';

COMMENT ON INDEX idx_compatibility_overall_score IS
  '궁합 점수별 정렬 및 필터링 성능 최적화';

-- 5. 성능 모니터링 뷰 생성
CREATE OR REPLACE VIEW v_compatibility_stats AS
SELECT
  DATE(created_at) AS analysis_date,
  COUNT(*) AS total_analyses,
  AVG(overall_score)::NUMERIC(5,2) AS avg_score,
  MAX(overall_score) AS max_score,
  MIN(overall_score) AS min_score,
  COUNT(DISTINCT user_result_id) AS unique_users,
  COUNT(CASE WHEN overall_score >= 80 THEN 1 END) AS high_compatibility_count,
  COUNT(CASE WHEN overall_score < 40 THEN 1 END) AS low_compatibility_count
FROM compatibility_results
GROUP BY DATE(created_at)
ORDER BY analysis_date DESC;

COMMENT ON VIEW v_compatibility_stats IS
  '일별 궁합 분석 통계 (성능 모니터링용)';

-- 6. 중복 검사 뷰
CREATE OR REPLACE VIEW v_duplicate_firebase_uids AS
SELECT
  firebase_uid,
  COUNT(*) AS duplicate_count,
  ARRAY_AGG(id ORDER BY created_at DESC) AS user_result_ids,
  MIN(created_at) AS first_created,
  MAX(created_at) AS last_created
FROM user_results
WHERE firebase_uid IS NOT NULL
GROUP BY firebase_uid
HAVING COUNT(*) > 1;

COMMENT ON VIEW v_duplicate_firebase_uids IS
  'Firebase UID 중복 검사 뷰 (데이터 정합성 모니터링용)';
