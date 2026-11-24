import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../shared/widgets.dart';
import 'booking_providers.dart';

Color bookingStatusColor(BookingStatus s) => switch (s) {
      BookingStatus.confirmed => Colors.blue,
      BookingStatus.workDone => Colors.orange,
      BookingStatus.completed => Colors.green,
      BookingStatus.cancelled => Colors.grey,
    };

/// Bookings tab (both roles): Active / Past.
class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myBookingsProvider);
    return DefaultTabController(
      length: 2,
      child: Column(children: [
        const TabBar(tabs: [Tab(text: 'Active'), Tab(text: 'Past')]),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorView(e),
            data: (all) {
              bool active(BookingInfo i) => i.booking.status == BookingStatus.confirmed || i.booking.status == BookingStatus.workDone;
              return TabBarView(children: [
                _List(all.where(active).toList(), 'No active bookings'),
                _List(all.where((i) => !active(i)).toList(), 'No past bookings'),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}

class _List extends ConsumerWidget {
  const _List(this.items, this.empty);
  final List<BookingInfo> items;
  final String empty;

  @override
  Widget build(BuildContext context, WidgetRef ref) => RefreshIndicator(
        onRefresh: () async => ref.refresh(myBookingsProvider.future),
        child: items.isEmpty
            ? ListView(children: [const SizedBox(height: 120), Center(child: Text(empty))])
            : ListView(padding: const EdgeInsets.all(12), children: [
                for (final i in items)
                  Card(
                    child: ListTile(
                      onTap: () => context.push('/booking/${i.booking.id}'),
                      title: Text(i.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${i.otherName} • ${pkr(i.booking.agreedPrice)}'),
                      trailing: StatusChip(i.booking.status.db, color: bookingStatusColor(i.booking.status)),
                    ),
                  ),
              ]),
      );
}
