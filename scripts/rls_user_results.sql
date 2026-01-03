-- =====================================================
-- RLS (Row Level Security) for user_results table
-- =====================================================
-- Supabase Dashboard의 SQL Editor에서 실행하세요
-- =====================================================

-- 1. RLS 활성화
ALTER TABLE public.user_results ENABLE ROW LEVEL SECURITY;

-- 2. 기존 정책 제거 (있는 경우)
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.user_results;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.user_results;
DROP POLICY IF EXISTS "user_results admin access" ON public.user_results;
DROP POLICY IF EXISTS "Admin read access" ON public.user_results;
DROP POLICY IF EXISTS "Authenticated users can insert" ON public.user_results;
DROP POLICY IF EXISTS "Admin update delete" ON public.user_results;
DROP POLICY IF EXISTS "Admin delete access" ON public.user_results;

-- 3. Admin만 읽기 가능 (역할 또는 이메일 기반)
CREATE POLICY "Admin read access"
ON public.user_results
FOR SELECT
USING (
  (auth.jwt() -> 'user_role') = '"admin"'
  OR auth.email() LIKE '%@admin%'
  OR auth.email() = 'admin@destiny.app'
);

-- 4. 인증된 사용자는 자신의 데이터 삽입 가능
CREATE POLICY "Authenticated users can insert"
ON public.user_results
FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

-- 5. Admin만 업데이트 가능
CREATE POLICY "Admin update delete"
ON public.user_results
FOR UPDATE
USING (
  (auth.jwt() -> 'user_role') = '"admin"'
  OR auth.email() LIKE '%@admin%'
  OR auth.email() = 'admin@destiny.app'
);

-- 6. Admin만 삭제 가능
CREATE POLICY "Admin delete access"
ON public.user_results
FOR DELETE
USING (
  (auth.jwt() -> 'user_role') = '"admin"'
  OR auth.email() LIKE '%@admin%'
  OR auth.email() = 'admin@destiny.app'
);

-- =====================================================
-- 검증: 정책이 올바르게 적용되었는지 확인
-- =====================================================
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  qual AS policy_expression
FROM pg_policies
WHERE tablename = 'user_results'
ORDER BY policyname;
