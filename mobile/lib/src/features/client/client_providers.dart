import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../services/providers.dart';

final myRequestsProvider = FutureProvider.autoDispose<List<ServiceRequest>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  return ref.watch(requestRepoProvider).myRequests(user.id);
});

final requestProvider = FutureProvider.autoDispose.family<ServiceRequest, String>(
  (ref, id) => ref.watch(requestRepoProvider).getById(id),
);

class BidWithProvider {
  const BidWithProvider(this.bid, this.profile);
  final Bid bid;
  final ProviderProfile? profile;
}

final requestBidsProvider = FutureProvider.autoDispose.family<List<BidWithProvider>, String>((ref, requestId) async {
  final bids = await ref.watch(bidRepoProvider).forRequest(requestId);
  final profiles = await ref.watch(bidRepoProvider).profilesFor(bids.map((b) => b.providerId).toSet().toList());
  return [for (final b in bids) BidWithProvider(b, profiles[b.providerId])];
});

final requestAddressProvider = FutureProvider.autoDispose.family<String?, String>(
  (ref, id) => ref.watch(requestRepoProvider).addressFor(id),
);
