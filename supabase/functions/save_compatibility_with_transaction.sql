-- =====================================================
-- 궁합 저장 트랜잭션 함수
-- user_results와 compatibility_results를 트랜잭션으로 처리
-- =====================================================

CREATE OR REPLACE FUNCTION save_compatibility_with_transaction(
  p_firebase_uid TEXT,
  p_birth_date TIMESTAMPTZ,
  p_birth_hour INTEGER,
  p_is_lunar BOOLEAN,
  p_gender TEXT,
  p_mbti TEXT,
  p_name TEXT,
  p_partner_name TEXT,
  p_partner_birth_date TIMESTAMPTZ,
  p_partner_birth_hour INTEGER,
  p_partner_gender TEXT,
  p_partner_is_lunar BOOLEAN,
  p_partner_mbti TEXT,
  p_overall_score INTEGER,
  p_saju_score INTEGER,
  p_mbti_score INTEGER,
  p_love_score INTEGER,
  p_marriage_score INTEGER,
  p_business_score INTEGER,
  p_friendship_score INTEGER,
  p_mbti_relationship_type TEXT,
  p_mbti_communication_style TEXT,
  p_mbti_conflict_pattern TEXT,
  p_mbti_common_ground TEXT[],
  p_mbti_differences TEXT[],
  p_day_pillar_analysis JSONB,
  p_branch_relations JSONB,
  p_element_balance JSONB,
  p_stem_relations JSONB,
  p_insights JSONB
)
RETURNS TABLE(
  user_result_id UUID,
  compatibility_result_id UUID,
  success BOOLEAN,
  message TEXT
) AS $$
DECLARE
  v_user_result_id UUID;
  v_compatibility_id UUID;
BEGIN
  -- 1. user_results 처리 (firebase_uid가 있으면 재사용, 없으면 생성)
  IF p_firebase_uid IS NOT NULL THEN
    -- 기존 user_results 찾기
    SELECT id INTO v_user_result_id
    FROM user_results
    WHERE firebase_uid = p_firebase_uid
    LIMIT 1;

    -- 없으면 새로 생성
    IF v_user_result_id IS NULL THEN
      INSERT INTO user_results (
        firebase_uid, birth_date, birth_hour, is_lunar, gender, mbti, name, use_night_subhour, created_at
      )
      VALUES (
        p_firebase_uid, p_birth_date, p_birth_hour, p_is_lunar, p_gender, p_mbti, p_name, FALSE, NOW()
      )
      RETURNING id INTO v_user_result_id;
    END IF;
  ELSE
    -- 비로그인 사용자는 새로 생성
    INSERT INTO user_results (
      birth_date, birth_hour, is_lunar, gender, mbti, name, use_night_subhour, created_at
    )
    VALUES (
      p_birth_date, p_birth_hour, p_is_lunar, p_gender, p_mbti, p_name, FALSE, NOW()
    )
    RETURNING id INTO v_user_result_id;
  END IF;

  -- 2. compatibility_results 저장
  INSERT INTO compatibility_results (
    user_result_id,
    partner_name,
    partner_birth_date,
    partner_birth_hour,
    partner_gender,
    partner_is_lunar,
    partner_mbti,
    overall_score,
    saju_score,
    mbti_score,
    love_score,
    marriage_score,
    business_score,
    friendship_score,
    mbti_relationship_type,
    mbti_communication_style,
    mbti_conflict_pattern,
    mbti_common_ground,
    mbti_differences,
    day_pillar_analysis,
    branch_relations,
    element_balance,
    stem_relations,
    insights,
    created_at
  )
  VALUES (
    v_user_result_id,
    p_partner_name,
    p_partner_birth_date,
    p_partner_birth_hour,
    p_partner_gender,
    p_partner_is_lunar,
    p_partner_mbti,
    p_overall_score,
    p_saju_score,
    p_mbti_score,
    p_love_score,
    p_marriage_score,
    p_business_score,
    p_friendship_score,
    p_mbti_relationship_type,
    p_mbti_communication_style,
    p_mbti_conflict_pattern,
    p_mbti_common_ground,
    p_mbti_differences,
    p_day_pillar_analysis,
    p_branch_relations,
    p_element_balance,
    p_stem_relations,
    p_insights,
    NOW()
  )
  RETURNING id INTO v_compatibility_id;

  -- 3. 성공 반환
  RETURN QUERY SELECT
    v_user_result_id,
    v_compatibility_id,
    TRUE,
    'Compatibility saved successfully'::TEXT;

EXCEPTION
  WHEN OTHERS THEN
    -- 에러 발생 시 자동 롤백 (PostgreSQL 트랜잭션)
    RETURN QUERY SELECT
      NULL::UUID,
      NULL::UUID,
      FALSE,
      SQLERRM::TEXT;
END;
$$ LANGUAGE plpgsql;

-- RLS 정책 추가 (함수 실행 권한)
ALTER FUNCTION save_compatibility_with_transaction SECURITY DEFINER;

-- 주석 추가
COMMENT ON FUNCTION save_compatibility_with_transaction IS
  '궁합 분석 결과를 트랜잭션으로 저장하는 함수. user_results와 compatibility_results를 원자적으로 처리합니다.';
