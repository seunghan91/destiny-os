-- ============================================
-- 관상 분석 리포트 테이블 및 Storage 설정
-- ============================================

-- 1. physiognomy_reports 테이블 생성
CREATE TABLE IF NOT EXISTS physiognomy_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_uid TEXT NOT NULL,
  image_path TEXT,
  card_image_path TEXT,
  features_json JSONB,
  saju_snapshot JSONB,
  mbti TEXT,
  report_markdown TEXT NOT NULL,
  model TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days')
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_physiognomy_reports_firebase_uid 
  ON physiognomy_reports(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_physiognomy_reports_created_at 
  ON physiognomy_reports(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_physiognomy_reports_expires_at 
  ON physiognomy_reports(expires_at);

-- RLS 활성화
ALTER TABLE physiognomy_reports ENABLE ROW LEVEL SECURITY;

-- RLS 정책: 본인 데이터만 조회 가능
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'physiognomy_reports' 
    AND policyname = 'Users can view own physiognomy reports'
  ) THEN
    CREATE POLICY "Users can view own physiognomy reports" 
    ON physiognomy_reports FOR SELECT
    USING (
      firebase_uid = (
        SELECT firebase_uid FROM users 
        WHERE auth_id = auth.uid()
        LIMIT 1
      )
    );
  END IF;
END $$;

-- 2. 리포트 저장 RPC 함수
CREATE OR REPLACE FUNCTION physiognomy_insert_report(
  p_firebase_uid TEXT,
  p_image_path TEXT DEFAULT NULL,
  p_card_image_path TEXT DEFAULT NULL,
  p_features_json JSONB DEFAULT '{}'::jsonb,
  p_saju_snapshot JSONB DEFAULT '{}'::jsonb,
  p_mbti TEXT DEFAULT NULL,
  p_report_markdown TEXT DEFAULT '',
  p_model TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO physiognomy_reports (
    firebase_uid,
    image_path,
    card_image_path,
    features_json,
    saju_snapshot,
    mbti,
    report_markdown,
    model,
    metadata
  ) VALUES (
    p_firebase_uid,
    p_image_path,
    p_card_image_path,
    p_features_json,
    p_saju_snapshot,
    p_mbti,
    p_report_markdown,
    p_model,
    p_metadata
  )
  RETURNING id INTO v_id;
  
  RETURN v_id::TEXT;
END;
$$;

-- 3. 리포트 목록 조회 RPC 함수
CREATE OR REPLACE FUNCTION physiognomy_list_reports(
  p_firebase_uid TEXT,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  created_at TIMESTAMPTZ,
  image_path TEXT,
  card_image_path TEXT,
  features_json JSONB,
  report_markdown TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    pr.id,
    pr.created_at,
    pr.image_path,
    pr.card_image_path,
    pr.features_json,
    pr.report_markdown
  FROM physiognomy_reports pr
  WHERE pr.firebase_uid = p_firebase_uid
  ORDER BY pr.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- 4. Storage 버킷 생성 (수동으로 Supabase Dashboard에서 생성 필요)
-- physiognomy-faces: 얼굴 이미지 저장 (private)
-- physiognomy-cards: 생성된 카드 이미지 저장 (private)

-- Storage 정책 예시 (Dashboard에서 설정):
-- INSERT: authenticated users can upload to their own folder (uid/*)
-- SELECT: authenticated users can read their own files (uid/*)
-- DELETE: authenticated users can delete their own files (uid/*)

-- 5. 만료된 이미지 정리 함수 (Cron으로 실행)
CREATE OR REPLACE FUNCTION cleanup_expired_physiognomy_images()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- 만료된 레코드의 image_path를 null로 설정 (실제 Storage 삭제는 별도 처리)
  UPDATE physiognomy_reports
  SET 
    image_path = NULL,
    metadata = metadata || '{"image_deleted": true}'::jsonb
  WHERE expires_at < NOW()
    AND image_path IS NOT NULL;
END;
$$;

-- 6. products 테이블에 관상 상품 추가
INSERT INTO products (name, description, product_type, price, features) VALUES
('관상 종합분석 1회', '관상+사주+토정+MBTI 통합 신년운세 리포트', 'single', 5000,
 '["Gemini Vision 기반 얼굴 분석", "사주/토정/MBTI 통합", "2026 신년운세 형식", "요약 카드 이미지"]'::jsonb)
ON CONFLICT DO NOTHING;

-- 완료 메시지
DO $$
BEGIN
  RAISE NOTICE '✅ physiognomy_reports table and functions created successfully';
END $$;
