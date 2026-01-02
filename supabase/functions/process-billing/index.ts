/**
 * Supabase Edge Function: process-billing
 *
 * 정기 구독 자동 결제 처리 (Cron Job)
 *
 * 실행 주기: 매일 자정 (Supabase Cron 설정)
 *
 * Flow:
 * 1. next_billing_date가 오늘인 구독 조회
 * 2. 각 구독마다 빌링키로 자동 결제 요청
 * 3. 결제 성공 시 DB 업데이트 (다음 결제일 +1개월)
 * 4. 결제 실패 시 재시도 로직 또는 구독 일시중지
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface Subscription {
  id: string;
  user_id: string;
  product_id: string;
  billing_key: string;
  customer_key: string;
  tier: string;
  amount: number;
  next_billing_date: string;
  current_period_end: string;
}

interface BillingPaymentResponse {
  paymentKey: string;
  orderId: string;
  status: string;
  totalAmount: number;
  method: string;
  approvedAt: string;
  receipt: {
    url: string;
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
    console.log('🔄 정기 결제 자동 처리 시작...');

    // 1. Supabase 클라이언트 (Service Role Key 사용)
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 2. 오늘 날짜 (YYYY-MM-DD)
    const today = new Date().toISOString().split('T')[0];

    console.log(`📅 오늘 날짜: ${today}`);

    // 3. 오늘 결제해야 할 구독 조회
    const { data: subscriptions, error: fetchError } = await supabase
      .from('subscriptions')
      .select('*')
      .eq('status', 'ACTIVE')
      .lte('next_billing_date', `${today}T23:59:59`);

    if (fetchError) {
      throw new Error(`구독 조회 실패: ${fetchError.message}`);
    }

    console.log(`📊 처리할 구독 수: ${subscriptions?.length || 0}`);

    if (!subscriptions || subscriptions.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: '오늘 처리할 구독이 없습니다',
          processed: 0,
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      );
    }

    // 4. 토스페이먼츠 시크릿 키
    const tossSecretKey = Deno.env.get('TOSS_SECRET_KEY') ?? '';
    const encodedKey = btoa(tossSecretKey + ':');

    // 5. 각 구독마다 자동 결제 처리
    const results = [];

    for (const subscription of subscriptions as Subscription[]) {
      try {
        console.log(`💳 구독 처리 중: ${subscription.id}`);

        // 5-1. orderId 생성 (고유값)
        const orderId = `sub_${subscription.id}_${Date.now()}`;
        const orderName = `${subscription.tier} 구독 - ${today}`;

        // 5-2. 빌링키로 자동 결제 요청
        const billingResponse = await fetch(
          `https://api.tosspayments.com/v1/billing/${subscription.billing_key}`,
          {
            method: 'POST',
            headers: {
              'Authorization': `Basic ${encodedKey}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              customerKey: subscription.customer_key,
              amount: subscription.amount,
              orderId: orderId,
              orderName: orderName,
            }),
          }
        );

        const paymentData: BillingPaymentResponse = await billingResponse.json();

        if (!billingResponse.ok) {
          throw new Error(paymentData['message'] || '자동 결제 실패');
        }

        console.log(`✅ 결제 성공: ${paymentData.paymentKey}`);

        // 5-3. payments 테이블에 저장
        const { data: payment, error: paymentInsertError } = await supabase
          .from('payments')
          .insert({
            user_id: subscription.user_id,
            product_id: subscription.product_id,
            payment_key: paymentData.paymentKey,
            order_id: orderId,
            order_name: orderName,
            amount: subscription.amount,
            payment_method: paymentData.method,
            payment_status: 'DONE',
            approved_at: paymentData.approvedAt,
            receipt_url: paymentData.receipt?.url,
          })
          .select()
          .single();

        if (paymentInsertError) {
          console.error('결제 정보 저장 실패:', paymentInsertError);
          throw paymentInsertError;
        }

        // 5-4. subscription_payments 기록
        await supabase
          .from('subscription_payments')
          .insert({
            subscription_id: subscription.id,
            payment_id: payment.id,
            billing_date: today,
            amount: subscription.amount,
            status: 'SUCCESS',
          });

        // 5-5. subscriptions 테이블 업데이트 (다음 결제일 +1개월)
        const nextBillingDate = new Date(subscription.next_billing_date);
        nextBillingDate.setMonth(nextBillingDate.getMonth() + 1);

        const { error: updateError } = await supabase
          .from('subscriptions')
          .update({
            current_period_start: subscription.current_period_end,
            current_period_end: nextBillingDate.toISOString(),
            next_billing_date: nextBillingDate.toISOString(),
            updated_at: new Date().toISOString(),
          })
          .eq('id', subscription.id);

        if (updateError) {
          console.error('구독 갱신 실패:', updateError);
        }

        // 5-6. users 테이블 업데이트
        await supabase
          .from('users')
          .update({
            subscription_expires_at: nextBillingDate.toISOString(),
          })
          .eq('id', subscription.user_id);

        results.push({
          subscription_id: subscription.id,
          user_id: subscription.user_id,
          status: 'success',
          amount: subscription.amount,
          next_billing_date: nextBillingDate.toISOString(),
        });

      } catch (error) {
        console.error(`❌ 구독 ${subscription.id} 결제 실패:`, error);

        // 실패 기록
        await supabase
          .from('subscription_payments')
          .insert({
            subscription_id: subscription.id,
            billing_date: today,
            amount: subscription.amount,
            status: 'FAILED',
          });

        // TODO: 재시도 로직 (3회 실패 시 구독 일시중지)
        // TODO: 이메일 알림 전송

        results.push({
          subscription_id: subscription.id,
          user_id: subscription.user_id,
          status: 'failed',
          error: error.message,
        });
      }
    }

    console.log('✅ 정기 결제 처리 완료');

    // 6. 응답
    return new Response(
      JSON.stringify({
        success: true,
        processed: subscriptions.length,
        results: results,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );

  } catch (error) {
    console.error('정기 결제 처리 오류:', error);

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
});
