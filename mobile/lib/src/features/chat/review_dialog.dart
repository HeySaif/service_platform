import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/providers.dart';

/// Star rating + optional comment (Flow C4). Returns true if a review was submitted.
Future<bool> showReviewDialog(BuildContext context, String bookingId) async {
  final result = await showDialog<bool>(context: context, builder: (_) => _ReviewDialog(bookingId: bookingId));
  return result ?? false;
}

class _ReviewDialog extends ConsumerStatefulWidget {
  const _ReviewDialog({required this.bookingId});
  final String bookingId;
  @override
  ConsumerState<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends ConsumerState<_ReviewDialog> {
  int _rating = 0;
  final _comment = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await ref.read(reviewRepoProvider).submit(bookingId: widget.bookingId, rating: _rating, comment: _comment.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not submit review: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate the provider'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 1; i <= 5; i++)
            IconButton(
              onPressed: () => setState(() => _rating = i),
              icon: Icon(i <= _rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
            ),
        ]),
        TextField(controller: _comment, maxLines: 3, decoration: const InputDecoration(labelText: 'Comment (optional)')),
      ]),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Later')),
        FilledButton(onPressed: _busy || _rating == 0 ? null : _submit, child: const Text('Submit')),
      ],
    );
  }
}
