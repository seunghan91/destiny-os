/**
 * Supabase Edge Function: webhook
 *
 * 토스페이먼츠 웹훅 수신 처리
 *
 * 이벤트 타입:
 * - PAYMENT_STATUS_CHANGED: 결제 상태 변경
 * - DEPOSIT_CALLBACK: 가상계좌 입금/취소
 * - CANCEL_STATUS_CHANGED: 결제 취소 상태 변경
 * - BILLING_DELETED: 빌링키 삭제
 *
 * Flow:
 * 1. 웹훅 수신 및 서명 검증
 * 2. 이벤트 타입별 처리
 * 3. DB 업데이트
 * 4. 10초 내 200 응답 (재전송 방지)
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { createHmac } from 'https://deno.land/std@0.168.0/node/crypto.ts';

interface WebhookEvent {
  eventType: string;
  createdAt: string;
  data: any;
}

/**
 * 웹훅 서명 검증 (보안)
 */
function verifyWebhookSignature(
  payload: string,
  signature: string,
  secret: string
): boolean {
  const computedSignature = createHmac('sha256', secret)
    .update(payload)
    .digest('hex');

  return computedSignature === signature;
}

serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, toss-signature',
  };

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    console.log('🔔 웹훅 수신...');

    // 1. Supabase 클라이언트
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 2. 요청 본문
    const rawBody = await req.text();
    const event: WebhookEvent = JSON.parse(rawBody);

    console.log(`이벤트 타입: ${event.eventType}`);

    // 3. 서명 검증 (선택사항, 프로덕션 권장)
    const signature = req.headers.get('Toss-Signature');
    const webhookSecret = Deno.env.get('TOSS_WEBHOOK_SECRET');

    if (webhookSecret && signature) {
      const isValid = verifyWebhookSignature(rawBody, signature, webhookSecret);
      if (!isValid) {
        console.error('⚠️ 웹훅 서명 검증 실패');
        throw new Error('Invalid webhook signature');
      }
    }

    // 4. 웹훅 이벤트 로그 저장
    await supabase
      .from('webhook_events')
      .insert({
        event_type: event.eventType,
        payment_key: event.data?.paymentKey,
        payload: event,
        processed: false,
      });

    // 5. 이벤트 타입별 처리
    switch (event.eventType) {
      case 'PAYMENT_STATUS_CHANGED':
        await handlePaymentStatusChanged(supabase, event.data);
        break;

      case 'DEPOSIT_CALLBACK':
        await handleDepositCallback(supabase, event.data);
        break;

      case 'CANCEL_STATUS_CHANGED':
        await handleCancelStatusChanged(supabase, event.data);
        break;

      case 'BILLING_DELETED':
        await handleBillingDeleted(supabase, event.data);
        break;

      default:
        console.log(`처리되지 않은 이벤트 타입: ${event.eventType}`);
    }

    // 6. 이벤트 처리 완료 표시
    await supabase
      .from('webhook_events')
      .update({ processed: true, processed_at: new Date().toISOString() })
      .eq('payment_key', event.data?.paymentKey)
      .eq('event_type', event.eventType);

    // 7. 10초 내 200 응답 (중요!)
    return new Response(
      JSON.stringify({ success: true }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );

  } catch (error) {
    console.error('웹훅 처리 오류:', error);

    // 실패 시에도 200 반환 (재전송 방지)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );
  }
});

/**
 * 결제 상태 변경 처리
 */
async function handlePaymentStatusChanged(supabase: any, data: any) {
  console.log('💳 결제 상태 변경:', data.status);

  const { error } = await supabase
    .from('payments')
    .update({
      payment_status: data.status,
      updated_at: new Date().toISOString(),
    })
    .eq('payment_key', data.paymentKey);

  if (error) {
    console.error('결제 상태 업데이트 실패:', error);
    throw error;
  }
}

/**
 * 가상계좌 입금 처리
 */
async function handleDepositCallback(supabase: any, data: any) {
  console.log('🏦 가상계좌 입금:', data.status);

  if (data.status === 'DONE') {
    // 입금 완료 시 결제 상태 업데이트
    const { error } = await supabase
      .from('payments')
      .update({
        payment_status: 'DONE',
        approved_at: data.approvedAt,
        updated_at: new Date().toISOString(),
      })
      .eq('payment_key', data.paymentKey);

    if (error) {
      console.error('가상계좌 입금 처리 실패:', error);
      throw error;
    }

    // TODO: 사용자에게 입금 완료 알림 전송
  }
}

/**
 * 결제 취소 상태 변경 처리
 */
async function handleCancelStatusChanged(supabase: any, data: any) {
  console.log('🔄 결제 취소:', data.cancels);

  const { error } = await supabase
    .from('payments')
    .update({
      payment_status: 'CANCELED',
      canceled_at: new Date().toISOString(),
      metadata: {
        cancels: data.cancels,
      },
      updated_at: new Date().toISOString(),
    })
    .eq('payment_key', data.paymentKey);

  if (error) {
    console.error('결제 취소 처리 실패:', error);
    throw error;
  }

  // TODO: 사용자에게 취소 완료 알림
}

/**
 * 빌링키 삭제 처리
 */
async function handleBillingDeleted(supabase: any, data: any) {
  console.log('🗑️ 빌링키 삭제:', data.billingKey);

  // 해당 빌링키의 구독 비활성화
  const { error } = await supabase
    .from('subscriptions')
    .update({
      status: 'CANCELED',
      canceled_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq('billing_key', data.billingKey);

  if (error) {
    console.error('빌링키 삭제 처리 실패:', error);
    throw error;
  }

  // TODO: 사용자에게 구독 취소 알림
}
