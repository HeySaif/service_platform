import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../services/providers.dart';
import '../shared/widgets.dart';
import 'client_providers.dart';

/// Request detail + incoming bids (Flow C2).
class RequestDetailScreen extends ConsumerWidget {
  const RequestDetailScreen({super.key, required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reqAsync = ref.watch(requestProvider(requestId));
    return Scaffold(
      appBar: AppBar(title: const Text('Request')),
      body: reqAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(e),
        data: (r) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(requestBidsProvider(requestId));
            await ref.refresh(requestProvider(requestId).future);
          },
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              Expanded(child: Text(r.title, style: Theme.of(context).textTheme.titleLarge)),
              StatusChip(r.status.db, color: requestStatusColor(r.status)),
            ]),
            const SizedBox(height: 8),
            Text('${r.category.label} • ${r.areaName}, ${r.city}'),
            if (r.budgetPkr != null) Text('Budget: ${pkr(r.budgetPkr!)}'),
            const SizedBox(height: 12),
            Text(r.description),
            if (r.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (final u in r.photoUrls)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(u, width: 100, height: 100, fit: BoxFit.cover)),
                    ),
                ]),
              ),
            ],
            const Divider(height: 32),
            if (r.status == RequestStatus.open) _Bids(request: r),
            if (r.status == RequestStatus.booked) const Text('A provider has been hired. Open it from the Bookings tab.'),
            if (r.status == RequestStatus.completed) const Text('This job is completed.'),
            if (r.status == RequestStatus.cancelled) const Text('This request was cancelled.'),
          ]),
        ),
      ),
    );
  }
}

class _Bids extends ConsumerStatefulWidget {
  const _Bids({required this.request});
  final ServiceRequest request;
  @override
  ConsumerState<_Bids> createState() => _BidsState();
}

class _BidsState extends ConsumerState<_Bids> {
  bool _busy = false;

  Future<void> _accept(Bid bid) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Accept this bid?'),
        content: Text('Hire ${bid.providerName} for ${pkr(bid.proposedPrice)}. All other bids will be rejected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Accept Bid')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final bookingId = await ref.read(bidRepoProvider).accept(bid.id);
      ref.invalidate(myRequestsProvider);
      if (mounted) context.pushReplacement('/booking/$bookingId');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not accept bid: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel this request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel request')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(requestRepoProvider).cancelOpen(widget.request.id);
    ref.invalidate(myRequestsProvider);
    ref.invalidate(requestProvider(widget.request.id));
  }

  @override
  Widget build(BuildContext context) {
    final bidsAsync = ref.watch(requestBidsProvider(widget.request.id));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Bids', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      bidsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
        data: (items) => items.isEmpty
            ? const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('No bids yet. Pull down to refresh.')))
            : Column(children: [for (final i in items) _BidCard(item: i, busy: _busy, onAccept: () => _accept(i.bid))]),
      ),
      const SizedBox(height: 16),
      OutlinedButton(onPressed: _cancel, child: const Text('Cancel request')),
    ]);
  }
}

class _BidCard extends StatelessWidget {
  const _BidCard({required this.item, required this.busy, required this.onAccept});
  final BidWithProvider item;
  final bool busy;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final b = item.bid;
    final p = item.profile;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(b.providerName, style: Theme.of(context).textTheme.titleSmall)),
            Text(pkr(b.proposedPrice), style: Theme.of(context).textTheme.titleMedium),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.star, size: 16, color: Colors.amber),
            Text(' ${(p?.ratingAverage ?? b.providerRating).toStringAsFixed(1)}'
                '${p != null ? ' (${p.reviewCount})' : ''} • ${p?.completedBookingsCount ?? 0} jobs done'),
          ]),
          const SizedBox(height: 8),
          Text(b.message),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: busy ? null : onAccept, style: FilledButton.styleFrom(minimumSize: const Size(120, 40)), child: const Text('Accept Bid'))),
        ]),
      ),
    );
  }
}
