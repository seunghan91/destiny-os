-- Hardening / robustness for user_results (non-breaking)
-- 1) Ensure uuid generation function exists (pgcrypto provides gen_random_uuid()).
create extension if not exists pgcrypto;

-- 2) Strengthen defaults / nullability (safe changes)
alter table public.user_results
  alter column is_lunar set default false;

-- 3) Add basic data quality constraints
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'user_results_birth_hour_range'
  ) then
    alter table public.user_results
      add constraint user_results_birth_hour_range
      check (birth_hour is null or (birth_hour >= 0 and birth_hour <= 23));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'user_results_gender_allowed'
  ) then
    alter table public.user_results
      add constraint user_results_gender_allowed
      check (gender in ('male', 'female'));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'user_results_mbti_format'
  ) then
    -- very lightweight guard (doesn't enforce 16 types strictly)
    alter table public.user_results
      add constraint user_results_mbti_format
      check (char_length(mbti) = 4);
  end if;
end $$;

-- 4) Performance: admin page sorts by created_at desc
create index if not exists user_results_created_at_idx
  on public.user_results (created_at desc);

