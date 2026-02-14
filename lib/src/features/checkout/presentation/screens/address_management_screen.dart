import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:med_shakthi/src/features/checkout/data/models/address_model.dart';
import '../screens/address_store.dart';
import '../widgets/address_edit_sheet.dart';

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({super.key});

  @override
  State<AddressManagementScreen> createState() =>
      _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<AddressStore>().fetchAddresses();
    });
  }

  void _showAddAddressSheet({AddressModel? addressToEdit}) {
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
      appBar: AppBar(title: const Text("My Addresses"), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAddressSheet(),
        child: const Icon(Icons.add),
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
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.location_on, color: Colors.white),
                    ),
                    title: Text(
                      address.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(address.fullAddress),
                        if (address.remarks != null &&
                            address.remarks!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              "Note: ${address.remarks}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () =>
                              _showAddAddressSheet(addressToEdit: address),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text("Delete Address"),
                                content: const Text("Are you sure?"),
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

                            if (confirm == true) {
                              await store.deleteAddress(address.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
