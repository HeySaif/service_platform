import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../shared/widgets.dart';
import 'client_providers.dart';

class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myRequestsProvider);
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        const TabBar(tabs: [Tab(text: 'Open'), Tab(text: 'Booked'), Tab(text: 'Done / Cancelled')]),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorView(e),
            data: (all) {
              List<ServiceRequest> where(bool Function(RequestStatus) f) => all.where((r) => f(r.status)).toList();
              return TabBarView(children: [
                _List(where((s) => s == RequestStatus.open), 'No open requests'),
                _List(where((s) => s == RequestStatus.booked), 'No booked requests'),
                _List(where((s) => s == RequestStatus.completed || s == RequestStatus.cancelled), 'Nothing here yet'),
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
  final List<ServiceRequest> items;
  final String empty;

  @override
  Widget build(BuildContext context, WidgetRef ref) => RefreshIndicator(
        onRefresh: () async => ref.refresh(myRequestsProvider.future),
        child: items.isEmpty
            ? ListView(children: [const SizedBox(height: 120), Center(child: Text(empty))])
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [for (final r in items) RequestCard(request: r, onTap: () => context.push('/request/${r.id}'))],
              ),
      );
}
