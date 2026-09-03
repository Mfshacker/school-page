-- ST GEORGE COLLEGE - FINAL SECURITY + CONTENT UPGRADE
-- Run once in Supabase Dashboard -> SQL Editor.
-- Safe to re-run: policies/columns are recreated safely.

alter table public.calendar_events add column if not exists audience text not null default 'all';

do $$ begin
  if not exists (select 1 from pg_constraint where conname='calendar_events_audience_check') then
    alter table public.calendar_events add constraint calendar_events_audience_check check (audience in ('all','learners','staff'));
  end if;
end $$;

create or replace function public.current_role()
returns text language sql stable security definer set search_path=public
as $$ select role from public.profiles where id=auth.uid() limit 1; $$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path=public
as $$ select public.current_role()='admin'; $$;

-- Profiles: authenticated members may read the directory; only admins can write.
alter table public.profiles enable row level security;
drop policy if exists "profiles authenticated read" on public.profiles;
create policy "profiles authenticated read" on public.profiles for select to authenticated using (true);
drop policy if exists "profiles admin write" on public.profiles;
create policy "profiles admin write" on public.profiles for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Announcements: database now enforces audience visibility, not just the frontend.
alter table public.announcements enable row level security;
drop policy if exists "announcements authenticated read" on public.announcements;
drop policy if exists "announcements audience read" on public.announcements;
create policy "announcements audience read" on public.announcements for select to authenticated using (
  public.is_admin() or audience='all' or
  (audience='learners' and public.current_role() in ('learner','SRC')) or
  (audience='staff' and public.current_role()='staff')
);
drop policy if exists "announcements admin write" on public.announcements;
create policy "announcements admin write" on public.announcements for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Calendar: database enforces audience visibility.
alter table public.calendar_events enable row level security;
drop policy if exists "calendar authenticated read" on public.calendar_events;
drop policy if exists "calendar audience read" on public.calendar_events;
create policy "calendar audience read" on public.calendar_events for select to authenticated using (
  public.is_admin() or audience='all' or
  (audience='learners' and public.current_role() in ('learner','SRC')) or
  (audience='staff' and public.current_role()='staff')
);
drop policy if exists "calendar admin write" on public.calendar_events;
create policy "calendar admin write" on public.calendar_events for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Public achievements/settings; only admins can change them.
alter table public.academic_achievements enable row level security;
drop policy if exists "achievements public read" on public.academic_achievements;
create policy "achievements public read" on public.academic_achievements for select to anon,authenticated using (true);
drop policy if exists "achievements admin write" on public.academic_achievements;
create policy "achievements admin write" on public.academic_achievements for all to authenticated using (public.is_admin()) with check (public.is_admin());

alter table public.school_settings enable row level security;
drop policy if exists "settings public read" on public.school_settings;
create policy "settings public read" on public.school_settings for select to anon,authenticated using (true);
drop policy if exists "settings admin write" on public.school_settings;
create policy "settings admin write" on public.school_settings for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Backfill the existing calendar rows as public/all.
update public.calendar_events set audience='all' where audience is null;

-- Ensure the default achievements exist if the table is empty.
insert into public.academic_achievements (title,value,description,year,sort_order)
select * from (values
 ('Circuit position','TOP 1','Replace with the official circuit result.',2026,1),
 ('Geography','BEST SCHOOL','Replace with the official 2026 achievement.',2026,2),
 ('Pass rate','98%','Replace with the verified official pass rate.',2026,3),
 ('Matric results','#1','Replace with the verified official ranking.',2026,4)
) as v(title,value,description,year,sort_order)
where not exists (select 1 from public.academic_achievements);

insert into public.school_settings (id,school_name) values (1,'St George College') on conflict (id) do nothing;
