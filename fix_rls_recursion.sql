-- Fix RLS recursion: stack depth limit exceeded
-- Problem: is_member() checks household_users, which triggers RLS again -> infinite loop

-- Drop problematic functions
drop function if exists public.is_member(uuid);
drop function if exists public.is_owner(uuid);

-- Drop all existing policies
drop policy if exists households_select on public.households;
drop policy if exists households_update_owner on public.households;
drop policy if exists users_select on public.household_users;
drop policy if exists users_insert_self on public.household_users;
drop policy if exists users_update_self_or_owner on public.household_users;
drop policy if exists log_select on public.activity_log;
drop policy if exists log_insert on public.activity_log;

-- Simplified RLS: use auth.uid() directly without recursive lookups
-- Note: This assumes auth.uid() returns household_users.id (from JWT)

-- Households: user can see households where they are a member
create policy households_select
on public.households for select
using (
  id in (
    select household_id 
    from public.household_users 
    where id = auth.uid()
  )
);

-- Households: owner can update
create policy households_update_owner
on public.households for update
using (
  owner_id = auth.uid()
);

-- Household users: users can see members of their household(s)
create policy users_select
on public.household_users for select
using (
  household_id in (
    select household_id 
    from public.household_users 
    where id = auth.uid()
  )
);

-- Household users: can insert if owner or existing member
create policy users_insert
on public.household_users for insert
with check (
  role = 'owner' 
  or household_id in (
    select household_id 
    from public.household_users 
    where id = auth.uid()
  )
);

-- Household users: can update self or if owner
create policy users_update
on public.household_users for update
using (
  id = auth.uid()
  or (
    household_id in (
      select h.id 
      from public.households h
      where h.owner_id = auth.uid()
    )
  )
);

-- Activity log: users can see logs from their household(s)
create policy log_select
on public.activity_log for select
using (
  household_id in (
    select household_id 
    from public.household_users 
    where id = auth.uid()
  )
);

-- Activity log: users can insert logs for their household(s)
create policy log_insert
on public.activity_log for insert
with check (
  household_id in (
    select household_id 
    from public.household_users 
    where id = auth.uid()
  )
);
