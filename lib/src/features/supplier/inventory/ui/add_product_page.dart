import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddProductPage extends StatefulWidget {
  final Map<String, dynamic>? product;

  const AddProductPage({super.key, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  bool get isEditing => widget.product != null;

  final nameController = TextEditingController();
  final genericController = TextEditingController();
  final brandController = TextEditingController();
  final skuController = TextEditingController();
  final priceController = TextEditingController();
  final unitSizeController = TextEditingController();
  final supplierIdController = TextEditingController(text: 'Loading...');
  final expiryController = TextEditingController();

  /// CUSTOM CATEGORY CONTROLLERS
  final customCategoryController = TextEditingController();
  final customSubCategoryController = TextEditingController();

  /// CATEGORY + SUBCATEGORY
  String category = 'Medicines';
  String subCategory = 'Tablets';

  final Map<String, List<String>> categoryMap = {
    'Medicines': ['Tablets', 'Syrups', 'Capsules', 'Injections', 'Pain Relief'],
    'Supplements': [
      'Protein',
      'Vitamins',
      'Omega 3',
      'Weight Gain',
      'Immunity',
    ],
    'Personal care': ['Skin care', 'Hair care', 'Body care', 'Cosmetics'],
    'Baby care': ['Diapers', 'Baby Food', 'Baby Lotion', 'Baby Soap'],
    'Devices': ['BP Monitor', 'Thermometer', 'Glucometer', 'Nebulizer'],
    'Other (Custom)': [],
  };

  File? imageFile;
  String? existingImageUrl;
  String? supplierCode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchSupplierCode();
    if (isEditing) _initializeEditMode();
  }

  void _initializeEditMode() {
    final p = widget.product!;
    nameController.text = p['name'] ?? '';
    genericController.text = p['generic_name'] ?? '';
    brandController.text = p['brand'] ?? '';
    skuController.text = p['sku'] ?? '';
    priceController.text = p['price']?.toString() ?? '';
    unitSizeController.text = p['unit_size'] ?? '';
    expiryController.text = p['expiry_date'] ?? '';

    final cat = p['category'];
    if (cat == 'other') {
      category = 'Other (Custom)';
      customCategoryController.text = p['custom_category'] ?? '';
      customSubCategoryController.text = p['custom_sub_category'] ?? '';
    } else if (categoryMap.containsKey(cat)) {
      category = cat;
      final sub = p['sub_category'];
      if (categoryMap[category]!.contains(sub)) {
        subCategory = sub;
      }
    }

    existingImageUrl = p['image_url'];
  }

  Future<void> fetchSupplierCode() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('suppliers')
        .select('supplier_code')
        .eq('user_id', user.id)
        .maybeSingle();

    if (mounted) {
      setState(() {
        supplierCode = data?['supplier_code'];
        supplierIdController.text = supplierCode ?? 'Unknown';
      });
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => imageFile = File(picked.path));
    }
  }

  Future<String?> uploadImage() async {
    if (imageFile == null) return null;

    final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await supabase.storage.from('product-images').upload(
          fileName,
          imageFile!,
          fileOptions: const FileOptions(upsert: true),
        );

    return supabase.storage.from('product-images').getPublicUrl(fileName);
  }

  Future<void> saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final imageUrl = await uploadImage() ?? existingImageUrl;

      final bool isCustom = category == 'Other (Custom)';

      final data = {
        'name': nameController.text.trim(),
        'generic_name': genericController.text.trim(),
        'brand': brandController.text.trim(),
        'sku': skuController.text.trim(),
        'price': double.parse(priceController.text),
        'unit_size': unitSizeController.text.trim(),
        'expiry_date': expiryController.text,
        'category': isCustom ? 'other' : category.toLowerCase().trim(),
        'sub_category':
            isCustom ? null : subCategory.toLowerCase().trim(),
        'custom_category':
            isCustom ? customCategoryController.text.trim().toLowerCase() : null,
        'custom_sub_category': isCustom &&
                customSubCategoryController.text.isNotEmpty
            ? customSubCategoryController.text.trim().toLowerCase()
            : null,
        'supplier_code': supplierCode,
        'image_url': imageUrl,
      };

      if (isEditing) {
        await supabase
            .from('products')
            .update(data)
            .eq('id', widget.product!['id']);
      } else {
        await supabase.from('products').insert(data);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Product Updated!' : 'Product Added!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> pickExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      expiryController.text = DateFormat('yyyy-MM-dd').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add New Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _imagePicker(),
              _input("Product Name", nameController),
              _input("Generic Name", genericController),
              _input("Brand", brandController),
              Row(
                children: [
                  Expanded(child: _input("SKU", skuController)),
                  const SizedBox(width: 10),
                  Expanded(child: _input("Unit Size", unitSizeController)),
                ],
              ),
              _input("Price", priceController,
                  keyboard: TextInputType.number),
              _supplierIdField(),
              _expiryField(),
              _categoryDropdown(),
              if (category != 'Other (Custom)') _subCategoryDropdown(),
              if (category == 'Other (Custom)') ...[
                _input("Custom Category", customCategoryController),
                _input("Custom Sub Category (optional)",
                    customSubCategoryController),
              ],
              const SizedBox(height: 20),
              _submitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _supplierIdField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: supplierIdController,
        readOnly: true,
        decoration: _inputDecoration("Supplier ID"),
      ),
    );
  }

  Widget _expiryField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: expiryController,
        readOnly: true,
        onTap: pickExpiryDate,
        validator: (v) => v!.isEmpty ? 'Select expiry date' : null,
        decoration: _inputDecoration("Expiry Date")
            .copyWith(suffixIcon: const Icon(Icons.calendar_today)),
      ),
    );
  }

  Widget _categoryDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: category,
        decoration: _inputDecoration("Category"),
        items: categoryMap.keys
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) {
          setState(() {
            category = v!;
            if (categoryMap[category]!.isNotEmpty) {
              subCategory = categoryMap[category]!.first;
            }
          });
        },
      ),
    );
  }

  Widget _subCategoryDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: subCategory,
        decoration: _inputDecoration("Sub Category"),
        items: categoryMap[category]!
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => setState(() => subCategory = v!),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : saveProduct,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Save Product'),
      ),
    );
  }

  Widget _imagePicker() {
    return GestureDetector(
      onTap: pickImage,
      child: Container(
        height: 140,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: imageFile == null
            ? const Center(child: Icon(Icons.add_a_photo))
            : ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(imageFile!, fit: BoxFit.cover),
              ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _input(String label, TextEditingController controller,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: (v) => v!.isEmpty ? 'Required' : null,
        decoration: _inputDecoration(label),
      ),
    );
  }
}
