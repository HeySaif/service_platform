import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import '../models/models.dart';

class RequestRepository {
  RequestRepository(this._db);
  final SupabaseClient _db;

  /// Uploads photos to `request-photos/<uid>/...` and returns public URLs.
  Future<List<String>> uploadPhotos(String userId, List<File> files) async {
    final urls = <String>[];
    for (final f in files.take(AppConfig.maxPhotos)) {
      final path = '$userId/${DateTime.now().microsecondsSinceEpoch}_${urls.length}.jpg';
      await _db.storage.from(AppConfig.photoBucket).upload(path, f);
      urls.add(_db.storage.from(AppConfig.photoBucket).getPublicUrl(path));
    }
    return urls;
  }

  Future<ServiceRequest> create({
    required AppUser client,
    required String title,
    required ServiceCategory category,
    required String description,
    required String city,
    required String areaName,
    required String addressDetails,
    double? budgetPkr,
    List<String> photoUrls = const [],
  }) async {
    final row = await _db.from('service_requests').insert({
      'client_id': client.id,
      'client_name': client.fullName,
      'title': title.trim(),
      'category': category.db,
      'description': description.trim(),
      'city': city.trim(),
      'area_name': areaName.trim(),
      'budget_pkr': budgetPkr,
      'photo_urls': photoUrls,
    }).select().single();
    await _db.from('request_addresses').insert({
      'request_id': row['id'],
      'address_details': addressDetails.trim(),
    });
    return ServiceRequest.fromJson(row);
  }

  Future<List<ServiceRequest>> myRequests(String clientId) async =>
      (await _db.from('service_requests').select().eq('client_id', clientId).order('created_at', ascending: false))
          .map(ServiceRequest.fromJson)
          .toList();

  /// Provider feed: OPEN, newest first, excluding own requests (FR-3.1 / Flow P2).
  Future<List<ServiceRequest>> openFeed({
    required String providerId,
    ServiceCategory? category,
    String? city,
  }) async {
    var q = _db.from('service_requests').select().eq('status', 'OPEN').neq('client_id', providerId);
    if (category != null) q = q.eq('category', category.db);
    if (city != null && city.isNotEmpty) q = q.ilike('city', city);
    return (await q.order('created_at', ascending: false)).map(ServiceRequest.fromJson).toList();
  }

  Future<ServiceRequest> getById(String id) async =>
      ServiceRequest.fromJson(await _db.from('service_requests').select().eq('id', id).single());

  /// Requests the caller can see (RLS hides ones booked to someone else).
  Future<Map<String, ServiceRequest>> byIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final rows = await _db.from('service_requests').select().inFilter('id', ids);
    return {for (final r in rows) r['id'] as String: ServiceRequest.fromJson(r)};
  }

  Future<void> cancelOpen(String requestId) =>
      _db.from('service_requests').update({'status': 'CANCELLED'}).eq('id', requestId);

  /// Only returns a value for the client, or the provider after booking (enforced by RLS).
  Future<String?> addressFor(String requestId) async =>
      (await _db.from('request_addresses').select().eq('request_id', requestId).maybeSingle())?['address_details'];
}

class BidRepository {
  BidRepository(this._db);
  final SupabaseClient _db;

  Future<void> submit({required String requestId, required String providerId, required double price, required String message}) =>
      _db.from('bids').insert({
        'request_id': requestId,
        'provider_id': providerId,
        'provider_name': '', // overwritten by DB trigger
        'proposed_price': price,
        'message': message.trim(),
      });

  Future<void> update(String bidId, {required double price, required String message}) =>
      _db.from('bids').update({'proposed_price': price, 'message': message.trim()}).eq('id', bidId);

  Future<void> withdraw(String bidId) => _db.from('bids').update({'status': 'WITHDRAWN'}).eq('id', bidId);

  Future<List<Bid>> forRequest(String requestId) async =>
      (await _db.from('bids').select().eq('request_id', requestId).eq('status', 'PENDING').order('proposed_price'))
          .map(Bid.fromJson)
          .toList();

  Future<List<Bid>> mine(String providerId) async =>
      (await _db.from('bids').select().eq('provider_id', providerId).order('created_at', ascending: false))
          .map(Bid.fromJson)
          .toList();

  /// Provider profiles for a set of bids (rating + completed count shown to the client, FR-4.1).
  Future<Map<String, ProviderProfile>> profilesFor(List<String> providerIds) async {
    if (providerIds.isEmpty) return {};
    final rows = await _db.from('provider_profiles').select().inFilter('user_id', providerIds);
    return {for (final r in rows) r['user_id'] as String: ProviderProfile.fromJson(r)};
  }

  /// Atomic: accepts bid, rejects others, books the request, creates the Booking. Returns booking id.
  Future<String> accept(String bidId) async =>
      (await _db.rpc('accept_bid', params: {'p_bid_id': bidId})) as String;
}

class BookingRepository {
  BookingRepository(this._db);
  final SupabaseClient _db;

  Future<List<Booking>> forUser(String userId) async =>
      (await _db.from('bookings').select().or('client_id.eq.$userId,provider_id.eq.$userId').order('created_at', ascending: false))
          .map(Booking.fromJson)
          .toList();

  Future<Booking> get(String id) async => Booking.fromJson(await _db.from('bookings').select().eq('id', id).single());

  Future<void> markWorkDone(String id) => _db.rpc('mark_work_done', params: {'p_booking_id': id});
  Future<void> complete(String id) => _db.rpc('complete_booking', params: {'p_booking_id': id});
  Future<void> cancel(String id) => _db.rpc('cancel_booking', params: {'p_booking_id': id});
}

class ChatRepository {
  ChatRepository(this._db);
  final SupabaseClient _db;

  Stream<List<ChatMessage>> watch(String bookingId) => _db
      .from('chat_messages')
      .stream(primaryKey: ['id'])
      .eq('booking_id', bookingId)
      .order('created_at')
      .map((rows) => rows.map(ChatMessage.fromJson).toList());

  Future<void> send({required String bookingId, required AppUser sender, required String text}) =>
      _db.from('chat_messages').insert({
        'booking_id': bookingId,
        'sender_id': sender.id,
        'sender_name': sender.fullName,
        'text': text.trim(),
      });
}

class ReviewRepository {
  ReviewRepository(this._db);
  final SupabaseClient _db;

  Future<void> submit({required String bookingId, required int rating, String? comment}) =>
      _db.rpc('submit_review', params: {'p_booking_id': bookingId, 'p_rating': rating, 'p_comment': comment ?? ''});

  Future<Review?> forBooking(String bookingId) async {
    final row = await _db.from('reviews').select().eq('booking_id', bookingId).maybeSingle();
    return row == null ? null : Review.fromJson(row);
  }

  Future<List<Review>> forProvider(String providerId) async =>
      (await _db.from('reviews').select().eq('provider_id', providerId).order('created_at', ascending: false))
          .map(Review.fromJson)
          .toList();
}
