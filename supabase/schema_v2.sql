-- ============================================================
--  先吃掉那隻青蛙 × GTD — schema v2 migration
--  Run in: Supabase Dashboard → SQL Editor → Run
--  Safe to run on top of the v1 schema (idempotent).
-- ============================================================

-- ---- tasks: new columns ----
alter table tasks add column if not exists difficulty text default 'medium';   -- easy | medium | hard
alter table tasks add column if not exists due_date date;
alter table tasks add column if not exists reminder_time text;                  -- 'HH:mm'
alter table tasks add column if not exists subtasks jsonb default '[]'::jsonb;  -- [{id,title,done}]

-- ---- completions: per-completion log (drives stats + streak) ----
create table if not exists completions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  date date not null,
  type text not null,            -- frog | tadpole
  task_id uuid,
  deleted boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists completions_user_date_idx on completions (user_id, date desc);

drop trigger if exists completions_set_updated_at on completions;
create trigger completions_set_updated_at
  before update on completions
  for each row execute function set_updated_at();

alter table completions enable row level security;
drop policy if exists "users own completions" on completions;
create policy "users own completions"
  on completions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---- daily_records is no longer used by the app (streak now comes from
--      completions). You may keep it or drop it:
-- drop table if exists daily_records;
