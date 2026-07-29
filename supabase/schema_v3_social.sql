-- ============================================================
--  先吃掉那隻青蛙 × GTD — schema v3 (social / multiplayer)  [robust]
--  Run in: Supabase Dashboard → SQL Editor → Run
--  No trigger on auth.users (the app creates the profile on login).
-- ============================================================

-- ---------- profiles ----------
create table if not exists profiles (
  id uuid primary key references auth.users on delete cascade,
  display_name text,
  avatar_color text default '#B5502E',
  streak int default 0,
  frogs_eaten int default 0,
  focus_task text,
  focus_started_at timestamptz,
  updated_at timestamptz default now()
);
alter table profiles enable row level security;
drop policy if exists "profiles read" on profiles;
drop policy if exists "profiles insert self" on profiles;
drop policy if exists "profiles update self" on profiles;
create policy "profiles read"        on profiles for select to authenticated using (true);
create policy "profiles insert self" on profiles for insert to authenticated with check (auth.uid() = id);
create policy "profiles update self" on profiles for update to authenticated using (auth.uid() = id);

-- ---------- friendships ----------
create table if not exists friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid references auth.users on delete cascade not null,
  addressee_id uuid references auth.users on delete cascade not null,
  status text default 'pending',
  created_at timestamptz default now(),
  unique (requester_id, addressee_id)
);
create index if not exists friendships_addressee_idx on friendships (addressee_id);
alter table friendships enable row level security;
drop policy if exists "friendship read" on friendships;
drop policy if exists "friendship insert" on friendships;
drop policy if exists "friendship update" on friendships;
create policy "friendship read"   on friendships for select to authenticated using (auth.uid() = requester_id or auth.uid() = addressee_id);
create policy "friendship insert" on friendships for insert to authenticated with check (auth.uid() = requester_id);
create policy "friendship update" on friendships for update to authenticated using (auth.uid() = requester_id or auth.uid() = addressee_id);

-- ---------- communities ----------
create table if not exists communities (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_by uuid references auth.users on delete set null,
  created_at timestamptz default now()
);
create table if not exists community_members (
  community_id uuid references communities on delete cascade not null,
  user_id uuid references auth.users on delete cascade not null,
  joined_at timestamptz default now(),
  primary key (community_id, user_id)
);
alter table communities enable row level security;
alter table community_members enable row level security;

create or replace function is_member(cid uuid, uid uuid)
returns boolean language sql security definer stable set search_path = public as $$
  select exists (select 1 from community_members where community_id = cid and user_id = uid);
$$;

drop policy if exists "community read" on communities;
drop policy if exists "community create" on communities;
create policy "community read"   on communities for select to authenticated using (is_member(id, auth.uid()));
create policy "community create" on communities for insert to authenticated with check (auth.uid() = created_by);

drop policy if exists "members read" on community_members;
drop policy if exists "members join" on community_members;
create policy "members read" on community_members for select to authenticated using (is_member(community_id, auth.uid()));
create policy "members join" on community_members for insert to authenticated with check (auth.uid() = user_id);

-- ---------- messages ----------
create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  community_id uuid references communities on delete cascade not null,
  user_id uuid references auth.users on delete cascade not null,
  text text not null,
  created_at timestamptz default now()
);
create index if not exists messages_community_idx on messages (community_id, created_at);
alter table messages enable row level security;
drop policy if exists "messages read" on messages;
drop policy if exists "messages send" on messages;
create policy "messages read" on messages for select to authenticated using (is_member(community_id, auth.uid()));
create policy "messages send" on messages for insert to authenticated with check (auth.uid() = user_id and is_member(community_id, auth.uid()));

-- ---------- realtime (safe: ignore if already added) ----------
do $$ begin
  alter publication supabase_realtime add table messages;
exception when duplicate_object then null; when others then null; end $$;
do $$ begin
  alter publication supabase_realtime add table profiles;
exception when duplicate_object then null; when others then null; end $$;
