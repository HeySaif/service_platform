import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../shared/widgets.dart';
import 'client_providers.dart';

class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(myRequestsProvider);
    final active = requests.value
            ?.where((r) => r.status == RequestStatus.open || r.status == RequestStatus.booked)
            .take(3)
            .toList() ??
        [];

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(myRequestsProvider.future),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('What do you need help with?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
            children: [
              for (final c in ServiceCategory.values)
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.push('/post-request', extra: c),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(categoryIcon(c), size: 30, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 6),
                      Text(c.label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelMedium),
                    ]),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push('/post-request'),
            icon: const Icon(Icons.add),
            label: const Text('Post a Service Request'),
          ),
          if (active.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Your active requests', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final r in active) RequestCard(request: r, onTap: () => context.push('/request/${r.id}')),
          ],
        ],
      ),
    );
  }
}
