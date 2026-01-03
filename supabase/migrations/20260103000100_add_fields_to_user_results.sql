-- =====================================================
-- user_results 테이블 필드 확장
-- firebase_uid와 use_night_subhour 필드 추가
-- =====================================================

-- 1. firebase_uid 필드 추가 (Firebase Auth 사용자 ID)
ALTER TABLE public.user_results
ADD COLUMN IF NOT EXISTS firebase_uid TEXT UNIQUE;

-- 2. use_night_subhour 필드 추가 (야자시 사용 여부)
ALTER TABLE public.user_results
ADD COLUMN IF NOT EXISTS use_night_subhour BOOLEAN DEFAULT FALSE NOT NULL;

-- 3. 성능 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_user_results_firebase_uid
  ON public.user_results(firebase_uid);

-- 4. 코멘트 추가 (문서화)
COMMENT ON COLUMN public.user_results.firebase_uid IS 'Firebase Authentication 사용자 고유 ID';
COMMENT ON COLUMN public.user_results.use_night_subhour IS '야자시(자정시) 사용 여부 (true=사용, false=미사용)';

-- =====================================================
-- 검증 쿼리 (실행 후 확인용)
-- =====================================================
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_name = 'user_results' AND column_name IN ('firebase_uid', 'use_night_subhour')
-- ORDER BY ordinal_position;
