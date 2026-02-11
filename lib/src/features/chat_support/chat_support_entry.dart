import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/providers/recent_orders_provider.dart';
import 'package:med_shakthi/src/features/chat_support/data/models/order_chat_candidate.dart';

import 'presentation/screens/chat_history_page.dart';
import 'presentation/screens/chat_detail_page.dart';
import 'presentation/providers/get_or_create_chat_provider.dart';


/// ===============================================================
/// ChatSupportEntryPage
/// ===============================================================
class ChatSupportEntryPage extends ConsumerStatefulWidget {
  final bool isSupplierView;

  const ChatSupportEntryPage({
    super.key,
    this.isSupplierView = false, // default = user
  });

  @override
  ConsumerState<ChatSupportEntryPage> createState() =>
      _ChatSupportEntryPageState();
}

class _ChatSupportEntryPageState
    extends ConsumerState<ChatSupportEntryPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(recentOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Support'),
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // =======================================================
          // TAB 0 — Start new chat (Orders)
          // =======================================================
          ordersAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),

            error: (error, _) => Center(
              child: Text(
                'Failed to load recent orders.\n$error',
                textAlign: TextAlign.center,
              ),
            ),

            data: (orders) {
              if (orders.isEmpty) {
                return const _NoRecentOrdersView();
              }

              return _OrdersListView(orders: orders);
            },
          ),

          // =======================================================
          // TAB 1 — Chat history
          // =======================================================
          const ChatHistoryPage(),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_comment),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// No recent orders UI
/// ===============================================================
class _NoRecentOrdersView extends StatelessWidget {
  const _NoRecentOrdersView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No orders placed in the last 15 days.\nChat support is unavailable.',
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// ===============================================================
/// Orders list UI
/// ===============================================================
class _OrdersListView extends ConsumerStatefulWidget {
  final List<OrderChatCandidate> orders;

  const _OrdersListView({required this.orders});

  @override
  ConsumerState<_OrdersListView> createState() =>
      _OrdersListViewState();
}

class _OrdersListViewState
    extends ConsumerState<_OrdersListView> {
  String? _loadingOrderGroupId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Choose the order you want support for:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),

        Expanded(
          child: ListView.separated(
            itemCount: widget.orders.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final order = widget.orders[index];
              final isLoading =
                  _loadingOrderGroupId == order.orderGroupId;

              return ListTile(
                enabled: order.canChat && !isLoading,

                title: Text(
                  order.orderGroupId,
                  style: TextStyle(
                    color: order.canChat
                        ? null
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.4),
                  ),
                ),

                subtitle: !order.canChat && order.disableReason != null
                    ? Text(
                        order.disableReason!,
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 12,
                        ),
                      )
                    : null,

                trailing: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),

                onTap: (order.canChat && order.supplierId != null)
                    ? () async {
                        final chatId = await ref.read(
                          getOrCreateChatProvider((
                            orderGroupId: order.orderGroupId,
                            supplierId: order.supplierId!,
                          )).future,
                        );

                        if (!context.mounted) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailPage(chatId: chatId),
                          ),
                        );
                      }
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
