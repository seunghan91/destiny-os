-- ============================================
-- Destiny.OS 통합 마이그레이션
-- ============================================

-- 0. Extensions 활성화
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_cron";

-- 1. users 테이블 생성
-- ============================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_id UUID UNIQUE,
  email TEXT UNIQUE,
  username TEXT,
  device_id TEXT,
  subscription_tier VARCHAR(20) DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium')),
  subscription_status VARCHAR(20) DEFAULT 'inactive' CHECK (subscription_status IN ('inactive', 'active', 'paused', 'canceled', 'expired')),
  billing_key TEXT,
  subscription_started_at TIMESTAMP,
  subscription_expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_auth_id ON users(auth_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_device_id ON users(device_id);
CREATE INDEX IF NOT EXISTS idx_users_subscription_status ON users(subscription_status);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'Users can view own data'
  ) THEN
    CREATE POLICY "Users can view own data" ON users FOR SELECT
    USING (auth.uid() = auth_id OR auth.uid()::text = device_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'Users can update own data'
  ) THEN
    CREATE POLICY "Users can update own data" ON users FOR UPDATE
    USING (auth.uid() = auth_id OR auth.uid()::text = device_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'Enable insert for authenticated users'
  ) THEN
    CREATE POLICY "Enable insert for authenticated users" ON users FOR INSERT
    WITH CHECK (true);
  END IF;
END $$;

CREATE OR REPLACE FUNCTION update_users_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_users_updated_at();

-- 2. 결제 시스템 테이블 생성
-- ============================================

CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  description TEXT,
  product_type VARCHAR(20) NOT NULL CHECK (product_type IN ('single', 'subscription')),
  price INTEGER NOT NULL CHECK (price >= 0),
  currency VARCHAR(3) DEFAULT 'KRW',
  features JSONB,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  payment_key VARCHAR(200) UNIQUE NOT NULL,
  order_id VARCHAR(100) UNIQUE NOT NULL,
  order_name VARCHAR(100) NOT NULL,
  amount INTEGER NOT NULL CHECK (amount >= 0),
  currency VARCHAR(3) DEFAULT 'KRW',
  payment_method VARCHAR(50),
  payment_status VARCHAR(20) NOT NULL CHECK (payment_status IN ('PENDING', 'DONE', 'CANCELED', 'FAILED')),
  requested_at TIMESTAMP DEFAULT NOW(),
  approved_at TIMESTAMP,
  canceled_at TIMESTAMP,
  failure_code VARCHAR(50),
  failure_message TEXT,
  receipt_url TEXT,
  metadata JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  billing_key TEXT NOT NULL,
  customer_key VARCHAR(100) NOT NULL,
  status VARCHAR(20) NOT NULL CHECK (status IN ('ACTIVE', 'PAUSED', 'CANCELED', 'EXPIRED')),
  tier VARCHAR(20) NOT NULL,
  started_at TIMESTAMP NOT NULL,
  current_period_start TIMESTAMP NOT NULL,
  current_period_end TIMESTAMP NOT NULL,
  canceled_at TIMESTAMP,
  billing_cycle VARCHAR(20) DEFAULT 'monthly' CHECK (billing_cycle IN ('monthly', 'yearly')),
  next_billing_date TIMESTAMP,
  amount INTEGER NOT NULL CHECK (amount >= 0),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS subscription_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID REFERENCES subscriptions(id) ON DELETE CASCADE,
  payment_id UUID REFERENCES payments(id),
  billing_date TIMESTAMP NOT NULL,
  amount INTEGER NOT NULL CHECK (amount >= 0),
  status VARCHAR(20) NOT NULL CHECK (status IN ('SUCCESS', 'FAILED', 'PENDING')),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS webhook_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(50) NOT NULL,
  payment_key VARCHAR(200),
  payload JSONB NOT NULL,
  processed BOOLEAN DEFAULT false,
  processed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(payment_status);
CREATE INDEX IF NOT EXISTS idx_payments_payment_key ON payments(payment_key);
CREATE INDEX IF NOT EXISTS idx_payments_created_at ON payments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_next_billing ON subscriptions(next_billing_date);
CREATE INDEX IF NOT EXISTS idx_webhook_events_processed ON webhook_events(processed);
CREATE INDEX IF NOT EXISTS idx_webhook_events_created_at ON webhook_events(created_at DESC);

-- RLS
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_payments ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'payments' AND policyname = 'Users can view own payments'
  ) THEN
    CREATE POLICY "Users can view own payments" ON payments FOR SELECT
    USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'subscriptions' AND policyname = 'Users can view own subscriptions'
  ) THEN
    CREATE POLICY "Users can view own subscriptions" ON subscriptions FOR SELECT
    USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'subscription_payments' AND policyname = 'Users can view own subscription payments'
  ) THEN
    CREATE POLICY "Users can view own subscription payments" ON subscription_payments FOR SELECT
    USING (
      EXISTS (
        SELECT 1 FROM subscriptions
        WHERE subscriptions.id = subscription_payments.subscription_id
        AND subscriptions.user_id = auth.uid()
      )
    );
  END IF;
END $$;

-- 초기 데이터
INSERT INTO products (name, description, product_type, price, features) VALUES
('AI 상담 1회', '사주/MBTI 기반 AI 맞춤 상담', 'single', 3000,
 '["GPT-4o 기반 상담", "개인화된 조언", "24시간 이내 답변"]'::jsonb),
('상세 운세 분석', '2026년 상세 월별 운세 리포트', 'single', 5000,
 '["12개월 상세 분석", "대운 타임라인", "PDF 다운로드"]'::jsonb),
('프리미엄 구독', '모든 기능 무제한 이용', 'subscription', 9900,
 '["무제한 AI 상담", "월별 운세 자동 업데이트", "광고 제거", "우선 지원"]'::jsonb)
ON CONFLICT DO NOTHING;

-- 트리거
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_products_updated_at ON products;
CREATE TRIGGER update_products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_payments_updated_at ON payments;
CREATE TRIGGER update_payments_updated_at
  BEFORE UPDATE ON payments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_subscriptions_updated_at ON subscriptions;
CREATE TRIGGER update_subscriptions_updated_at
  BEFORE UPDATE ON subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- 3. Cron Job 설정
-- ============================================

-- 기존 작업 삭제 (있다면)
SELECT cron.unschedule('daily-subscription-billing') WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'daily-subscription-billing'
);

-- 새 작업 등록
SELECT cron.schedule(
  'daily-subscription-billing',
  '0 0 * * *',
  $$
  SELECT
    net.http_post(
      url := 'https://eunnaxqjyitxjdkrjaau.supabase.co/functions/v1/process-billing',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV1bm5heHFqeWl0eGpka3JqYWF1Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzI1MjU4MiwiZXhwIjoyMDgyODI4NTgyfQ.Zni8PJeHaVhBh2jTqQZW_04TODBMtToEBAqejz3tdzM'
      ),
      body := '{}'::jsonb
    );
  $$
);

-- 확인
SELECT * FROM cron.job WHERE jobname = 'daily-subscription-billing';
