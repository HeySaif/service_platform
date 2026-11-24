import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/validators.dart';
import '../../models/models.dart';
import '../../services/providers.dart';
import '../client/client_providers.dart';
import '../shared/widgets.dart';
import 'provider_providers.dart';

/// Flow P3 — request details + submit / edit / withdraw a bid.
class ProviderRequestScreen extends ConsumerStatefulWidget {
  const ProviderRequestScreen({super.key, required this.requestId});
  final String requestId;
  @override
  ConsumerState<ProviderRequestScreen> createState() => _ProviderRequestScreenState();
}

class _ProviderRequestScreenState extends ConsumerState<ProviderRequestScreen> {
  final _form = GlobalKey<FormState>();
  final _price = TextEditingController();
  final _message = TextEditingController();
  bool _busy = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _price.dispose();
    _message.dispose();
    super.dispose();
  }

  void _snack(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(myBidsProvider);
      ref.invalidate(requestProvider(widget.requestId));
      _snack(done);
    } catch (e) {
      _snack('Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reqAsync = ref.watch(requestProvider(widget.requestId));
    final bids = ref.watch(myBidsProvider).value ?? const [];
    final existing = bids.map((e) => e.bid).where((b) => b.requestId == widget.requestId && b.status == BidStatus.pending).firstOrNull;
    final user = ref.watch(currentUserProvider).value;
    final profile = ref.watch(myProviderProfileProvider).value;
    final unavailable = profile != null && !profile.isAvailable;

    if (existing != null && !_prefilled) {
      _prefilled = true;
      _price.text = existing.proposedPrice.round().toString();
      _message.text = existing.message;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Request details')),
      body: reqAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('This request is no longer available.\n$e', textAlign: TextAlign.center)),
        data: (r) {
          final canBid = r.status == RequestStatus.open && user != null && r.clientId != user.id;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              Expanded(child: Text(r.title, style: Theme.of(context).textTheme.titleLarge)),
              StatusChip(r.status.db, color: requestStatusColor(r.status)),
            ]),
            const SizedBox(height: 8),
            Text('${r.category.label} • ${r.areaName}, ${r.city}'),
            Text('Posted by ${r.clientName}'),
            if (r.budgetPkr != null) Text('Client budget: ${pkr(r.budgetPkr!)}'),
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
            const SizedBox(height: 12),
            const Row(children: [
              Icon(Icons.lock_outline, size: 16),
              SizedBox(width: 6),
              Expanded(child: Text('Exact address is shared only after your bid is accepted.')),
            ]),
            const Divider(height: 32),
            if (!canBid || (unavailable && existing == null))
              Text(r.status != RequestStatus.open
                  ? 'This request is no longer open for bids.'
                  : !canBid
                      ? 'You cannot bid on your own request.'
                      : "You're set to unavailable. Turn availability on in your Profile to bid.")
            else
              Form(
                key: _form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(existing == null ? 'Place your bid' : 'Your bid (pending)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Your price (PKR)'),
                    validator: (v) => Validators.positiveNumber(v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _message,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Message to client'),
                    validator: (v) => Validators.required(v, 'Message'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () {
                            if (!_form.currentState!.validate() || user == null) return;
                            final price = double.parse(_price.text.trim());
                            final repo = ref.read(bidRepoProvider);
                            if (existing == null) {
                              _run(() => repo.submit(requestId: r.id, providerId: user.id, price: price, message: _message.text), 'Bid submitted');
                            } else {
                              _run(() => repo.update(existing.id, price: price, message: _message.text), 'Bid updated');
                            }
                          },
                    child: Text(existing == null ? 'Submit Bid' : 'Update Bid'),
                  ),
                  if (existing != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                                await ref.read(bidRepoProvider).withdraw(existing.id);
                                _prefilled = false;
                                _price.clear();
                                _message.clear();
                              }, 'Bid withdrawn'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      child: const Text('Withdraw Bid'),
                    ),
                  ],
                ]),
              ),
          ]);
        },
      ),
    );
  }
}
