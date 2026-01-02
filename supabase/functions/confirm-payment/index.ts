/**
 * Supabase Edge Function: confirm-payment
 *
 * 토스페이먼츠 결제 승인 처리
 *
 * Flow:
 * 1. Flutter 앱에서 paymentKey, orderId, amount 전달
 * 2. DB에 저장된 초기 금액과 비교 검증
 * 3. 토스페이먼츠 API로 결제 승인 요청
 * 4. 결제 정보 DB에 저장
 * 5. 결과 반환
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface ConfirmPaymentRequest {
  paymentKey: string;
  orderId: string;
  amount: number;
}

interface TossPaymentResponse {
  paymentKey: string;
  orderId: string;
  status: string;
  method: string;
  totalAmount: number;
  approvedAt: string;
  receipt: {
    url: string;
  };
}

serve(async (req) => {
  // CORS 헤더 설정
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };

  // OPTIONS 요청 처리 (CORS preflight)
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 1. 요청 파라미터 추출
    const { paymentKey, orderId, amount }: ConfirmPaymentRequest = await req.json();

    if (!paymentKey || !orderId || !amount) {
      throw new Error('필수 파라미터 누락: paymentKey, orderId, amount');
    }

    // 2. Supabase 클라이언트 초기화
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 3. 사용자 인증 확인
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('인증 정보 없음');
    }

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      throw new Error('인증 실패');
    }

    // 4. 결제 금액 검증 (DB의 초기 금액과 비교)
    const { data: storedPayment, error: fetchError } = await supabase
      .from('payments')
      .select('amount, payment_status')
      .eq('order_id', orderId)
      .single();

    if (fetchError) {
      throw new Error('주문 정보를 찾을 수 없습니다');
    }

    if (storedPayment.amount !== amount) {
      throw new Error(`결제 금액 불일치: 요청=${amount}, 저장=${storedPayment.amount}`);
    }

    if (storedPayment.payment_status === 'DONE') {
      throw new Error('이미 승인된 결제입니다');
    }

    // 5. 토스페이먼츠 결제 승인 API 호출
    const tossSecretKey = Deno.env.get('TOSS_SECRET_KEY') ?? '';
    const encodedKey = btoa(tossSecretKey + ':');

    const tossResponse = await fetch(
      'https://api.tosspayments.com/v1/payments/confirm',
      {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${encodedKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          paymentKey,
          orderId,
          amount,
        }),
      }
    );

    if (!tossResponse.ok) {
      const errorData = await tossResponse.json();
      throw new Error(`토스 결제 승인 실패: ${errorData.message}`);
    }

    const paymentData: TossPaymentResponse = await tossResponse.json();

    // 6. 결제 정보 DB 업데이트
    const { data: updatedPayment, error: updateError } = await supabase
      .from('payments')
      .update({
        payment_key: paymentData.paymentKey,
        payment_status: 'DONE',
        payment_method: paymentData.method,
        approved_at: paymentData.approvedAt,
        receipt_url: paymentData.receipt?.url,
        updated_at: new Date().toISOString(),
      })
      .eq('order_id', orderId)
      .select()
      .single();

    if (updateError) {
      console.error('결제 정보 업데이트 실패:', updateError);
      throw new Error('결제 정보 저장 실패');
    }

    // 7. 성공 응답
    return new Response(
      JSON.stringify({
        success: true,
        payment: updatedPayment,
        receiptUrl: paymentData.receipt?.url,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );

  } catch (error) {
    console.error('결제 승인 오류:', error);

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
