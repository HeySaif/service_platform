import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../services/providers.dart';
import '../provider/provider_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const Center(child: CircularProgressIndicator());
    final isClient = user.activeRole == UserRole.client;

    Future<void> switchMode() async {
      if (isClient && !user.isProviderOnboarded) {
        context.push('/provider-onboarding'); // Flow P1
        return;
      }
      await ref.read(authServiceProvider).setActiveRole(user.id, isClient ? UserRole.provider : UserRole.client);
      ref.invalidate(currentUserProvider);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(user.fullName),
          subtitle: Text('${user.email}\n${user.phone} • ${user.city}'),
          isThreeLine: true,
        ),
        if (!isClient) _ProviderSection(user: user),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: switchMode,
          icon: const Icon(Icons.swap_horiz),
          label: Text(isClient ? 'Switch to Provider Mode' : 'Switch to Client Mode'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => ref.read(authServiceProvider).signOut(),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
      ],
    );
  }
}

/// Provider stats, availability toggle and received reviews.
class _ProviderSection extends ConsumerWidget {
  const _ProviderSection({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProviderProfileProvider).value;
    final reviews = ref.watch(myReviewsProvider).value ?? const [];
    if (profile == null) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(height: 32),
      Text(profile.displayName, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      Text(profile.bio),
      const SizedBox(height: 8),
      Wrap(spacing: 6, children: [for (final c in profile.categories) Chip(label: Text(c.label))]),
      Text('Areas: ${profile.serviceAreas.join(', ')}'),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _Stat(icon: Icons.star, value: profile.ratingAverage.toStringAsFixed(1), label: '${profile.reviewCount} reviews'),
        _Stat(icon: Icons.task_alt, value: '${profile.completedBookingsCount}', label: 'jobs done'),
      ]),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Available for new work'),
        subtitle: const Text('Turn off to pause bidding'),
        value: profile.isAvailable,
        onChanged: (v) async {
          await ref.read(authServiceProvider).setAvailability(user.id, v);
          ref.invalidate(myProviderProfileProvider);
        },
      ),
      if (reviews.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text('Reviews', style: Theme.of(context).textTheme.titleSmall),
        for (final r in reviews)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.star, color: Colors.amber),
            title: Text('${r.rating}/5 • ${r.clientName}'),
            subtitle: r.comment == null ? null : Text(r.comment!),
          ),
      ],
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(children: [
        Row(children: [Icon(icon, color: Colors.amber), const SizedBox(width: 4), Text(value, style: Theme.of(context).textTheme.titleLarge)]),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ]);
}
