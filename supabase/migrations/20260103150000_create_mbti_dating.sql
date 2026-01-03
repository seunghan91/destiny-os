-- =====================================================
-- MBTI 소개팅 시스템 마이그레이션
-- 하루 3명 추천 + 좋아요/패스 기능
-- =====================================================

-- 1. 소개팅 프로필 테이블 (추가 정보)
CREATE TABLE IF NOT EXISTS dating_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    
    -- 필수 정보 (user_profiles에서 가져오되, 소개팅용으로 별도 관리)
    birth_year SMALLINT NOT NULL,
    gender TEXT NOT NULL CHECK (gender IN ('male', 'female')),
    mbti TEXT NOT NULL CHECK (length(mbti) = 4),
    
    -- 추가 프로필 정보
    job TEXT,
    height SMALLINT CHECK (height IS NULL OR (height >= 100 AND height <= 250)),
    keywords TEXT[] DEFAULT '{}',
    bio TEXT,
    photo_path TEXT,  -- Supabase Storage 경로
    
    -- 상태
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'paused', 'banned')),
    
    -- 메타데이터
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_dating_profile UNIQUE (user_id)
);

-- 2. 소개팅 선호도 테이블
CREATE TABLE IF NOT EXISTS dating_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    
    -- 필수 선호도
    target_mbti TEXT[] NOT NULL DEFAULT '{}',  -- 원하는 MBTI 유형 (복수)
    age_min SMALLINT NOT NULL DEFAULT 20,
    age_max SMALLINT NOT NULL DEFAULT 40,
    target_gender TEXT CHECK (target_gender IS NULL OR target_gender IN ('male', 'female')),
    -- NULL이면 기본 로직: 남자→여자, 여자→남자
    
    -- 선택 선호도 (추후 확장)
    height_min SMALLINT,
    height_max SMALLINT,
    job_preferences TEXT[],
    
    -- 메타데이터
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_dating_preference UNIQUE (user_id),
    CONSTRAINT valid_age_range CHECK (age_min <= age_max),
    CONSTRAINT valid_height_range CHECK (height_min IS NULL OR height_max IS NULL OR height_min <= height_max)
);

-- 3. 일일 추천 테이블
CREATE TABLE IF NOT EXISTS dating_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    recommended_user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    
    -- 추천 날짜 (KST 기준)
    date_key DATE NOT NULL DEFAULT (CURRENT_DATE AT TIME ZONE 'Asia/Seoul'),
    rank SMALLINT NOT NULL,  -- 1, 2, 3
    
    -- 메타데이터
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- 하루에 같은 사람 중복 추천 방지
    CONSTRAINT unique_daily_recommendation UNIQUE (user_id, recommended_user_id, date_key),
    -- 자기 자신 추천 방지
    CONSTRAINT no_self_recommendation CHECK (user_id != recommended_user_id)
);

-- 4. 좋아요/패스 기록 테이블
CREATE TABLE IF NOT EXISTS dating_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    target_user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    
    -- 액션
    action TEXT NOT NULL CHECK (action IN ('like', 'pass')),
    
    -- 메타데이터
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- 한 사람에 대해 한 번만 액션 가능
    CONSTRAINT unique_like_action UNIQUE (user_id, target_user_id),
    -- 자기 자신 액션 방지
    CONSTRAINT no_self_action CHECK (user_id != target_user_id)
);

-- 5. 매치 테이블 (양방향 좋아요)
CREATE TABLE IF NOT EXISTS dating_matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user1_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    user1_accepted BOOLEAN NOT NULL DEFAULT FALSE,
    user2_accepted BOOLEAN NOT NULL DEFAULT FALSE,
    user1_accepted_at TIMESTAMPTZ,
    user2_accepted_at TIMESTAMPTZ,
    accepted_at TIMESTAMPTZ,
    user1_open_chat_url TEXT,
    user2_open_chat_url TEXT,
    user1_open_chat_url_at TIMESTAMPTZ,
    user2_open_chat_url_at TIMESTAMPTZ,
    
    -- 메타데이터
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- 중복 매치 방지 (user1_id < user2_id로 정규화)
    CONSTRAINT unique_match UNIQUE (user1_id, user2_id),
    CONSTRAINT ordered_match CHECK (user1_id < user2_id),
    CONSTRAINT user1_open_chat_url_format CHECK (user1_open_chat_url IS NULL OR user1_open_chat_url LIKE 'https://open.kakao.com/%'),
    CONSTRAINT user2_open_chat_url_format CHECK (user2_open_chat_url IS NULL OR user2_open_chat_url LIKE 'https://open.kakao.com/%')
);

