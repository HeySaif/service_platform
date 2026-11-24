import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../services/providers.dart';
import '../shared/widgets.dart';
import 'provider_providers.dart';

class MyBidsScreen extends ConsumerWidget {
  const MyBidsScreen({super.key});

  Color _color(BidStatus s) => switch (s) {
        BidStatus.pending => Colors.blue,
        BidStatus.accepted => Colors.green,
        BidStatus.rejected => Colors.red,
        BidStatus.withdrawn => Colors.grey,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myBidsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(e),
      data: (items) => RefreshIndicator(
        onRefresh: () async => ref.refresh(myBidsProvider.future),
        child: items.isEmpty
            ? ListView(children: const [SizedBox(height: 120), Center(child: Text("You haven't placed any bids yet"))])
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (final i in items)
                    Card(
                      child: ListTile(
                        title: Text(i.request?.title ?? 'Request no longer available'),
                        subtitle: Text('${pkr(i.bid.proposedPrice)}${i.request != null ? ' • ${i.request!.areaName}' : ''}\n${i.bid.message}',
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        isThreeLine: true,
                        trailing: StatusChip(i.bid.status.db, color: _color(i.bid.status)),
                        onTap: i.request != null && i.bid.status == BidStatus.pending && i.request!.status == RequestStatus.open
                            ? () => context.push('/provider/request/${i.bid.requestId}')
                            : null,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
