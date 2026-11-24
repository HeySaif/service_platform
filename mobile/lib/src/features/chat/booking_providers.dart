import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../services/providers.dart';

class BookingInfo {
  const BookingInfo({required this.booking, required this.title, required this.otherName});
  final Booking booking;
  final String title; // request title ("Service request" if unavailable)
  final String otherName; // the other party's name
}

Future<BookingInfo> _info(Ref ref, Booking b, String myId) async {
  final reqs = await ref.read(requestRepoProvider).byIds([b.requestId]);
  final otherId = b.clientId == myId ? b.providerId : b.clientId;
  String name = 'User';
  try {
    name = (await ref.read(authServiceProvider).fetchUser(otherId)).fullName;
  } catch (_) {}
  return BookingInfo(booking: b, title: reqs[b.requestId]?.title ?? 'Service request', otherName: name);
}

/// Bookings for the current user in their *active role*.
final myBookingsProvider = FutureProvider.autoDispose<List<BookingInfo>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  final all = await ref.watch(bookingRepoProvider).forUser(user.id);
  final mine = all.where((b) => user.activeRole == UserRole.client ? b.clientId == user.id : b.providerId == user.id);
  return Future.wait(mine.map((b) => _info(ref, b, user.id)));
});

final bookingInfoProvider = FutureProvider.autoDispose.family<BookingInfo, String>((ref, id) async {
  final user = await ref.watch(currentUserProvider.future);
  final b = await ref.watch(bookingRepoProvider).get(id);
  return _info(ref, b, user!.id);
});

final bookingReviewProvider = FutureProvider.autoDispose.family<Review?, String>(
  (ref, bookingId) => ref.watch(reviewRepoProvider).forBooking(bookingId),
);

final chatMessagesProvider = StreamProvider.autoDispose.family<List<ChatMessage>, String>(
  (ref, bookingId) => ref.watch(chatRepoProvider).watch(bookingId),
);
