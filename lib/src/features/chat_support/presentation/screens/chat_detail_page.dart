import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/chat_messages_provider.dart';
import '../providers/send_message_provider.dart';
import '../providers/chat_repository_provider.dart';
import '../providers/supplier_id_provider.dart';

class ChatDetailPage extends ConsumerStatefulWidget {
  final String chatId;

  const ChatDetailPage({super.key, required this.chatId});

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _markMessagesReadIfSupplier();
  }

  Future<void> _markMessagesReadIfSupplier() async {
    final supplierId = await ref.read(supplierIdProvider.future);
    if (supplierId == null) return;

    try {
      await ref.read(chatRepositoryProvider).markMessagesAsRead(
            chatId: widget.chatId,
            supplierId: supplierId,
          );
    } catch (_) {
      // ignore errors silently for now
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(chatMessagesProvider(widget.chatId));

    return Scaffold(
      appBar: AppBar(title: const Text('Support Chat')),
      body: Column(
        children: [
          // ---------------- Messages ----------------
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (messages) => ListView.builder(
                itemCount: messages.length,
                itemBuilder: (_, i) {
                  final m = messages[i];
                  final isMe = m.senderId ==
                      Supabase.instance.client.auth.currentUser!.id;

                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.teal.shade200
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(m.body),
                    ),
                  );
                },
              ),
            ),
          ),

          // ---------------- Input ----------------
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;

                    final repo = ref.read(sendMessageProvider);
                    await repo.sendMessage(
                      chatId: widget.chatId,
                      senderId: Supabase
                          .instance.client.auth.currentUser!.id,
                      body: text,
                    );

                    controller.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
