create table if not exists public.fortune_year_results (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),

  -- cache key to ensure identical input yields identical result
  fingerprint text not null,

  year int not null,

  -- generator metadata (A: template, B: ai)
  generator text not null default 'template',
  generator_version text not null default 'v1',

  -- input snapshot (optional, for debugging/auditing)
  input jsonb,

  -- narrative output
  overall text not null,
  best text not null,
  caution text not null,
  advice text not null,

  constraint fortune_year_results_year_range check (year >= 1900 and year <= 2200),
  constraint fortune_year_results_generator_allowed check (generator in ('template', 'ai'))
);

create unique index if not exists fortune_year_results_fingerprint_year_unique
  on public.fortune_year_results (fingerprint, year);

alter table public.fortune_year_results enable row level security;

create policy "Enable read access for all users" on public.fortune_year_results
  for select using (true);

create policy "Enable insert access for all users" on public.fortune_year_results
  for insert with check (true);
