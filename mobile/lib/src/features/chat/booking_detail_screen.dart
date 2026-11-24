import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../services/providers.dart';
import '../client/client_providers.dart';
import '../shared/widgets.dart';
import 'booking_providers.dart';
import 'bookings_screen.dart';
import 'review_dialog.dart';

/// Booking detail (Flow C3 / P4): status, address, chat, and role-specific actions.
class BookingDetailScreen extends ConsumerStatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});
  final String bookingId;
  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _busy = false;

  void _refresh() {
    ref.invalidate(bookingInfoProvider(widget.bookingId));
    ref.invalidate(myBookingsProvider);
    ref.invalidate(myRequestsProvider);
    ref.invalidate(bookingReviewProvider(widget.bookingId));
  }

  Future<bool> _confirm(String title, String body, String yes) async =>
      (await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Back')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(yes)),
          ],
        ),
      )) ??
      false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final infoAsync = ref.watch(bookingInfoProvider(widget.bookingId));
    final me = ref.watch(currentUserProvider).value;
    final repo = ref.read(bookingRepoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      body: infoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(e),
        data: (info) {
          final b = info.booking;
          final isClient = me?.id == b.clientId;
          final active = b.status == BookingStatus.confirmed || b.status == BookingStatus.workDone;
          final address = ref.watch(requestAddressProvider(b.requestId)).value;
          final review = ref.watch(bookingReviewProvider(b.id)).value;

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Row(children: [
                Expanded(child: Text(info.title, style: Theme.of(context).textTheme.titleLarge)),
                StatusChip(b.status.db, color: bookingStatusColor(b.status)),
              ]),
              const SizedBox(height: 12),
              ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.person_outline), title: Text(isClient ? 'Provider' : 'Client'), subtitle: Text(info.otherName)),
              ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.payments_outlined), title: const Text('Agreed price'), subtitle: Text(pkr(b.agreedPrice))),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Address'),
                subtitle: Text(address ?? 'Not available'),
              ),
              if (b.status == BookingStatus.cancelled)
                ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.cancel_outlined), title: Text('Cancelled by ${b.cancelledBy?.db.toLowerCase() ?? 'a party'}')),
              if (review != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: Text('${review.rating} / 5'),
                    subtitle: review.comment == null ? null : Text(review.comment!),
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => context.push('/chat/${b.id}?readonly=${!active}'),
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(active ? 'Open chat' : 'View chat history'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 12),
              if (!isClient && b.status == BookingStatus.confirmed)
                FilledButton(
                  onPressed: _busy ? null : () => _run(() => repo.markWorkDone(b.id)),
                  child: const Text('Mark Work Done'),
                ),
              if (isClient && b.status == BookingStatus.workDone)
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          if (!await _confirm('Confirm completion?', 'This closes the job.', 'Confirm & Complete')) return;
                          await _run(() => repo.complete(b.id));
                          if (mounted) await showReviewDialog(context, b.id);
                          _refresh();
                        },
                  child: const Text('Confirm & Complete'),
                ),
              if (isClient && b.status == BookingStatus.completed && review == null)
                FilledButton(
                  onPressed: () async {
                    if (await showReviewDialog(context, b.id)) _refresh();
                  },
                  child: const Text('Leave a Review'),
                ),
              if (active) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          if (await _confirm('Cancel booking?', 'The request will be cancelled as well.', 'Cancel booking')) {
                            await _run(() => repo.cancel(b.id));
                          }
                        },
                  child: const Text('Cancel booking', style: TextStyle(color: Colors.red)),
                ),
              ],
            ]),
          );
        },
      ),
    );
  }
}
