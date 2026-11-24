import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../models/models.dart';
import '../../services/providers.dart';

class FeedFilter {
  const FeedFilter({this.category, this.city});
  final ServiceCategory? category;
  final String? city;
  FeedFilter copyWith({ServiceCategory? category, bool clearCategory = false, String? city}) =>
      FeedFilter(category: clearCategory ? null : (category ?? this.category), city: city ?? this.city);
}

final feedFilterProvider = StateProvider<FeedFilter>((ref) => const FeedFilter());

final providerFeedProvider = FutureProvider.autoDispose<List<ServiceRequest>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  final f = ref.watch(feedFilterProvider);
  return ref.watch(requestRepoProvider).openFeed(providerId: user.id, category: f.category, city: f.city);
});

class BidWithRequest {
  const BidWithRequest(this.bid, this.request);
  final Bid bid;
  final ServiceRequest? request; // null when hidden by RLS (booked by someone else)
}

final myBidsProvider = FutureProvider.autoDispose<List<BidWithRequest>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  final bids = await ref.watch(bidRepoProvider).mine(user.id);
  final reqs = await ref.watch(requestRepoProvider).byIds(bids.map((b) => b.requestId).toSet().toList());
  return [for (final b in bids) BidWithRequest(b, reqs[b.requestId])];
});

final myProviderProfileProvider = FutureProvider.autoDispose<ProviderProfile?>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null || !user.isProviderOnboarded) return null;
  return ref.watch(authServiceProvider).fetchProviderProfile(user.id);
});

final myReviewsProvider = FutureProvider.autoDispose<List<Review>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null || !user.isProviderOnboarded) return [];
  return ref.watch(reviewRepoProvider).forProvider(user.id);
});
