-- =====================================================
-- 궁합 분석 결과 테이블
-- user_results와 연결하여 궁합 히스토리 추적
-- =====================================================

CREATE TABLE IF NOT EXISTS compatibility_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- 메인 사용자 (user_results 연결)
  user_result_id UUID NOT NULL REFERENCES user_results(id) ON DELETE CASCADE,

  -- 상대방 정보
  partner_name TEXT,
  partner_birth_date TIMESTAMPTZ NOT NULL,
  partner_birth_hour INTEGER CHECK (partner_birth_hour >= 0 AND partner_birth_hour <= 23),
  partner_gender TEXT NOT NULL CHECK (partner_gender IN ('male', 'female', 'M', 'F')),
  partner_is_lunar BOOLEAN DEFAULT FALSE,
  partner_mbti TEXT CHECK (partner_mbti IS NULL OR length(partner_mbti) = 4),

  -- 궁합 점수
  overall_score INTEGER NOT NULL CHECK (overall_score >= 0 AND overall_score <= 100),
  saju_score INTEGER NOT NULL CHECK (saju_score >= 0 AND saju_score <= 100),
  mbti_score INTEGER CHECK (mbti_score IS NULL OR (mbti_score >= 0 AND mbti_score <= 100)),

  -- 카테고리별 점수
  love_score INTEGER NOT NULL CHECK (love_score >= 0 AND love_score <= 100),
  marriage_score INTEGER NOT NULL CHECK (marriage_score >= 0 AND marriage_score <= 100),
  business_score INTEGER NOT NULL CHECK (business_score >= 0 AND business_score <= 100),
  friendship_score INTEGER NOT NULL CHECK (friendship_score >= 0 AND friendship_score <= 100),

  -- MBTI 궁합 정보
  mbti_relationship_type TEXT,
  mbti_communication_style TEXT,
  mbti_conflict_pattern TEXT,
  mbti_common_ground TEXT[], -- 배열 형태로 저장
  mbti_differences TEXT[], -- 배열 형태로 저장

  -- 상세 분석 (JSONB 형태로 저장)
  day_pillar_analysis JSONB,
  branch_relations JSONB,
  element_balance JSONB,
  stem_relations JSONB,
  insights JSONB,

  -- 메타데이터
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_compatibility_user_result
  ON compatibility_results(user_result_id);

CREATE INDEX IF NOT EXISTS idx_compatibility_created_at
  ON compatibility_results(created_at DESC);

-- RLS 정책
ALTER TABLE compatibility_results ENABLE ROW LEVEL SECURITY;

-- 모든 사용자가 읽기 가능 (관리자 페이지용)
CREATE POLICY "Enable read access for all users"
  ON compatibility_results
  FOR SELECT
  USING (true);

-- 모든 사용자가 삽입 가능
CREATE POLICY "Enable insert access for all users"
  ON compatibility_results
  FOR INSERT
  WITH CHECK (true);

-- 주석 추가
COMMENT ON TABLE compatibility_results IS '궁합 분석 결과를 저장하는 테이블. user_results와 연결하여 사용자별 궁합 히스토리를 추적합니다.';
COMMENT ON COLUMN compatibility_results.user_result_id IS 'user_results 테이블의 ID (메인 사용자)';
COMMENT ON COLUMN compatibility_results.overall_score IS '전체 궁합 점수 (0-100)';
COMMENT ON COLUMN compatibility_results.saju_score IS '사주 궁합 점수 (0-100)';
COMMENT ON COLUMN compatibility_results.mbti_score IS 'MBTI 궁합 점수 (0-100, nullable)';
COMMENT ON COLUMN compatibility_results.insights IS '강점, 약점, 조언 등의 인사이트 (JSONB)';
