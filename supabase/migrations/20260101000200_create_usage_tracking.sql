-- Usage tracking for rate limiting
-- Track total app usage and notify when threshold reached

-- 1) App usage counter table
create table if not exists public.app_usage (
  id uuid primary key default gen_random_uuid(),
  date date not null default current_date,
  total_count integer not null default 0,
  saju_count integer not null default 0,
  mbti_count integer not null default 0,
  compatibility_count integer not null default 0,
  consultation_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint app_usage_date_unique unique (date)
);

-- 2) Usage alerts table (for developer notifications)
create table if not exists public.usage_alerts (
  id uuid primary key default gen_random_uuid(),
  alert_type text not null, -- 'threshold_warning', 'threshold_reached', 'service_paused'
  threshold_value integer not null,
  current_value integer not null,
  message text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

-- 3) App settings table (for global config)
create table if not exists public.app_settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

-- Insert default settings
insert into public.app_settings (key, value) values
  ('usage_limit', '{"daily_limit": 10000, "warning_threshold": 8000, "is_paused": false}'::jsonb),
  ('admin_email', '"seunghan@example.com"'::jsonb)
on conflict (key) do nothing;

-- 4) Function to increment usage and check limits
create or replace function public.increment_usage(usage_type text default 'general')
returns jsonb
language plpgsql
security definer
as $$
declare
  v_today date := current_date;
  v_usage record;
  v_settings jsonb;
  v_limit integer;
  v_warning integer;
  v_is_paused boolean;
  v_new_count integer;
begin
  -- Get settings
  select value into v_settings from public.app_settings where key = 'usage_limit';
  v_limit := coalesce((v_settings->>'daily_limit')::integer, 10000);
  v_warning := coalesce((v_settings->>'warning_threshold')::integer, 8000);
  v_is_paused := coalesce((v_settings->>'is_paused')::boolean, false);

  -- Check if service is paused
  if v_is_paused then
    return jsonb_build_object(
      'allowed', false,
      'reason', 'service_paused',
      'message', '서비스가 일시 중단되었습니다. 잠시 후 다시 시도해주세요.'
    );
  end if;

  -- Upsert today's usage
  insert into public.app_usage (date, total_count)
  values (v_today, 1)
  on conflict (date) do update
  set total_count = app_usage.total_count + 1,
      updated_at = now()
  returning * into v_usage;

  -- Update specific counter
  case usage_type
    when 'saju' then
      update public.app_usage set saju_count = saju_count + 1 where date = v_today;
    when 'mbti' then
      update public.app_usage set mbti_count = mbti_count + 1 where date = v_today;
    when 'compatibility' then
      update public.app_usage set compatibility_count = compatibility_count + 1 where date = v_today;
    when 'consultation' then
      update public.app_usage set consultation_count = consultation_count + 1 where date = v_today;
    else
      -- general, no specific counter
      null;
  end case;

  v_new_count := v_usage.total_count;

  -- Check if limit reached
  if v_new_count >= v_limit then
    -- Auto-pause service
    update public.app_settings
    set value = value || '{"is_paused": true}'::jsonb,
        updated_at = now()
    where key = 'usage_limit';

    -- Create alert
    insert into public.usage_alerts (alert_type, threshold_value, current_value, message)
    values ('threshold_reached', v_limit, v_new_count,
            '일일 사용량 한도(' || v_limit || '회)에 도달했습니다. 서비스가 자동 중단되었습니다.');

    return jsonb_build_object(
      'allowed', false,
      'reason', 'limit_reached',
      'message', '오늘의 서비스 한도에 도달했습니다. 내일 다시 이용해주세요.',
      'current_count', v_new_count,
      'limit', v_limit
    );
  end if;

  -- Check warning threshold (80%)
  if v_new_count = v_warning then
    insert into public.usage_alerts (alert_type, threshold_value, current_value, message)
    values ('threshold_warning', v_warning, v_new_count,
            '일일 사용량이 ' || v_warning || '회에 도달했습니다. 한도(' || v_limit || ')의 80% 입니다.');
  end if;

  return jsonb_build_object(
    'allowed', true,
    'current_count', v_new_count,
    'limit', v_limit,
    'remaining', v_limit - v_new_count
  );
end;
$$;

-- 5) Function to get current usage status (for admin dashboard)
create or replace function public.get_usage_status()
returns jsonb
language plpgsql
security definer
as $$
declare
  v_today date := current_date;
  v_usage record;
  v_settings jsonb;
  v_alerts jsonb;
begin
  -- Get today's usage
  select * into v_usage from public.app_usage where date = v_today;

  -- Get settings
  select value into v_settings from public.app_settings where key = 'usage_limit';

  -- Get recent unread alerts
  select jsonb_agg(
    jsonb_build_object(
      'id', id,
      'type', alert_type,
      'message', message,
      'created_at', created_at
    )
  ) into v_alerts
  from public.usage_alerts
  where is_read = false
  order by created_at desc
  limit 10;

  return jsonb_build_object(
    'date', v_today,
    'total_count', coalesce(v_usage.total_count, 0),
    'saju_count', coalesce(v_usage.saju_count, 0),
    'mbti_count', coalesce(v_usage.mbti_count, 0),
    'compatibility_count', coalesce(v_usage.compatibility_count, 0),
    'consultation_count', coalesce(v_usage.consultation_count, 0),
    'settings', v_settings,
    'alerts', coalesce(v_alerts, '[]'::jsonb)
  );
end;
$$;

-- 6) Function to reset daily pause (call at midnight or manually)
create or replace function public.reset_daily_usage()
returns void
language plpgsql
security definer
as $$
begin
  -- Reset pause status for new day
  update public.app_settings
  set value = value || '{"is_paused": false}'::jsonb,
      updated_at = now()
  where key = 'usage_limit';
end;
$$;

-- 7) RLS policies
alter table public.app_usage enable row level security;
alter table public.usage_alerts enable row level security;
alter table public.app_settings enable row level security;

-- Allow read for authenticated users (for checking limits)
create policy "Allow read app_usage" on public.app_usage
  for select using (true);

create policy "Allow read app_settings" on public.app_settings
  for select using (true);

-- Alerts only for admin (you can modify this based on your auth setup)
create policy "Allow read usage_alerts" on public.usage_alerts
  for select using (true);

-- 8) Index for performance
create index if not exists app_usage_date_idx on public.app_usage (date desc);
create index if not exists usage_alerts_unread_idx on public.usage_alerts (is_read, created_at desc);