-- =====================================================
-- 인덱스
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_dating_profiles_user_id ON dating_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_dating_profiles_status ON dating_profiles(status);
CREATE INDEX IF NOT EXISTS idx_dating_profiles_gender ON dating_profiles(gender);
CREATE INDEX IF NOT EXISTS idx_dating_profiles_mbti ON dating_profiles(mbti);
CREATE INDEX IF NOT EXISTS idx_dating_profiles_birth_year ON dating_profiles(birth_year);

CREATE INDEX IF NOT EXISTS idx_dating_preferences_user_id ON dating_preferences(user_id);

CREATE INDEX IF NOT EXISTS idx_dating_recommendations_user_id ON dating_recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_dating_recommendations_date_key ON dating_recommendations(date_key);
CREATE INDEX IF NOT EXISTS idx_dating_recommendations_user_date ON dating_recommendations(user_id, date_key);

CREATE INDEX IF NOT EXISTS idx_dating_likes_user_id ON dating_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_dating_likes_target_user_id ON dating_likes(target_user_id);
CREATE INDEX IF NOT EXISTS idx_dating_likes_action ON dating_likes(action);

CREATE INDEX IF NOT EXISTS idx_dating_matches_user1 ON dating_matches(user1_id);
CREATE INDEX IF NOT EXISTS idx_dating_matches_user2 ON dating_matches(user2_id);

-- =====================================================
-- 트리거: updated_at 자동 업데이트
-- =====================================================
DROP TRIGGER IF EXISTS update_dating_profiles_updated_at ON dating_profiles;
CREATE TRIGGER update_dating_profiles_updated_at
    BEFORE UPDATE ON dating_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_dating_preferences_updated_at ON dating_preferences;
CREATE TRIGGER update_dating_preferences_updated_at
    BEFORE UPDATE ON dating_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_dating_matches_updated_at ON dating_matches;
CREATE TRIGGER update_dating_matches_updated_at
    BEFORE UPDATE ON dating_matches
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- RLS (Row Level Security)
-- =====================================================
ALTER TABLE dating_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE dating_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE dating_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE dating_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE dating_matches ENABLE ROW LEVEL SECURITY;

-- Service role 전체 접근
DROP POLICY IF EXISTS "Service role full access on dating_profiles" ON dating_profiles;
DROP POLICY IF EXISTS "Service role full access on dating_preferences" ON dating_preferences;
DROP POLICY IF EXISTS "Service role full access on dating_recommendations" ON dating_recommendations;
DROP POLICY IF EXISTS "Service role full access on dating_likes" ON dating_likes;
DROP POLICY IF EXISTS "Service role full access on dating_matches" ON dating_matches;

CREATE POLICY "Service role full access on dating_profiles" ON dating_profiles
    FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service role full access on dating_preferences" ON dating_preferences
    FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service role full access on dating_recommendations" ON dating_recommendations
    FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service role full access on dating_likes" ON dating_likes
    FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Service role full access on dating_matches" ON dating_matches
    FOR ALL USING (auth.role() = 'service_role');

-- Anon 역할 (Firebase Auth 사용)
-- dating_profiles: active 상태만 읽기 가능 (다른 사용자 프로필 보기)
DROP POLICY IF EXISTS "Anon can read active dating_profiles" ON dating_profiles;
DROP POLICY IF EXISTS "Anon can insert dating_profiles" ON dating_profiles;
DROP POLICY IF EXISTS "Anon can update own dating_profiles" ON dating_profiles;
DROP POLICY IF EXISTS "Anon can manage dating_preferences" ON dating_preferences;
DROP POLICY IF EXISTS "Anon can manage dating_recommendations" ON dating_recommendations;
DROP POLICY IF EXISTS "Anon can manage dating_likes" ON dating_likes;
DROP POLICY IF EXISTS "Anon can read dating_matches" ON dating_matches;
DROP POLICY IF EXISTS "Anon can insert dating_matches" ON dating_matches;

