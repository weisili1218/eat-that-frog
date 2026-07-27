-- ============================================================
--  先吃掉那隻青蛙 × GTD — Supabase schema
--  Paste into: Supabase Dashboard → SQL Editor → Run
-- ============================================================

-- ---------- tasks ----------
create table if not exists tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  title text not null,
  note text,
  is_frog boolean default false,
  ever_frog boolean default false,
  bucket text default 'inbox',          -- inbox | today | later | someday
  completed_at timestamptz,
  deleted boolean default false,        -- soft delete, for offline sync
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ---------- daily_records ----------
create table if not exists daily_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  date date not null,
  frog_completed boolean default false,
  total_completed int default 0,
  current_streak int default 0,
  updated_at timestamptz default now(),
  unique (user_id, date)
);

-- ---------- indexes ----------
create index if not exists tasks_user_updated_idx on tasks (user_id, updated_at desc);
create index if not exists records_user_date_idx  on daily_records (user_id, date desc);

-- ---------- auto-update updated_at (supports Last-Write-Wins sync) ----------
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists tasks_set_updated_at on tasks;
create trigger tasks_set_updated_at
  before update on tasks
  for each row execute function set_updated_at();

drop trigger if exists records_set_updated_at on daily_records;
create trigger records_set_updated_at
  before update on daily_records
  for each row execute function set_updated_at();

-- ---------- Row Level Security ----------
alter table tasks         enable row level security;
alter table daily_records enable row level security;

drop policy if exists "users own tasks"   on tasks;
drop policy if exists "users own records"  on daily_records;

create policy "users own tasks"
  on tasks for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "users own records"
  on daily_records for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
