-- ============================================================
--  v3b: allow a community creator to add other members
--  (the create-group member picker). Run after schema_v3_social.sql.
-- ============================================================
drop policy if exists "members add by creator" on community_members;
create policy "members add by creator"
  on community_members for insert to authenticated
  with check (
    auth.uid() = (select created_by from communities where id = community_id)
  );
