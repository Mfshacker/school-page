# XOLII DAILY BETS — Member website + Supabase

This package has been converted from the original school website into a personal betting-content website.

## Membership model
- **Free Member** = existing database role `learner`
- **Premium Member** = existing database role `staff`
- **Administrator** = existing database role `admin`

The underlying role values remain unchanged so the existing Supabase authentication and RLS policies continue to work.

## Website sections
- Public XOLII DAILY BETS landing page
- Free Member Area for daily/free picks and updates
- Premium Hub for members-only picks and analysis
- Administrator Control Centre for managing members, updates, fixtures, picks and settings
- First-login password change flow
- Responsive mobile/desktop layout
- Custom XOLII DAILY BETS logo and favicon

## Supabase
Run `supabase-final-upgrade.sql` once in the Supabase SQL Editor if you want the existing database content and branding converted too.

The frontend only uses the browser-safe Supabase URL and publishable key in `assets/supabase-config.js`. Never place a service-role/secret key in frontend code.

## Content management
The old school "announcements", "calendar events" and "academic achievements" tables are intentionally reused as:
- Betting updates
- Fixtures / betting schedule
- Featured picks & results

No database table rename is required.

## Important
Betting picks are informational/entertainment content. No outcome is guaranteed. Add your own responsible-betting, age and legal notices appropriate to the jurisdictions you serve.

## Main files
- `index.html` — public XOLII DAILY BETS website
- `login.html` — Free / Premium / Admin login
- `portal.html` — Free Member Area
- `staff.html` — Premium Hub
- `admin.html` — Administrator Control Centre
- `assets/app.js` — authentication, member routing and content rendering
- `assets/style.css` — site styling
- `supabase-final-upgrade.sql` — database conversion/security upgrade