CREATE POLICY "Anon can read active dating_profiles" ON dating_profiles
    FOR SELECT USING (status = 'active');

CREATE POLICY "Anon can insert dating_profiles" ON dating_profiles
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Anon can update own dating_profiles" ON dating_profiles
    FOR UPDATE USING (true);

-- dating_preferences: 본인 것만 관리
CREATE POLICY "Anon can manage dating_preferences" ON dating_preferences
    FOR ALL USING (true);

-- dating_recommendations: 읽기/쓰기 허용
CREATE POLICY "Anon can manage dating_recommendations" ON dating_recommendations
    FOR ALL USING (true);

-- dating_likes: 읽기/쓰기 허용
CREATE POLICY "Anon can manage dating_likes" ON dating_likes
    FOR ALL USING (true);

-- dating_matches: 읽기 허용
CREATE POLICY "Anon can read dating_matches" ON dating_matches
    FOR SELECT USING (true);

CREATE POLICY "Anon can insert dating_matches" ON dating_matches
    FOR INSERT WITH CHECK (true);

-- =====================================================
-- 함수: 매치 생성 (양방향 좋아요 시 자동)
-- =====================================================
CREATE OR REPLACE FUNCTION check_and_create_match()
RETURNS TRIGGER AS $$
DECLARE
    v_other_like BOOLEAN;
    v_user1 UUID;
    v_user2 UUID;
BEGIN
    -- 좋아요인 경우만 처리
    IF NEW.action != 'like' THEN
        RETURN NEW;
    END IF;
    
    -- 상대방도 나를 좋아요 했는지 확인
    SELECT EXISTS(
        SELECT 1 FROM dating_likes
        WHERE user_id = NEW.target_user_id
        AND target_user_id = NEW.user_id
        AND action = 'like'
    ) INTO v_other_like;
    
    -- 양방향 좋아요면 매치 생성
    IF v_other_like THEN
        -- ID 순서 정규화 (user1_id < user2_id)
        IF NEW.user_id < NEW.target_user_id THEN
            v_user1 := NEW.user_id;
            v_user2 := NEW.target_user_id;
        ELSE
            v_user1 := NEW.target_user_id;
            v_user2 := NEW.user_id;
        END IF;
        
        -- 매치 생성 (중복 무시)
        INSERT INTO dating_matches (user1_id, user2_id)
        VALUES (v_user1, v_user2)
        ON CONFLICT (user1_id, user2_id) DO NOTHING;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_check_match ON dating_likes;
CREATE TRIGGER trigger_check_match
    AFTER INSERT ON dating_likes
    FOR EACH ROW
    EXECUTE FUNCTION check_and_create_match();

-- =====================================================
-- 함수: 오늘의 추천 생성 (온디맨드)
-- =====================================================
CREATE OR REPLACE FUNCTION generate_daily_recommendations(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 3
) RETURNS TABLE (
    recommended_user_id UUID,
    mbti TEXT,
    birth_year SMALLINT,
    job TEXT,
    keywords TEXT[],
    bio TEXT,
    photo_path TEXT
) AS $$
DECLARE
    v_today DATE := (CURRENT_DATE AT TIME ZONE 'Asia/Seoul');
    v_existing_count INTEGER;
    v_user_gender TEXT;
    v_target_gender TEXT;
    v_target_mbti TEXT[];
    v_age_min SMALLINT;
    v_age_max SMALLINT;
    v_current_year SMALLINT := EXTRACT(YEAR FROM CURRENT_DATE)::SMALLINT;
