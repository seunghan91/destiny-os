-- =====================================================
-- Tojung Premium Reports (server storage)
-- =====================================================

create extension if not exists "uuid-ossp";

-- =====================================================
-- Tojung Premium Passes (1회권)
-- =====================================================

create table if not exists public.tojung_premium_passes (
  id uuid default gen_random_uuid() primary key,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  user_profile_id uuid not null references public.user_profiles(id) on delete cascade,
  firebase_uid text not null,
  remaining int not null default 0 check (remaining >= 0),

  constraint unique_tojung_premium_passes_user unique (user_profile_id),
  constraint unique_tojung_premium_passes_firebase_uid unique (firebase_uid)
);

create index if not exists idx_tojung_premium_passes_profile_id
  on public.tojung_premium_passes(user_profile_id);

alter table public.tojung_premium_passes enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies where tablename = 'tojung_premium_passes' and policyname = 'Service role full access on tojung_premium_passes'
  ) then
    create policy "Service role full access on tojung_premium_passes" on public.tojung_premium_passes
      for all using (auth.role() = 'service_role');
  end if;
end $$;

create table if not exists public.tojung_reports (
  id uuid default gen_random_uuid() primary key,
  created_at timestamptz default now(),

  -- Firebase Auth 기반 식별자
  firebase_uid text not null,
  user_profile_id uuid references public.user_profiles(id) on delete cascade,

  -- 입력 스냅샷 (재현/감사 용도)
  year int not null default 2026,
  mbti text,
  saju_snapshot jsonb default '{}'::jsonb,

  -- 생성 결과
  report_markdown text not null,
  model text,
  tokens_in int,
  tokens_out int,
  metadata jsonb default '{}'::jsonb
);

create index if not exists idx_tojung_reports_profile_created_at
  on public.tojung_reports(user_profile_id, created_at desc);

create index if not exists idx_tojung_reports_firebase_uid_created_at
  on public.tojung_reports(firebase_uid, created_at desc);

alter table public.tojung_reports enable row level security;

-- NOTE:
-- 현재 프로젝트는 Firebase Auth 중심이며 Supabase Auth 세션이 없는 경우가 많아
-- auth.uid() 기반의 엄격한 RLS를 적용하면 클라이언트 저장이 막힐 수 있습니다.
-- 우선은 기존 패턴처럼 클라이언트 저장/조회가 가능하도록 열어두고,
-- 추후 Edge Function + Firebase 토큰 검증 방식으로 강화 권장.

do $$
begin
  if not exists (
    select 1 from pg_policies where tablename = 'tojung_reports' and policyname = 'Service role full access on tojung_reports'
  ) then
    create policy "Service role full access on tojung_reports" on public.tojung_reports
      for all using (auth.role() = 'service_role');
  end if;
end $$;

-- =====================================================
-- RPC functions (Firebase UID 기반) - 클라이언트는 RPC로만 접근
-- =====================================================

create or replace function public.tojung_get_pass_balance(p_firebase_uid text)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_remaining int;
begin
  select remaining into v_remaining
  from public.tojung_premium_passes
  where firebase_uid = p_firebase_uid;

  return coalesce(v_remaining, 0);
end;
$$;

create or replace function public.tojung_add_pass(
  p_firebase_uid text,
  p_amount int,
  p_payment_id text default null,
  p_description text default null
)
returns table (
  success boolean,
  new_balance int,
  message text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_id uuid;
  v_current int;
  v_next int;
begin
  if p_amount is null or p_amount <= 0 then
    return query select false, 0, '추가할 이용권 수가 올바르지 않습니다.'::text;
    return;
  end if;

  select id into v_profile_id
  from public.user_profiles
  where firebase_uid = p_firebase_uid;

  if v_profile_id is null then
    return query select false, 0, '사용자를 찾을 수 없습니다.'::text;
    return;
  end if;

  insert into public.tojung_premium_passes (user_profile_id, firebase_uid, remaining)
  values (v_profile_id, p_firebase_uid, p_amount)
  on conflict (firebase_uid) do update
    set remaining = public.tojung_premium_passes.remaining + excluded.remaining,
        updated_at = now()
  returning remaining into v_next;

  if exists (select 1 from pg_tables where schemaname = 'public' and tablename = 'credit_transactions') then
    insert into public.credit_transactions (
      user_id,
      type,
      amount,
      balance_after,
      description,
      payment_id,
      feature_used,
      metadata
    ) values (
      v_profile_id,
      'purchase',
      p_amount,
      v_next,
      coalesce(p_description, '토정비결 종합분석 1회권 구매'),
      p_payment_id,
      'tojung_premium',
      jsonb_build_object('firebase_uid', p_firebase_uid)
    );
  end if;

  return query select true, v_next, '이용권이 추가되었습니다.'::text;
end;
$$;

create or replace function public.tojung_consume_pass(p_firebase_uid text)
returns table (
  success boolean,
  new_balance int,
  message text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_id uuid;
  v_current int;
  v_next int;
begin
  select id into v_profile_id
  from public.user_profiles
  where firebase_uid = p_firebase_uid;

  if v_profile_id is null then
    return query select false, 0, '사용자를 찾을 수 없습니다.'::text;
    return;
  end if;

  select remaining into v_current
  from public.tojung_premium_passes
  where firebase_uid = p_firebase_uid
  for update;

  if coalesce(v_current, 0) <= 0 then
    return query select false, coalesce(v_current, 0), '이용권이 부족합니다.'::text;
    return;
  end if;

  v_next := v_current - 1;
  update public.tojung_premium_passes
    set remaining = v_next,
        updated_at = now()
  where firebase_uid = p_firebase_uid;

  if exists (select 1 from pg_tables where schemaname = 'public' and tablename = 'credit_transactions') then
    insert into public.credit_transactions (
      user_id,
      type,
      amount,
      balance_after,
      description,
      feature_used,
      metadata
    ) values (
      v_profile_id,
      'use',
      -1,
      v_next,
      '토정비결 종합분석 1회 사용',
      'tojung_premium',
      jsonb_build_object('firebase_uid', p_firebase_uid)
    );
  end if;

  return query select true, v_next, '이용권이 차감되었습니다.'::text;
end;
$$;

create or replace function public.tojung_insert_report(
  p_firebase_uid text,
  p_year int,
  p_mbti text,
  p_saju_snapshot jsonb,
  p_report_markdown text,
  p_model text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_id uuid;
  v_id uuid;
begin
  select id into v_profile_id
  from public.user_profiles
  where firebase_uid = p_firebase_uid;

  if v_profile_id is null then
    raise exception '사용자를 찾을 수 없습니다.';
  end if;

  insert into public.tojung_reports (
    firebase_uid,
    user_profile_id,
    year,
    mbti,
    saju_snapshot,
    report_markdown,
    model,
    metadata
  ) values (
    p_firebase_uid,
    v_profile_id,
    coalesce(p_year, 2026),
    p_mbti,
    coalesce(p_saju_snapshot, '{}'::jsonb),
    p_report_markdown,
    p_model,
    coalesce(p_metadata, '{}'::jsonb)
  ) returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.tojung_list_reports(
  p_firebase_uid text,
  p_limit int default 20,
  p_offset int default 0
)
returns setof public.tojung_reports
language sql
security definer
set search_path = public
as $$
  select *
  from public.tojung_reports
  where firebase_uid = p_firebase_uid
  order by created_at desc
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
$$;
