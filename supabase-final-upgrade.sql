-- XOLII DAILY BETS - FINAL SECURITY + CONTENT UPGRADE
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
 ('Featured Free Pick','DAILY','A rotating free selection posted by Xolii.',2026,1),
 ('Premium Pick','VIP','Members-only selection available in the Premium Hub.',2026,2),
 ('Analysis','XDB','Follow the reasoning and notes attached to featured picks.',2026,3),
 ('Reminder','18+','Bet responsibly and only where legal. No outcome is guaranteed.',2026,4)
) as v(title,value,description,year,sort_order)
where not exists (select 1 from public.academic_achievements);

insert into public.school_settings (id,school_name) values (1,'XOLII DAILY BETS') on conflict (id) do nothing;


-- Convert the singleton branding to Xolii. Phone/address are intentionally left blank.
update public.school_settings
set school_name='XOLII DAILY BETS',
    phone='',
    email='',
    address='',
    updated_at=now()
where id=1;

-- Convert the original school seed content if it is still present.
update public.announcements set title='Today''s Featured Free Pick', category='Free Pick',
  audience='learners', text='Check the dashboard for today''s featured free selection and the key factors behind it.'
  where title='Parent information evening';
update public.announcements set title='Premium Picks Are Live', category='Premium Pick',
  audience='staff', text='Premium members can now view the latest members-only selections and analysis in the Premium Hub.'
  where title='Term assessment timetable';
update public.announcements set title='Responsible Betting Reminder', category='General',
  audience='all', text='Bet responsibly. Picks are for information and entertainment, and no outcome is guaranteed.'
  where title='Inter-school athletics';


update public.calendar_events set title='Daily Picks Drop', type='event' where title='Parent information evening';
update public.calendar_events set title='Midweek Fixtures', type='event' where title='Inter-school athletics';
update public.calendar_events set title='Weekend Picks', type='event' where title='Heritage Day';
update public.calendar_events set title='Premium Review', type='event', audience='staff' where title='Spring cultural festival';
update public.calendar_events set title='Results & Performance Update', type='event', audience='all' where title='Term assessment begins';
delete from public.calendar_events where title in ('School holiday');

update public.academic_achievements set title='Featured Free Pick', value='DAILY',
  description='A rotating free selection posted by Xolii.' where title='Circuit position';
update public.academic_achievements set title='Premium Pick', value='VIP',
  description='Members-only selection available in the Premium Hub.' where title='Geography';
update public.academic_achievements set title='Analysis', value='XDB',
  description='Follow the reasoning and notes attached to featured picks.' where title='Pass rate';
update public.academic_achievements set title='Reminder', value='18+',
  description='Bet responsibly and only where legal. No outcome is guaranteed.' where title='Matric results';
