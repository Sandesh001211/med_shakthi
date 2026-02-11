import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:med_shakthi/src/features/chat_support/presentation/providers/supplier_chats_provider.dart';
import 'package:med_shakthi/src/features/chat_support/presentation/screens/chat_detail_page.dart';
import 'package:med_shakthi/src/features/chat_support/presentation/providers/supplier_unread_count_provider.dart';

class SupplierChatListPage extends ConsumerWidget {
  const SupplierChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(supplierChatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Chats'),
      ),
      body: chatsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (chats) {
          if (chats.isEmpty) {
            return const Center(
              child: Text('No chats yet'),
            );
          }

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = chats[index];

              return ListTile(
                title: Text('Order: ${chat.orderGroupId}'),
                subtitle: Text(
                  chat.lastMessage ?? 'No messages yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Consumer(
                  builder: (context, ref, _) {
                    final unreadAsync =
                        ref.watch(supplierUnreadCountProvider(chat.chatId));

                    return unreadAsync.when(
                      data: (count) {
                        if (count == 0) return const SizedBox.shrink();

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
                onTap: () {
                  // 🔹 Immediately clear unread badge for this chat
                   ref.invalidate(supplierUnreadCountProvider(chat.chatId));

                  Navigator.push(
                   context,
                   MaterialPageRoute(
                      builder: (_) => ChatDetailPage(chatId: chat.chatId),
                   ),
                 );
               },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}
