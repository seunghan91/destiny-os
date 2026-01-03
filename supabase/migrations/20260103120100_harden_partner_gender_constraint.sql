-- =====================================================
-- partner_gender 제약 강화
-- male/female만 허용하도록 제약 조건 강화
-- =====================================================

-- 1. 기존 데이터 정규화 (M → male, F → female)
UPDATE compatibility_results
SET partner_gender = CASE
  WHEN UPPER(partner_gender) IN ('M', 'MALE') THEN 'male'
  WHEN UPPER(partner_gender) IN ('F', 'FEMALE') THEN 'female'
  ELSE partner_gender
END
WHERE partner_gender NOT IN ('male', 'female');

-- 2. 기존 제약 조건 삭제 (있다면)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'compatibility_results_partner_gender_check'
  ) THEN
    ALTER TABLE compatibility_results
      DROP CONSTRAINT compatibility_results_partner_gender_check;
  END IF;
END $$;

-- 3. 새로운 제약 조건 추가 (male/female만 허용)
ALTER TABLE compatibility_results
  ADD CONSTRAINT compatibility_results_partner_gender_check
  CHECK (partner_gender IN ('male', 'female'));

-- 4. user_results.gender도 동일하게 강화
UPDATE user_results
SET gender = CASE
  WHEN UPPER(gender) IN ('M', 'MALE', '남', '남성') THEN 'male'
  WHEN UPPER(gender) IN ('F', 'FEMALE', '여', '여성') THEN 'female'
  ELSE gender
END
WHERE gender NOT IN ('male', 'female');

-- user_results.gender 제약 조건 강화
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'user_results_gender_check'
  ) THEN
    ALTER TABLE user_results
      DROP CONSTRAINT user_results_gender_check;
  END IF;
END $$;

ALTER TABLE user_results
  ADD CONSTRAINT user_results_gender_check
  CHECK (gender IN ('male', 'female'));

-- 5. 주석 추가
COMMENT ON CONSTRAINT compatibility_results_partner_gender_check ON compatibility_results IS
  '파트너 성별은 male 또는 female만 허용합니다.';

COMMENT ON CONSTRAINT user_results_gender_check ON user_results IS
  '사용자 성별은 male 또는 female만 허용합니다.';
