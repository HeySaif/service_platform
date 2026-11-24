import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'auth_service.dart';
import 'repositories.dart';

final supabaseProvider = Provider<SupabaseClient>((_) => Supabase.instance.client);

final authServiceProvider = Provider((ref) => AuthService(ref.watch(supabaseProvider)));
final requestRepoProvider = Provider((ref) => RequestRepository(ref.watch(supabaseProvider)));
final bidRepoProvider = Provider((ref) => BidRepository(ref.watch(supabaseProvider)));
final bookingRepoProvider = Provider((ref) => BookingRepository(ref.watch(supabaseProvider)));
final chatRepoProvider = Provider((ref) => ChatRepository(ref.watch(supabaseProvider)));
final reviewRepoProvider = Provider((ref) => ReviewRepository(ref.watch(supabaseProvider)));

/// Emits whenever the Supabase session changes (sign in / out).
final sessionProvider = StreamProvider<Session?>((ref) async* {
  final auth = ref.watch(supabaseProvider).auth;
  yield auth.currentSession;
  yield* auth.onAuthStateChange.map((e) => e.session);
});

/// The signed-in user's AppUser row (null when signed out).
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final session = ref.watch(sessionProvider).value;
  if (session == null) return null;
  return ref.watch(authServiceProvider).fetchUser(session.user.id);
});
