# Project Status: what it does, how, and what's missing

Last updated: 24 Nov 2026

## 1. What the app is
A local-services marketplace for Pakistan (PKR, Lahore default). One account can act as **Client** (posts jobs) or **Provider** (bids on jobs).

Flow: `ServiceRequest -> Bid -> Booking -> Review`

## 2. Tech stack
| Layer | Tech |
|---|---|
| Mobile app | Flutter (Dart), Material 3 |
| State management | Riverpod |
| Navigation | go_router (with login redirect) |
| Backend | Supabase (Postgres database, Auth, Storage, Realtime) |
| Business rules | Postgres functions (RPC) + Row Level Security, in `backend/supabase/schema.sql` |

No other APIs are used.

## 3. How it works (architecture)
```
Screens (features/)  ->  Providers/Services (services/)  ->  Supabase (online)
```
- `lib/src/core/`: constants (Supabase URL/key), theme, router, form validators
- `lib/src/models/`: Dart classes for the 7 tables + enums
- `lib/src/services/`: `AuthService`, repositories (requests, bids, bookings, chat, reviews), Riverpod providers
- `lib/src/features/`: `auth`, `client`, `provider`, `chat`, `profile`, `shared`, `shell`

Key design choices:
- **Atomic actions are database functions**: `accept_bid`, `mark_work_done`, `complete_booking`, `cancel_booking`, `submit_review`. The app can't leave data half-updated.
- **Address privacy**: the street address is in a separate table (`request_addresses`); only the client and the provider who got booked can read it (enforced by RLS, not just the UI).
- **Sign-up** puts name/phone/city in auth metadata; a DB trigger creates the `app_users` row.
- **Chat** uses Supabase Realtime streams.

## 4. Features: built
**Auth & profile**: register, login, logout, switch Client/Provider mode, one-time provider onboarding, provider stats + availability switch + received reviews.
**Client**: category home, post request (validated form, up to 3 photos), My Requests (Open / Booked / Done-Cancelled), request detail with bids (rating, jobs done), Accept Bid, cancel request.
**Provider**: Explore feed (newest first, category + city filter, hides own requests), request detail (address hidden), submit / edit / withdraw bid, My Bids with statuses.
**Both**: Bookings list (Active / Past), booking detail with role-based buttons (Mark Work Done, Confirm & Complete, Cancel), real-time chat (read-only after close), review dialog with stars + comment.

## 5. Verified vs not yet verified (be honest in your report)
- **Verified by running:** app starts, connects to Supabase, sign-up, login, Home screen renders in Chrome.
- **Written but NOT yet tested end to end:** posting requests, bidding, accepting, bookings, chat, reviews, provider onboarding. Run the test script in `mobile/README.md` with two accounts and fix what breaks.
- **Unit tests** (`mobile/test/`) were written but never run. They import `package:service_platform/...`; this only works if `pubspec.yaml` has `name: service_platform`.

## 6. What's missing / known limitations
**Not built**
- Edit profile (name, phone, photo/avatar), change password, forgot password
- Push notifications (users must open the app to see new bids/messages)
- Full-screen photo viewer; provider public profile page for clients
- Search by keyword, pagination (lists load everything)
- Admin / reporting / dispute handling, payments (cash assumed)
- Email verification (turned off for development)

**Technical issues**
- **Photo upload doesn't work in Chrome** (uses `dart:io`). Needs a phone/emulator, or switch to `XFile.readAsBytes` + `uploadBinary` for web support.
- **Android build** failed earlier on this PC with an NDK 28.2 / Gradle issue (environment, not app code). Chrome works. For phone: install NDK 28.2.13676358 via SDK Manager, or fix `ndkVersion` in `android/app/build.gradle.kts`.
- Provider "unavailable" switch is checked only in the app, not enforced in the database.
- Request detail shows plain error text in a couple of places (no retry button).
- Lists refresh by pull-down; only chat is live.
- Supabase free projects **pause after ~1 week idle** (click "Restore project" in the dashboard).

## 7. Setup checklist for a new machine
1. Supabase project: tick "Grant API access to new tables automatically"; run `backend/supabase/schema.sql` once; Authentication > Providers > Email > turn **Confirm email** off.
2. Put Project URL + publishable key in `mobile/lib/src/core/constants.dart` (or pass `--dart-define`).
3. `cd mobile && flutter create . --platforms=android,web && flutter pub get && flutter run -d chrome`
4. Test with two accounts: see `mobile/README.md`.

## 8. Suggested next steps (priority)
1. Run the full two-account test and fix bugs.
2. Make photo upload web-safe or test on phone.
3. Add edit profile + forgot password.
4. Take screenshots, update the report/proposal to match what's built.
5. Optional: notifications, search, pagination.
