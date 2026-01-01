-- ============================================
-- Destiny.OS Consultations Table
-- ============================================
-- 사주/MBTI 상담 기록 저장용 테이블
-- 생성일: 2026-01-01

-- ============================================
-- 1. consultations 테이블 생성
-- ============================================
CREATE TABLE IF NOT EXISTS consultations (
  -- 기본 식별자
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- 사용자 정보 (익명 사용자 지원)
  user_id TEXT,  -- 기기 ID 또는 사용자 ID

  -- 사주 정보 (JSONB로 유연하게 저장)
  saju_info JSONB,  -- { birth_date, birth_time, gender, is_leap_month, ... }

  -- MBTI 정보
  mbti_type TEXT CHECK (
    mbti_type IS NULL OR
    mbti_type ~ '^[IE][NS][FT][JP]$'
  ),

  -- 상담 타입
  consultation_type TEXT CHECK (
    consultation_type IN ('saju', 'mbti', 'combined', 'compatibility')
  ),

  -- 상담 대화 내역 (JSONB 배열)
  messages JSONB,  -- [{ role: 'user'|'assistant', content: '...', timestamp: ... }]

  -- 운세 점수 (0-100)
  fortune_score INTEGER CHECK (
    fortune_score IS NULL OR
    (fortune_score >= 0 AND fortune_score <= 100)
  ),

  -- 메타데이터
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 2. 인덱스 생성
-- ============================================
-- 사용자별 상담 조회 최적화
CREATE INDEX IF NOT EXISTS idx_consultations_user_id
ON consultations(user_id);

-- 생성일 기준 정렬 최적화
CREATE INDEX IF NOT EXISTS idx_consultations_created_at
ON consultations(created_at DESC);

-- 상담 타입별 조회 최적화
CREATE INDEX IF NOT EXISTS idx_consultations_type
ON consultations(consultation_type);

-- MBTI 타입별 조회 최적화
CREATE INDEX IF NOT EXISTS idx_consultations_mbti
ON consultations(mbti_type)
WHERE mbti_type IS NOT NULL;

-- ============================================
-- 3. RLS (Row Level Security) 활성화
-- ============================================
ALTER TABLE consultations ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 4. RLS 정책 생성
-- ============================================
-- 정책 1: 모든 사용자가 조회 가능 (익명 포함)
CREATE POLICY "Anyone can view consultations"
ON consultations
FOR SELECT
USING (true);

-- 정책 2: 모든 사용자가 생성 가능 (익명 포함)
CREATE POLICY "Anyone can create consultations"
ON consultations
FOR INSERT
WITH CHECK (true);

-- 정책 3: 자신의 기록만 업데이트 가능
CREATE POLICY "Users can update own consultations"
ON consultations
FOR UPDATE
USING (user_id = current_setting('request.jwt.claims', true)::json->>'sub')
WITH CHECK (user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- 정책 4: 자신의 기록만 삭제 가능
CREATE POLICY "Users can delete own consultations"
ON consultations
FOR DELETE
USING (user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- ============================================
-- 5. updated_at 자동 업데이트 트리거
-- ============================================
-- 트리거 함수 생성
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
CREATE TRIGGER update_consultations_updated_at
BEFORE UPDATE ON consultations
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 6. 샘플 데이터 (테스트용 - 선택)
-- ============================================
-- INSERT INTO consultations (
--   user_id,
--   saju_info,
--   mbti_type,
--   consultation_type,
--   messages,
--   fortune_score
-- ) VALUES (
--   'test-device-123',
--   '{"birth_date": "1990-05-15", "birth_time": "14:30", "gender": "M"}'::jsonb,
--   'INFP',
--   'combined',
--   '[{"role": "user", "content": "오늘의 운세는?", "timestamp": "2026-01-01T00:00:00Z"}]'::jsonb,
--   85
-- );

-- ============================================
-- 완료
-- ============================================
-- Migration completed successfully
