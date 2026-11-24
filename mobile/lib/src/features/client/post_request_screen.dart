import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants.dart';
import '../../core/validators.dart';
import '../../models/models.dart';
import '../../services/providers.dart';
import 'client_providers.dart';

/// Flow C1 — post a service request.
class PostRequestScreen extends ConsumerStatefulWidget {
  const PostRequestScreen({super.key, this.initialCategory});
  final ServiceCategory? initialCategory;

  @override
  ConsumerState<PostRequestScreen> createState() => _PostRequestScreenState();
}

class _PostRequestScreenState extends ConsumerState<PostRequestScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _city = TextEditingController();
  final _area = TextEditingController();
  final _address = TextEditingController();
  final _budget = TextEditingController();
  final _photos = <File>[];
  final _picker = ImagePicker();
  ServiceCategory? _category;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _city.text = ref.read(currentUserProvider).value?.city ?? AppConfig.defaultCity;
  }

  @override
  void dispose() {
    for (final c in [_title, _desc, _city, _area, _address, _budget]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final files = await _picker.pickMultiImage(imageQuality: 80, limit: AppConfig.maxPhotos - _photos.length);
        setState(() => _photos.addAll(files.take(AppConfig.maxPhotos - _photos.length).map((x) => File(x.path))));
      } else {
        final x = await _picker.pickImage(source: source, imageQuality: 80);
        if (x != null) setState(() => _photos.add(File(x.path)));
      }
    } catch (e) {
      _snack('Could not pick image: $e');
    }
  }

  void _addPhoto() {
    if (_photos.length >= AppConfig.maxPhotos) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Camera'), onTap: () { Navigator.pop(context); _pick(ImageSource.camera); }),
          ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () { Navigator.pop(context); _pick(ImageSource.gallery); }),
        ]),
      ),
    );
  }

  void _snack(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_category == null) {
      _snack('Please choose a category');
      return;
    }
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(requestRepoProvider);
      final urls = await repo.uploadPhotos(user.id, _photos);
      final req = await repo.create(
        client: user,
        title: _title.text,
        category: _category!,
        description: _desc.text,
        city: _city.text,
        areaName: _area.text,
        addressDetails: _address.text,
        budgetPkr: double.tryParse(_budget.text.trim()),
        photoUrls: urls,
      );
      ref.invalidate(myRequestsProvider);
      if (mounted) context.pushReplacement('/request/${req.id}'); // -> Request Detail & Bids
    } catch (e) {
      _snack('Could not post request: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Service Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Title'), validator: Validators.length('Title', 5, 80)),
            const SizedBox(height: 16),
            DropdownButtonFormField<ServiceCategory>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [for (final c in ServiceCategory.values) DropdownMenuItem(value: c, child: Text(c.label))],
              onChanged: (c) => setState(() => _category = c),
              validator: (v) => v == null ? 'Category is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _desc, maxLines: 4, decoration: const InputDecoration(labelText: 'Description'), validator: Validators.length('Description', 10, 1000)),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: TextFormField(controller: _city, decoration: const InputDecoration(labelText: 'City'), validator: (v) => Validators.required(v, 'City'))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _area, decoration: const InputDecoration(labelText: 'Area / neighborhood'), validator: (v) => Validators.required(v, 'Area'))),
            ]),
            const SizedBox(height: 16),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Address details', helperText: 'Only shared with the provider you hire'),
              validator: (v) => Validators.required(v, 'Address'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _budget,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Budget (PKR, optional)'),
              validator: (v) => Validators.positiveNumber(v, optional: true),
            ),
            const SizedBox(height: 16),
            Text('Photos (${_photos.length}/${AppConfig.maxPhotos})', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < _photos.length; i++)
                Stack(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_photos[i], width: 90, height: 90, fit: BoxFit.cover)),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () => setState(() => _photos.removeAt(i)),
                      child: const CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
                    ),
                  ),
                ]),
              if (_photos.length < AppConfig.maxPhotos)
                InkWell(
                  onTap: _addPhoto,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.add_a_photo_outlined),
                  ),
                ),
            ]),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit Request'),
            ),
          ]),
        ),
      ),
    );
  }
}
