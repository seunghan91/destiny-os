-- =====================================================
-- Tojung Premium Reports (server storage)
-- =====================================================

create extension if not exists "uuid-ossp";

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
    select 1 from pg_policies where tablename = 'tojung_reports' and policyname = 'Anyone can insert tojung_reports'
  ) then
    create policy "Anyone can insert tojung_reports" on public.tojung_reports
      for insert with check (true);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_policies where tablename = 'tojung_reports' and policyname = 'Anyone can read tojung_reports'
  ) then
    create policy "Anyone can read tojung_reports" on public.tojung_reports
      for select using (true);
  end if;
end $$;
