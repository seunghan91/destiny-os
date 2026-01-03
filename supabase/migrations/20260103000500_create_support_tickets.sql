create extension if not exists pgcrypto;

create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  user_id uuid null,
  firebase_uid text null,
  title text not null,
  contact text not null,
  message text not null,
  status text not null default 'open',
  admin_note text null,
  resolved_at timestamptz null
);

do $$
begin
  if to_regclass('public.user_profiles') is not null then
    alter table public.support_tickets
      add constraint support_tickets_user_id_fkey
      foreign key (user_id) references public.user_profiles(id)
      on delete set null;
  end if;
exception
  when duplicate_object then
    null;
end $$;

alter table public.support_tickets enable row level security;

create policy "Enable read access for all users" on public.support_tickets
  for select using (true);

create policy "Enable insert access for all users" on public.support_tickets
  for insert with check (true);

create index if not exists support_tickets_created_at_idx
  on public.support_tickets (created_at desc);

create index if not exists support_tickets_status_created_at_idx
  on public.support_tickets (status, created_at desc);
