import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../services/providers.dart';
import '../chat/bookings_screen.dart';
import '../client/client_home_screen.dart';
import '../client/my_requests_screen.dart';
import '../profile/profile_screen.dart';
import '../provider/explore_screen.dart';
import '../provider/my_bids_screen.dart';

/// Bottom-nav shell. Tabs depend on active_role (docs/04 §1).
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;
  UserRole? _lastRole;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) {
        if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (_lastRole != user.activeRole) {
          _lastRole = user.activeRole;
          _index = 0;
        }
        final isClient = user.activeRole == UserRole.client;
        final tabs = isClient ? _clientTabs : _providerTabs;
        return Scaffold(
          appBar: AppBar(title: Text(tabs[_index].label), actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(label: Text(isClient ? 'Client' : 'Provider')),
            ),
          ]),
          body: _body(isClient, _index, tabs[_index]),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [for (final t in tabs) NavigationDestination(icon: Icon(t.icon), label: t.label)],
          ),
        );
      },
    );
  }
}

Widget _body(bool isClient, int i, _Tab tab) {
  if (tab.isProfile) return const ProfileScreen();
  if (i == 2) return const BookingsScreen();
  if (isClient && i == 0) return const ClientHomeScreen();
  if (isClient && i == 1) return const MyRequestsScreen();
  if (!isClient && i == 0) return const ExploreScreen();
  if (!isClient && i == 1) return const MyBidsScreen();
  return _Placeholder(tab.label);
}

class _Tab {
  const _Tab(this.label, this.icon, {this.isProfile = false});
  final String label;
  final IconData icon;
  final bool isProfile;
}

const _clientTabs = [
  _Tab('Home', Icons.home_outlined),
  _Tab('My Requests', Icons.list_alt),
  _Tab('Bookings', Icons.chat_bubble_outline),
  _Tab('Profile', Icons.person_outline, isProfile: true),
];

const _providerTabs = [
  _Tab('Explore', Icons.search),
  _Tab('My Bids', Icons.request_quote_outlined),
  _Tab('Bookings', Icons.work_outline),
  _Tab('Profile', Icons.person_outline, isProfile: true),
];

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.name);
  final String name;
  @override
  Widget build(BuildContext context) => Center(child: Text('$name — coming in the next phase'));
}
