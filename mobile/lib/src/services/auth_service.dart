import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

class AuthService {
  AuthService(this._db);
  final SupabaseClient _db;

  Future<void> signIn(String email, String password) =>
      _db.auth.signInWithPassword(email: email.trim(), password: password);

  /// full_name / phone / city go into user metadata; a DB trigger creates the app_users row.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String city,
  }) =>
      _db.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim(), 'phone': phone.trim(), 'city': city.trim()},
      );

  Future<void> signOut() => _db.auth.signOut();

  Future<AppUser> fetchUser(String id) async =>
      AppUser.fromJson(await _db.from('app_users').select().eq('id', id).single());

  Future<void> setActiveRole(String userId, UserRole role) =>
      _db.from('app_users').update({'active_role': role.db}).eq('id', userId);

  /// One-time provider setup (FR-1.2): creates ProviderProfile, flags user onboarded and switches mode.
  Future<void> completeProviderOnboarding(ProviderProfile profile) async {
    await _db.from('provider_profiles').insert(profile.toInsert());
    await _db
        .from('app_users')
        .update({'is_provider_onboarded': true, 'active_role': UserRole.provider.db})
        .eq('id', profile.userId);
  }

  Future<void> setAvailability(String userId, bool available) =>
      _db.from('provider_profiles').update({'is_available': available}).eq('user_id', userId);

  Future<ProviderProfile?> fetchProviderProfile(String userId) async {
    final row = await _db.from('provider_profiles').select().eq('user_id', userId).maybeSingle();
    return row == null ? null : ProviderProfile.fromJson(row);
  }
}
