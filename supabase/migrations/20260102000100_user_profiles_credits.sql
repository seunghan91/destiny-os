-- =====================================================
-- 사용자 프로필 및 크레딧 시스템 마이그레이션
-- mbti_luck 프로젝트용 Firebase Auth 연동
-- =====================================================

-- 1. 사용자 프로필 테이블
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid TEXT UNIQUE NOT NULL,
    email TEXT,
    display_name TEXT,
    
    -- 사주 정보
    birth_date TIMESTAMPTZ,
    birth_hour INTEGER CHECK (birth_hour >= 0 AND birth_hour <= 23),
    gender TEXT CHECK (gender IN ('male', 'female')),
    is_lunar BOOLEAN DEFAULT FALSE,
    mbti TEXT CHECK (mbti IS NULL OR length(mbti) = 4),
    
    -- 인증 정보
    auth_provider TEXT CHECK (auth_provider IN ('google', 'apple')),
    
    -- 메타데이터
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 사용자 크레딧 테이블 (잔액 관리)
CREATE TABLE IF NOT EXISTS user_credits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    balance INTEGER NOT NULL DEFAULT 0 CHECK (balance >= 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_user_credit UNIQUE (user_id)
);

-- 3. 크레딧 거래 이력 테이블
CREATE TABLE IF NOT EXISTS credit_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    
    -- 거래 정보
    type TEXT NOT NULL CHECK (type IN ('purchase', 'use', 'refund', 'bonus', 'admin')),
    amount INTEGER NOT NULL, -- +: 증가, -: 감소
    balance_after INTEGER NOT NULL CHECK (balance_after >= 0),
    
    -- 상세 정보
    description TEXT,
    payment_id TEXT, -- 결제 연동 시 사용
    feature_used TEXT, -- 사용한 기능 (saju_analysis, compatibility, ai_consultation 등)
    
    -- 메타데이터
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_user_profiles_firebase_uid ON user_profiles(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_user_credits_user_id ON user_credits(user_id);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_user_id ON credit_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_created_at ON credit_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_type ON credit_transactions(type);

-- updated_at 자동 업데이트 트리거
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_credits_updated_at ON user_credits;
CREATE TRIGGER update_user_credits_updated_at
    BEFORE UPDATE ON user_credits
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- RLS (Row Level Security) 정책
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_credits ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;

-- 서비스 역할(service_role)은 모든 작업 허용
CREATE POLICY "Service role full access on user_profiles" ON user_profiles
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access on user_credits" ON user_credits
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access on credit_transactions" ON credit_transactions
    FOR ALL USING (auth.role() = 'service_role');

-- anon 역할도 읽기/쓰기 허용 (Firebase Auth 사용으로 Supabase Auth 미사용)
CREATE POLICY "Anon can read user_profiles" ON user_profiles
    FOR SELECT USING (true);

CREATE POLICY "Anon can insert user_profiles" ON user_profiles
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Anon can update user_profiles" ON user_profiles
    FOR UPDATE USING (true);

CREATE POLICY "Anon can read user_credits" ON user_credits
    FOR SELECT USING (true);

CREATE POLICY "Anon can insert user_credits" ON user_credits
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Anon can update user_credits" ON user_credits
    FOR UPDATE USING (true);

CREATE POLICY "Anon can read credit_transactions" ON credit_transactions
    FOR SELECT USING (true);

CREATE POLICY "Anon can insert credit_transactions" ON credit_transactions
    FOR INSERT WITH CHECK (true);

-- 크레딧 사용 함수 (원자적 트랜잭션)
CREATE OR REPLACE FUNCTION use_credit(
    p_user_id UUID,
    p_amount INTEGER,
    p_feature TEXT,
    p_description TEXT DEFAULT NULL
) RETURNS TABLE (
    success BOOLEAN,
    new_balance INTEGER,
    message TEXT
) AS $$
DECLARE
    v_current_balance INTEGER;
    v_new_balance INTEGER;
BEGIN
    -- 현재 잔액 조회 (락)
    SELECT balance INTO v_current_balance
    FROM user_credits
    WHERE user_id = p_user_id
    FOR UPDATE;
    
    IF v_current_balance IS NULL THEN
        RETURN QUERY SELECT FALSE, 0, '크레딧 정보가 없습니다.'::TEXT;
        RETURN;
    END IF;
    
    IF v_current_balance < p_amount THEN
        RETURN QUERY SELECT FALSE, v_current_balance, '크레딧이 부족합니다.'::TEXT;
        RETURN;
    END IF;
    
    -- 잔액 차감
    v_new_balance := v_current_balance - p_amount;
    
    UPDATE user_credits
    SET balance = v_new_balance
    WHERE user_id = p_user_id;
    
    -- 거래 이력 기록
    INSERT INTO credit_transactions (user_id, type, amount, balance_after, feature_used, description)
    VALUES (p_user_id, 'use', -p_amount, v_new_balance, p_feature, COALESCE(p_description, p_feature || ' 사용'));
    
    RETURN QUERY SELECT TRUE, v_new_balance, '크레딧이 차감되었습니다.'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- 크레딧 추가 함수 (구매/보너스)
CREATE OR REPLACE FUNCTION add_credit(
    p_user_id UUID,
    p_amount INTEGER,
    p_type TEXT,
    p_description TEXT DEFAULT NULL,
    p_payment_id TEXT DEFAULT NULL
) RETURNS TABLE (
    success BOOLEAN,
    new_balance INTEGER,
    message TEXT
) AS $$
DECLARE
    v_current_balance INTEGER;
    v_new_balance INTEGER;
BEGIN
    -- 현재 잔액 조회 (락)
    SELECT balance INTO v_current_balance
    FROM user_credits
    WHERE user_id = p_user_id
    FOR UPDATE;
    
    IF v_current_balance IS NULL THEN
        -- 크레딧 레코드가 없으면 생성
        INSERT INTO user_credits (user_id, balance)
        VALUES (p_user_id, p_amount);
        v_new_balance := p_amount;
    ELSE
        v_new_balance := v_current_balance + p_amount;
        UPDATE user_credits
        SET balance = v_new_balance
        WHERE user_id = p_user_id;
    END IF;
    
    -- 거래 이력 기록
    INSERT INTO credit_transactions (user_id, type, amount, balance_after, description, payment_id)
    VALUES (p_user_id, p_type, p_amount, v_new_balance, 
            COALESCE(p_description, 
                CASE p_type 
                    WHEN 'purchase' THEN p_amount || '회권 구매'
                    WHEN 'bonus' THEN '보너스 ' || p_amount || '회'
                    WHEN 'refund' THEN '환불 ' || p_amount || '회'
                    ELSE p_amount || '회 추가'
                END),
            p_payment_id);
    
    RETURN QUERY SELECT TRUE, v_new_balance, '크레딧이 추가되었습니다.'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- 코멘트 추가
COMMENT ON TABLE user_profiles IS '사용자 프로필 (Firebase Auth 연동)';
COMMENT ON TABLE user_credits IS '사용자 크레딧 잔액';
COMMENT ON TABLE credit_transactions IS '크레딧 거래 이력';
COMMENT ON FUNCTION use_credit IS '크레딧 사용 (원자적 차감)';
COMMENT ON FUNCTION add_credit IS '크레딧 추가 (구매/보너스/환불)';
