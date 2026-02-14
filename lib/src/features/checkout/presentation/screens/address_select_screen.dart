// ignore_for_file: deprecated_member_use, no_leading_underscores_for_local_identifiers
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:med_shakthi/src/features/checkout/data/models/address_model.dart';
import 'package:med_shakthi/src/features/checkout/presentation/widgets/address_edit_sheet.dart';
import 'address_store.dart';
import 'payment_method_screen.dart';

class AddressSelectScreen extends StatefulWidget {
  const AddressSelectScreen({super.key});

  @override
  State<AddressSelectScreen> createState() => _AddressSelectScreenState();
}

class _AddressSelectScreenState extends State<AddressSelectScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<AddressStore>().fetchAddresses();
    });
  }

  void _showAddAddressBottomSheet({AddressModel? addressToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddressEditSheet(addressToEdit: addressToEdit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AddressStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Delivery Address"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showAddAddressBottomSheet(),
            icon: const Icon(Icons.add),
            tooltip: "Add New Address",
          ),
        ],
      ),
      body: store.loading
          ? const Center(child: CircularProgressIndicator())
          : store.addresses.isEmpty
          ? const Center(child: Text("No address saved yet"))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: store.addresses.length,
              separatorBuilder: (_, i) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final address = store.addresses[i];
                final isSelected = store.selectedAddress?.id == address.id;

                return Dismissible(
                  key: Key(address.id),
                  direction: DismissDirection.startToEnd,
                  confirmDismiss: (_) async {
                    return await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Delete Address"),
                        content: const Text(
                          "Are you sure you want to delete this address?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              "Delete",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) {
                    store.deleteAddress(address.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Address deleted")),
                    );
                  },
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.teal : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: RadioListTile<String>(
                      value: address.id,
                      groupValue: store.selectedAddress?.id,
                      activeColor: Colors.teal,
                      contentPadding: const EdgeInsets.all(8),
                      onChanged: (val) {
                        if (val != null) store.selectAddressLocal(val);
                      },
                      title: Text(
                        address.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isSelected ? Colors.teal : null,
                        ),
                      ),
                      isThreeLine: true,
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            address.fullAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                          if (address.remarks != null &&
                              address.remarks!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "Note: ${address.remarks}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      ),
                      secondary: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueGrey),
                        onPressed: () =>
                            _showAddAddressBottomSheet(addressToEdit: address),
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            if (store.selectedAddress == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please select an address")),
              );
              return;
            }
            // Pass selected address to payment screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentMethodScreen(
                  deliveryAddress: store.selectedAddress!,
                ),
              ),
            );
          },
          child: const Text(
            "PROCEED TO PAYMENT",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
