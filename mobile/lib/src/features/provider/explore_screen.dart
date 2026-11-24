import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../services/providers.dart';
import '../shared/widgets.dart';
import 'provider_providers.dart';

/// Flow P2 — open requests feed, newest first, filterable by category and city.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});
  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _city = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).value;
    _city.text = user?.city ?? '';
    // Default the city filter to the provider's own city.
    Future.microtask(() => ref.read(feedFilterProvider.notifier).state = FeedFilter(city: _city.text));
  }

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(feedFilterProvider);
    final feed = ref.watch(providerFeedProvider);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: TextField(
          controller: _city,
          decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_on_outlined), isDense: true),
          onSubmitted: (v) => ref.read(feedFilterProvider.notifier).state = filter.copyWith(city: v.trim()),
        ),
      ),
      SizedBox(
        height: 52,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: const Text('All'),
                selected: filter.category == null,
                onSelected: (_) => ref.read(feedFilterProvider.notifier).state = filter.copyWith(clearCategory: true),
              ),
            ),
            for (final c in ServiceCategory.values)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c.label),
                  selected: filter.category == c,
                  onSelected: (_) => ref.read(feedFilterProvider.notifier).state = filter.copyWith(category: c),
                ),
              ),
          ],
        ),
      ),
      Expanded(
        child: feed.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(e),
          data: (items) => RefreshIndicator(
            onRefresh: () async => ref.refresh(providerFeedProvider.future),
            child: items.isEmpty
                ? ListView(children: const [SizedBox(height: 120), Center(child: Text('No open requests match your filters'))])
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [for (final r in items) RequestCard(request: r, onTap: () => context.push('/provider/request/${r.id}'))],
                  ),
          ),
        ),
      ),
    ]);
  }
}
