-- =====================================================
-- Add use_night_subhour field to user_results
-- =====================================================
-- Supabase Dashboard의 SQL Editor에서 실행하세요
-- =====================================================

-- 1. user_results 테이블에 use_night_subhour 컬럼 추가 (이미 있는 경우 무시)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_results' AND column_name = 'use_night_subhour'
  ) THEN
    ALTER TABLE public.user_results ADD COLUMN use_night_subhour BOOLEAN DEFAULT false;
    -- 기존 데이터는 모두 false로 설정 (기본값)
    UPDATE public.user_results SET use_night_subhour = false WHERE use_night_subhour IS NULL;
  END IF;
END $$;

-- 2. 컬럼이 NOT NULL로 설정되어야 함
ALTER TABLE public.user_results ALTER COLUMN use_night_subhour SET NOT NULL;

-- 3. 기본값을 false로 설정
ALTER TABLE public.user_results ALTER COLUMN use_night_subhour SET DEFAULT false;

-- =====================================================
-- 검증: 컬럼이 올바르게 생성되었는지 확인
-- =====================================================
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'user_results' AND column_name = 'use_night_subhour';
