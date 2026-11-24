# Backend (Supabase)

1. Create a project at supabase.com.
2. SQL Editor → paste and run `supabase/schema.sql`.
3. Authentication → Providers → enable Email (turn off "Confirm email" while developing).
4. Copy Project URL and anon key into the Flutter app:
   `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

All multi-step state changes (accept bid, mark work done, complete, cancel, review) are Postgres RPCs, so they are atomic and enforced server-side.
