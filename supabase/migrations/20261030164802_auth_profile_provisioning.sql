-- Keep public farmer profiles synchronized with Supabase Auth users.
-- This trigger runs inside the auth.users insert transaction, including signups
-- where email confirmation is required and the client has no session yet.

create or replace function public.handle_new_auth_user_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  insert into public.profiles (id, name, email)
  values (
    new.id,
    coalesce(
      nullif(btrim(new.raw_user_meta_data ->> 'name'), ''),
      nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''),
      'Farmer'
    ),
    new.email
  )
  on conflict (id) do update
    set email = excluded.email
    where public.profiles.email is distinct from excluded.email;

  return new;
end;
$function$;

-- The function is only invoked by its trigger, never as a client-callable RPC.
revoke all on function public.handle_new_auth_user_profile() from public;
revoke all on function public.handle_new_auth_user_profile() from anon;
revoke all on function public.handle_new_auth_user_profile() from authenticated;

drop trigger if exists on_auth_user_created_profile on auth.users;

create trigger on_auth_user_created_profile
after insert on auth.users
for each row
execute function public.handle_new_auth_user_profile();

-- Backfill only genuinely missing profiles; existing farmer profile details
-- are preserved untouched.
insert into public.profiles (id, name, email)
select
  u.id,
  coalesce(
    nullif(btrim(u.raw_user_meta_data ->> 'name'), ''),
    nullif(btrim(u.raw_user_meta_data ->> 'full_name'), ''),
    'Farmer'
  ),
  u.email
from auth.users u
on conflict (id) do nothing;
