import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/validators.dart';
import '../../models/models.dart';
import '../../services/providers.dart';

/// Flow P1 — one-time provider setup.
class ProviderOnboardingScreen extends ConsumerStatefulWidget {
  const ProviderOnboardingScreen({super.key});
  @override
  ConsumerState<ProviderOnboardingScreen> createState() => _ProviderOnboardingScreenState();
}

class _ProviderOnboardingScreenState extends ConsumerState<ProviderOnboardingScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _city = TextEditingController();
  final _areas = TextEditingController();
  final _categories = <ServiceCategory>{};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final u = ref.read(currentUserProvider).value;
    if (u != null) {
      _name.text = u.fullName;
      _city.text = u.city;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _bio, _city, _areas]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one category')));
      return;
    }
    final user = ref.read(currentUserProvider).requireValue!;
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).completeProviderOnboarding(ProviderProfile(
            userId: user.id,
            displayName: _name.text.trim(),
            bio: _bio.text.trim(),
            categories: _categories.toList(),
            city: _city.text.trim(),
            serviceAreas: _areas.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          ));
      ref.invalidate(currentUserProvider);
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Display name'), validator: (v) => Validators.required(v, 'Display name')),
            const SizedBox(height: 16),
            TextFormField(controller: _bio, maxLines: 3, decoration: const InputDecoration(labelText: 'Short bio'), validator: (v) => Validators.required(v, 'Bio')),
            const SizedBox(height: 16),
            Text('Services you offer', style: Theme.of(context).textTheme.titleSmall),
            Wrap(spacing: 8, children: [
              for (final c in ServiceCategory.values)
                FilterChip(
                  label: Text(c.label),
                  selected: _categories.contains(c),
                  onSelected: (s) => setState(() => s ? _categories.add(c) : _categories.remove(c)),
                ),
            ]),
            const SizedBox(height: 16),
            TextFormField(controller: _city, decoration: const InputDecoration(labelText: 'City'), validator: (v) => Validators.required(v, 'City')),
            const SizedBox(height: 16),
            TextFormField(controller: _areas, decoration: const InputDecoration(labelText: 'Areas served (comma separated)', hintText: 'Johar Town, DHA, Gulberg'), validator: (v) => Validators.required(v, 'Areas')),
            const SizedBox(height: 24),
            FilledButton(onPressed: _busy ? null : _submit, child: const Text('Save & continue')),
          ]),
        ),
      ),
    );
  }
}
