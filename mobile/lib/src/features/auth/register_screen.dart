import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/validators.dart';
import '../../services/providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController(text: AppConfig.defaultCity);
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _city, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).signUp(
            email: _email.text,
            password: _password.text,
            fullName: _name.text,
            phone: _phone.text,
            city: _city.text,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign up failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              children: [
                TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full name'), validator: (v) => Validators.required(v, 'Name')),
                const SizedBox(height: 16),
                TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email'), validator: Validators.email),
                const SizedBox(height: 16),
                TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone'), validator: (v) => Validators.required(v, 'Phone')),
                const SizedBox(height: 16),
                TextFormField(controller: _city, decoration: const InputDecoration(labelText: 'City'), validator: (v) => Validators.required(v, 'City')),
                const SizedBox(height: 16),
                TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password'), validator: Validators.password),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sign up'),
                ),
                TextButton(onPressed: () => context.go('/login'), child: const Text('I already have an account')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
