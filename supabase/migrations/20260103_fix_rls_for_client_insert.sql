-- =====================================================
-- RLS 정책 수정: 클라이언트(ANON)도 데이터 저장 가능하도록 개선
-- Firebase Auth + Supabase 클라이언트 연동
-- =====================================================

-- 1. user_profiles 테이블: 모든 사용자가 자신의 프로필을 생성/업데이트 가능
DO $$
BEGIN
    DROP POLICY IF EXISTS "Service role full access on user_profiles" ON user_profiles;
EXCEPTION
    WHEN undefined_object THEN
        NULL;
END $$;

DO $$
BEGIN
    DROP POLICY IF EXISTS "Anyone can insert user_profiles" ON user_profiles;
EXCEPTION
    WHEN undefined_object THEN
        NULL;
END $$;

CREATE POLICY "Anyone can insert user_profiles"
ON user_profiles
FOR INSERT
WITH CHECK (true);

DO $$
BEGIN
    DROP POLICY IF EXISTS "Anyone can update user_profiles" ON user_profiles;
EXCEPTION
    WHEN undefined_object THEN
        NULL;
END $$;

CREATE POLICY "Anyone can update user_profiles"
ON user_profiles
FOR UPDATE
USING (true)
WITH CHECK (true);

DO $$
BEGIN
    DROP POLICY IF EXISTS "Anyone can read user_profiles" ON user_profiles;
EXCEPTION
    WHEN undefined_object THEN
        NULL;
END $$;

CREATE POLICY "Anyone can read user_profiles"
ON user_profiles
FOR SELECT
USING (true);

-- 2. user_results 테이블: 모든 사용자가 분석 결과를 저장 가능
DO $$
BEGIN
    DROP POLICY IF EXISTS "Service role full access on user_results" ON user_results;
EXCEPTION
    WHEN undefined_object THEN
        NULL;
END $$;

DO $$
BEGIN
    DROP POLICY IF EXISTS "Anyone can insert user_results" ON user_results;
EXCEPTION
    WHEN undefined_object THEN
        NULL;
END $$;

CREATE POLICY "Anyone can insert user_results"
ON user_results
FOR INSERT
WITH CHECK (true);

DO $$
BEGIN
    DROP POLICY IF EXISTS "Anyone can read user_results" ON user_results;
EXCEPTION
    WHEN undefined_object THEN
        NULL;
END $$;

CREATE POLICY "Anyone can read user_results"
ON user_results
FOR SELECT
USING (true);

-- 3. fortune_2026_results 테이블: 모든 사용자가 운세 결과를 저장 가능 (테이블이 존재하는 경우에만)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'fortune_2026_results') THEN
        BEGIN
            DROP POLICY IF EXISTS "Anyone can insert fortune_2026_results" ON fortune_2026_results;
        EXCEPTION
            WHEN undefined_object THEN
                NULL;
        END;

        BEGIN
            DROP POLICY IF EXISTS "Anyone can read fortune_2026_results" ON fortune_2026_results;
        EXCEPTION
            WHEN undefined_object THEN
                NULL;
        END;

        CREATE POLICY "Anyone can insert fortune_2026_results"
        ON fortune_2026_results
        FOR INSERT
        WITH CHECK (true);

        CREATE POLICY "Anyone can read fortune_2026_results"
        ON fortune_2026_results
        FOR SELECT
        USING (true);
    END IF;
END $$;

-- 4. user_credits 테이블: 모든 사용자가 크레딧 정보를 읽을 수 있음
DO $$
BEGIN
    DROP POLICY IF EXISTS "Service role full access on user_credits" ON user_credits;
EXCEPTION
    WHEN undefined_object THEN
        NULL;
END $$;

DO $$
BEGIN
    DROP POLICY IF EXISTS "Anyone can read user_credits" ON user_credits;
EXCEPTION
    WHEN undefined_object THEN
        NULL;
END $$;

CREATE POLICY "Anyone can read user_credits"
ON user_credits
FOR SELECT
USING (true);

DO $$
BEGIN
    DROP POLICY IF EXISTS "Anyone can insert user_credits" ON user_credits;
EXCEPTION
    WHEN undefined_object THEN
        NULL;
END $$;

CREATE POLICY "Anyone can insert user_credits"
ON user_credits
FOR INSERT
WITH CHECK (true);

DO $$
BEGIN
    DROP POLICY IF EXISTS "Anyone can update user_credits" ON user_credits;
EXCEPTION
    WHEN undefined_object THEN
        NULL;
END $$;

CREATE POLICY "Anyone can update user_credits"
ON user_credits
FOR UPDATE
USING (true)
WITH CHECK (true);

-- 5. credit_transactions 테이블: 모든 사용자가 거래 기록을 읽고 저장 가능
DO $$
BEGIN
    DROP POLICY IF EXISTS "Service role full access on credit_transactions" ON credit_transactions;
EXCEPTION
    WHEN undefined_object THEN
        NULL;
END $$;

DO $$
BEGIN
    DROP POLICY IF EXISTS "Anyone can read credit_transactions" ON credit_transactions;
EXCEPTION
    WHEN undefined_object THEN
        NULL;
END $$;

CREATE POLICY "Anyone can read credit_transactions"
ON credit_transactions
FOR SELECT
USING (true);

DO $$
BEGIN
    DROP POLICY IF EXISTS "Anyone can insert credit_transactions" ON credit_transactions;
EXCEPTION
    WHEN undefined_object THEN
        NULL;
END $$;

CREATE POLICY "Anyone can insert credit_transactions"
ON credit_transactions
FOR INSERT
WITH CHECK (true);

-- 6. consultations 테이블: 이미 적절한 정책이 있으므로 유지

-- =====================================================
-- 코멘트 추가
-- =====================================================
COMMENT ON POLICY "Anyone can insert user_profiles" ON user_profiles IS
  'Firebase Auth를 사용하는 클라이언트가 프로필을 저장할 수 있도록 허용';

COMMENT ON POLICY "Anyone can insert user_results" ON user_results IS
  '사주 분석 결과를 누구나 저장할 수 있도록 허용';

-- fortune_2026_results 코멘트는 테이블이 존재하는 경우에만 추가
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'fortune_2026_results') THEN
        EXECUTE 'COMMENT ON POLICY "Anyone can insert fortune_2026_results" ON fortune_2026_results IS ''2026년 운세 결과를 누구나 저장할 수 있도록 허용''';
    END IF;
END $$;