BEGIN
    -- 오늘 이미 추천된 수 확인
    SELECT COUNT(*) INTO v_existing_count
    FROM dating_recommendations dr
    WHERE dr.user_id = p_user_id AND dr.date_key = v_today;
    
    -- 이미 3명 추천 완료면 기존 추천 반환
    IF v_existing_count >= p_limit THEN
        RETURN QUERY
        SELECT dp.user_id, dp.mbti, dp.birth_year, dp.job, dp.keywords, dp.bio, dp.photo_path
        FROM dating_recommendations dr
        JOIN dating_profiles dp ON dp.user_id = dr.recommended_user_id
        WHERE dr.user_id = p_user_id AND dr.date_key = v_today
        ORDER BY dr.rank;
        RETURN;
    END IF;
    
    -- 사용자 프로필 및 선호도 조회
    SELECT dp.gender INTO v_user_gender
    FROM dating_profiles dp
    WHERE dp.user_id = p_user_id;
    
    SELECT 
        COALESCE(dpr.target_gender, CASE v_user_gender WHEN 'male' THEN 'female' ELSE 'male' END),
        dpr.target_mbti,
        dpr.age_min,
        dpr.age_max
    INTO v_target_gender, v_target_mbti, v_age_min, v_age_max
    FROM dating_preferences dpr
    WHERE dpr.user_id = p_user_id;
    
    -- 선호도가 없으면 기본값
    IF v_target_gender IS NULL THEN
        v_target_gender := CASE v_user_gender WHEN 'male' THEN 'female' ELSE 'male' END;
    END IF;
    IF v_age_min IS NULL THEN v_age_min := 20; END IF;
    IF v_age_max IS NULL THEN v_age_max := 40; END IF;
    
    -- 새 추천 생성
    INSERT INTO dating_recommendations (user_id, recommended_user_id, date_key, rank)
    SELECT 
        p_user_id,
        dp.user_id,
        v_today,
        ROW_NUMBER() OVER (ORDER BY RANDOM())
    FROM dating_profiles dp
    WHERE dp.user_id != p_user_id
      AND dp.status = 'active'
      AND dp.gender = v_target_gender
      -- 나이 필터 (출생년도 기준)
      AND (v_current_year - dp.birth_year) BETWEEN v_age_min AND v_age_max
      -- MBTI 필터 (비어있으면 모두 허용)
      AND (v_target_mbti IS NULL OR array_length(v_target_mbti, 1) IS NULL OR dp.mbti = ANY(v_target_mbti))
      -- 이미 오늘 추천된 사람 제외
      AND NOT EXISTS (
          SELECT 1 FROM dating_recommendations dr2
          WHERE dr2.user_id = p_user_id 
          AND dr2.recommended_user_id = dp.user_id
          AND dr2.date_key = v_today
      )
      -- 이미 좋아요/패스한 사람 제외
      AND NOT EXISTS (
          SELECT 1 FROM dating_likes dl
          WHERE dl.user_id = p_user_id AND dl.target_user_id = dp.user_id
      )
      -- 최근 7일 내 추천된 사람 제외 (재추천 방지)
      AND NOT EXISTS (
          SELECT 1 FROM dating_recommendations dr3
          WHERE dr3.user_id = p_user_id 
          AND dr3.recommended_user_id = dp.user_id
          AND dr3.date_key > v_today - INTERVAL '7 days'
      )
    ORDER BY RANDOM()
    LIMIT (p_limit - v_existing_count);
    
    -- 최종 추천 반환
    RETURN QUERY
    SELECT dp.user_id, dp.mbti, dp.birth_year, dp.job, dp.keywords, dp.bio, dp.photo_path
    FROM dating_recommendations dr
    JOIN dating_profiles dp ON dp.user_id = dr.recommended_user_id
    WHERE dr.user_id = p_user_id AND dr.date_key = v_today
    ORDER BY dr.rank;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 코멘트
-- =====================================================
COMMENT ON TABLE dating_profiles IS 'MBTI 소개팅 프로필 (추가 정보)';
COMMENT ON TABLE dating_preferences IS 'MBTI 소개팅 선호도 설정';
COMMENT ON TABLE dating_recommendations IS '일일 추천 기록 (하루 3명)';
COMMENT ON TABLE dating_likes IS '좋아요/패스 기록';
COMMENT ON TABLE dating_matches IS '매치 (양방향 좋아요)';
COMMENT ON FUNCTION generate_daily_recommendations IS '오늘의 추천 3명 생성 (온디맨드)';
COMMENT ON FUNCTION check_and_create_match IS '양방향 좋아요 시 자동 매치 생성';
