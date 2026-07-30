-- ============================================================
--  v4: task duration + profile avatar photo + chat reactions
--  Run in Supabase SQL Editor.
-- ============================================================
alter table tasks    add column if not exists duration_minutes int;
alter table profiles add column if not exists avatar_url text;

-- reactions: {emoji: [user_id, ...]}
alter table messages add column if not exists reactions jsonb default '{}'::jsonb;

-- allow group members to update a message (used for reactions)
drop policy if exists "messages update by members" on messages;
create policy "messages update by members"
  on messages for update to authenticated
  using (is_member(community_id, auth.uid()));
