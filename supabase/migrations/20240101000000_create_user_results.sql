create table if not exists public.user_results (
  id uuid default gen_random_uuid() primary key,
  created_at timestamptz default now(),
  name text,
  birth_date timestamp with time zone not null,
  birth_hour int,
  gender text not null,
  is_lunar boolean default false,
  mbti text not null
);

alter table public.user_results enable row level security;

create policy "Enable read access for all users" on public.user_results
  for select using (true);

create policy "Enable insert access for all users" on public.user_results
  for insert with check (true);
