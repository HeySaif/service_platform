# Mobile Application (Flutter)

Flutter client (Android & iOS) backed by Supabase. Set up the database first: see `../backend/README.md`.

## First run

```bash
cd mobile
flutter create . --platforms=android,ios   # generates android/ and ios/ (keeps lib/ and pubspec.yaml)
flutter pub get
flutter analyze && flutter test
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

### Platform setup for photos
- **iOS** (`ios/Runner/Info.plist`): add `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription`.
- **Android**: the gallery works out of the box; for camera capture see the `image_picker` docs.

## Architecture

```
lib/src/
  core/       theme, router (go_router + auth redirect), validators, constants
  models/     enums + 7 domain models (fromJson)
  services/   AuthService, repositories (requests, bids, bookings, chat, reviews), Riverpod providers
  features/   auth, client, provider, chat (bookings), profile, shared widgets
```

State management: Riverpod. All multi-step transitions (accept bid, mark done, complete, cancel, review) are Postgres RPCs, so the app cannot leave data half-updated.

## Status

- [x] Phase 2: scaffold, theme, router, models, service layer, auth, role switch, provider onboarding
- [x] Phase 3: Client home, Post Request form (photo upload), My Requests, bid comparison + Accept Bid
- [x] Phase 4: Provider feed with filters, bid submit/edit/withdraw, My Bids
- [x] Phase 5: Bookings list, booking detail + status actions, realtime chat, review dialog
- [x] Phase 6: Provider profile (stats, availability, reviews), error views, unit tests, test script below
- [ ] Not built: profile editing, push notifications, in-app photo viewer

## End-to-end test script (two accounts)

Use two devices/emulators (or two browsers' worth of sessions), Account A = client, Account B = provider.

1. **A** registers, taps a category, posts a request with a photo. It appears under My Requests → Open.
2. **B** registers, Profile → Switch to Provider Mode, completes onboarding. Explore shows A's request (city + category filters work).
3. **B** opens it, confirms the address is hidden, submits a bid. My Bids shows it as PENDING. Edit the price, then check A sees the update.
4. **A** pulls to refresh on the request, sees B's bid (rating, jobs done), taps Accept Bid. Lands on the booking, request is BOOKED, B's bid is ACCEPTED.
5. **B** opens Bookings → the booking: address now visible. Chat both ways works live.
6. **B** taps Mark Work Done. **A** taps Confirm & Complete, leaves 5 stars.
7. **B**'s Profile shows rating 5.0, 1 job done, and the review.
8. Negative checks: A can't bid on own request (switch A to provider mode); B can't bid after the request is booked; withdrawing a bid lets B bid again; turning availability off blocks new bids.
