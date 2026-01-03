-- =====================================================
-- RLS 보안 강화 및 결제 테이블 스키마 통합
-- mbti_luck 프로젝트용 Firebase Auth + Supabase 연동
-- =====================================================

-- 1. user_profiles 테이블에 legacy_user_id 추가 (기존 users 테이블 연동)
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS legacy_user_id UUID REFERENCES users(id) ON DELETE SET NULL;

-- legacy_user_id 인덱스
CREATE INDEX IF NOT EXISTS idx_user_profiles_legacy_user_id ON user_profiles(legacy_user_id);

-- 2. 기존 RLS 정책 삭제 (너무 오픈된 정책들)
DROP POLICY IF EXISTS "Anon can read user_profiles" ON user_profiles;
DROP POLICY IF EXISTS "Anon can insert user_profiles" ON user_profiles;
DROP POLICY IF EXISTS "Anon can update user_profiles" ON user_profiles;
DROP POLICY IF EXISTS "Anon can read user_credits" ON user_credits;
DROP POLICY IF EXISTS "Anon can insert user_credits" ON user_credits;
DROP POLICY IF EXISTS "Anon can update user_credits" ON user_credits;
DROP POLICY IF EXISTS "Anon can read credit_transactions" ON credit_transactions;
DROP POLICY IF EXISTS "Anon can insert credit_transactions" ON credit_transactions;

-- 3. 새로운 RLS 정책 (더 엄격한 버전)
-- 참고: Firebase Auth 사용으로 Supabase Auth를 사용하지 않으므로
-- 앱에서 service_role key를 사용하여 DB 접근

-- user_profiles: service_role만 접근 가능 (기본 정책 유지)
-- anon 정책은 없음 - 앱에서 service_role 사용해야 함

-- 4. 결제 연동을 위한 함수: Firebase UID로 user_profiles.id 조회
CREATE OR REPLACE FUNCTION get_profile_id_by_firebase_uid(p_firebase_uid TEXT)
RETURNS UUID AS $$
DECLARE
    v_profile_id UUID;
BEGIN
    SELECT id INTO v_profile_id
    FROM user_profiles
    WHERE firebase_uid = p_firebase_uid;

    RETURN v_profile_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. 결제 완료 시 크레딧 추가 함수 (Firebase UID 기반)
CREATE OR REPLACE FUNCTION process_payment_credit(
    p_firebase_uid TEXT,
    p_amount INTEGER,
    p_payment_id TEXT,
    p_description TEXT DEFAULT NULL
) RETURNS TABLE (
    success BOOLEAN,
    new_balance INTEGER,
    message TEXT
) AS $$
DECLARE
    v_profile_id UUID;
    v_result RECORD;
BEGIN
    -- 프로필 ID 조회
    SELECT id INTO v_profile_id
    FROM user_profiles
    WHERE firebase_uid = p_firebase_uid;

    IF v_profile_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 0, '사용자를 찾을 수 없습니다.'::TEXT;
        RETURN;
    END IF;

    -- 크레딧 추가
    SELECT * INTO v_result FROM add_credit(
        v_profile_id,
        p_amount,
        'purchase',
        p_description,
        p_payment_id
    );

    RETURN QUERY SELECT
        v_result.success,
        v_result.new_balance,
        v_result.message;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. 사용자 생성/업데이트 시 legacy users 테이블과 연동
CREATE OR REPLACE FUNCTION sync_user_profile_with_legacy()
RETURNS TRIGGER AS $$
DECLARE
    v_legacy_id UUID;
BEGIN
    -- 이메일로 기존 users 테이블에서 매칭 시도
    IF NEW.email IS NOT NULL AND NEW.legacy_user_id IS NULL THEN
        SELECT id INTO v_legacy_id
        FROM users
        WHERE email = NEW.email
        LIMIT 1;

        IF v_legacy_id IS NOT NULL THEN
            NEW.legacy_user_id := v_legacy_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS sync_legacy_user ON user_profiles;
CREATE TRIGGER sync_legacy_user
    BEFORE INSERT OR UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION sync_user_profile_with_legacy();

-- 7. 크레딧 사용 통계 뷰
CREATE OR REPLACE VIEW credit_usage_stats AS
SELECT
    up.firebase_uid,
    up.email,
    up.display_name,
    COALESCE(uc.balance, 0) as current_balance,
    COALESCE(SUM(CASE WHEN ct.type = 'use' THEN ABS(ct.amount) ELSE 0 END), 0) as total_used,
    COALESCE(SUM(CASE WHEN ct.type = 'purchase' THEN ct.amount ELSE 0 END), 0) as total_purchased,
    COALESCE(COUNT(CASE WHEN ct.type = 'use' THEN 1 END), 0) as use_count,
    COALESCE(COUNT(CASE WHEN ct.type = 'purchase' THEN 1 END), 0) as purchase_count
FROM user_profiles up
LEFT JOIN user_credits uc ON uc.user_id = up.id
LEFT JOIN credit_transactions ct ON ct.user_id = up.id
GROUP BY up.id, up.firebase_uid, up.email, up.display_name, uc.balance;

-- 8. 코멘트 업데이트
COMMENT ON COLUMN user_profiles.legacy_user_id IS '기존 users 테이블과의 연동 ID';
COMMENT ON FUNCTION get_profile_id_by_firebase_uid IS 'Firebase UID로 프로필 ID 조회';
COMMENT ON FUNCTION process_payment_credit IS '결제 완료 후 크레딧 지급 (Firebase UID 기반)';
COMMENT ON VIEW credit_usage_stats IS '크레딧 사용 통계 뷰';
