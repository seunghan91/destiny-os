/**
 * Supabase Edge Function: create-subscription
 *
 * 정기 구독 생성 및 빌링키 발급
 *
 * Flow:
 * 1. 초회 결제 완료 후 빌링키 발급
 * 2. subscriptions 테이블에 구독 정보 저장
 * 3. users 테이블 업데이트 (구독 상태)
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface CreateSubscriptionRequest {
  paymentKey: string;
  customerKey: string;
  tier: 'premium' | 'pro';
  productId: string;
}

interface BillingKeyResponse {
  mId: string;
  customerKey: string;
  authenticatedAt: string;
  method: string;
  billingKey: string;
  card?: {
    company: string;
    number: string;
    cardType: string;
  };
}

serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 1. 요청 파라미터
    const { paymentKey, customerKey, tier, productId }: CreateSubscriptionRequest = await req.json();

    if (!paymentKey || !customerKey || !tier || !productId) {
      throw new Error('필수 파라미터 누락');
    }

    // 2. Supabase 클라이언트
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 3. 사용자 인증
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('인증 정보 없음');
    }

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      throw new Error('인증 실패');
    }

    // 4. 토스페이먼츠 빌링키 발급 API 호출
    const tossSecretKey = Deno.env.get('TOSS_SECRET_KEY') ?? '';
    const encodedKey = btoa(tossSecretKey + ':');

    const billingResponse = await fetch(
      `https://api.tosspayments.com/v1/billing/authorizations/issue`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${encodedKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          authKey: paymentKey, // 초회 결제의 paymentKey
          customerKey: customerKey,
        }),
      }
    );

    if (!billingResponse.ok) {
      const errorData = await billingResponse.json();
      throw new Error(`빌링키 발급 실패: ${errorData.message}`);
    }

    const billingData: BillingKeyResponse = await billingResponse.json();
    const billingKey = billingData.billingKey;

    console.log('빌링키 발급 성공:', billingKey);

    // 5. 구독 정보 계산
    const now = new Date();
    const currentPeriodEnd = new Date(now);
    currentPeriodEnd.setMonth(currentPeriodEnd.getMonth() + 1); // +1개월

    // 가격 결정
    const priceMap = {
      premium: 9900,
      pro: 19900,
    };
    const amount = priceMap[tier] || 9900;

    // 6. subscriptions 테이블에 저장
    const { data: subscription, error: insertError } = await supabase
      .from('subscriptions')
      .insert({
        user_id: user.id,
        product_id: productId,
        billing_key: billingKey,
        customer_key: customerKey,
        status: 'ACTIVE',
        tier: tier,
        started_at: now.toISOString(),
        current_period_start: now.toISOString(),
        current_period_end: currentPeriodEnd.toISOString(),
        next_billing_date: currentPeriodEnd.toISOString(),
        amount: amount,
        billing_cycle: 'monthly',
      })
      .select()
      .single();

    if (insertError) {
      console.error('구독 정보 저장 실패:', insertError);
      throw new Error('구독 생성 실패');
    }

    // 7. users 테이블 업데이트
    const { error: userUpdateError } = await supabase
      .from('users')
      .update({
        subscription_tier: tier,
        subscription_status: 'active',
        billing_key: billingKey,
        subscription_started_at: now.toISOString(),
        subscription_expires_at: currentPeriodEnd.toISOString(),
      })
      .eq('id', user.id);

    if (userUpdateError) {
      console.error('사용자 구독 상태 업데이트 실패:', userUpdateError);
      // 치명적이지 않으므로 계속 진행
    }

    // 8. 성공 응답
    return new Response(
      JSON.stringify({
        success: true,
        subscription: subscription,
        nextBillingDate: currentPeriodEnd.toISOString(),
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );

  } catch (error) {
    console.error('구독 생성 오류:', error);

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    );
  }
});
