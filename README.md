# St George College - Production-ready frontend + Supabase

This package builds on the connected/first-login version.

## Included
- Supabase authentication and role-based routing
- First-login temporary password flow
- Learner, Staff, SRC and Administrator roles
- Admin account management through the deployed `manage-user` Edge Function
- Database-backed announcements with Everyone / Learners / Staff audience controls
- Database-backed calendar with audience controls
- Public, database-backed academic achievements
- Admin CRUD for academic achievements
- Database-backed school settings shown on the public website
- Stronger RLS policies for announcement/calendar audience visibility
- Responsive mobile/desktop polish

## One final Supabase step
Run `supabase-final-upgrade.sql` once in Supabase SQL Editor. This adds calendar audiences and enforces announcement/calendar visibility at the database level.

## Existing Edge Function
The `manage-user` Edge Function is already deployed in the Supabase project. If you replace its code later, deploy it from the folder containing `supabase/functions/manage-user/index.ts`.

## Frontend config
`assets/supabase-config.js` contains only the browser-safe project URL and publishable key. Never put a service-role/secret key in frontend code.

## Testing checklist
1. Admin logs in.
2. Admin creates a learner and a staff account.
3. Each uses the temporary password and completes first-login password change.
4. Admin creates a Learners-only announcement; learner sees it, staff does not.
5. Admin creates a Staff-only announcement; staff sees it, learner does not.
6. Admin creates a Staff-only calendar event; staff sees it, learner does not.
7. Admin edits an academic achievement; the public homepage updates.
8. Admin edits school settings; the public contact section updates.
