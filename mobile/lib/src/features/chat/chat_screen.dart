import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/widgets.dart';

import '../../services/providers.dart';
import 'booking_providers.dart';

/// Real-time chat between the two booking parties (FR-6).
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.bookingId, this.readOnly = false});
  final String bookingId;
  final bool readOnly;
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _text = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    final me = ref.read(currentUserProvider).value;
    if (t.isEmpty || me == null) return;
    setState(() => _sending = true);
    try {
      await ref.read(chatRepoProvider).send(bookingId: widget.bookingId, sender: me, text: t);
      _text.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not send: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider).value;
    final msgs = ref.watch(chatMessagesProvider(widget.bookingId));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(children: [
        Expanded(
          child: msgs.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorView(e),
            data: (list) => list.isEmpty
                ? const Center(child: Text('No messages yet. Say hello!'))
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final m = list[list.length - 1 - i];
                      final mine = m.senderId == me?.id;
                      return Align(
                        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: mine ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            if (!mine) Text(m.senderName, style: Theme.of(context).textTheme.labelSmall),
                            Text(m.text),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ),
        if (widget.readOnly)
          const Padding(padding: EdgeInsets.all(12), child: Text('This booking is closed — chat is read-only.'))
        else
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(hintText: 'Message', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _sending ? null : _send, icon: const Icon(Icons.send)),
              ]),
            ),
          ),
      ]),
    );
  }
}
