import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});
  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();

  // Product text controllers
  final nameEnController = TextEditingController();
  final nameTaController = TextEditingController();
  final descriptionController = TextEditingController();
  final otherDescriptionController = TextEditingController();
  final wholesalePriceController = TextEditingController();
  final retailPriceController = TextEditingController();
  final offerController = TextEditingController();
  final otherOfferController = TextEditingController();
  final fssaiController = TextEditingController();
  final hsnController = TextEditingController();
  final minQtyStepController = TextEditingController();
  final stockController = TextEditingController();
  final barcodeController = TextEditingController();
  final imagesController = TextEditingController();
  final notifyStockController = TextEditingController();

  // Variant controllers
  final variantQtyController = TextEditingController();
  final variantMrpController = TextEditingController();
  final variantPriceController = TextEditingController();
  List<Map<String, dynamic>> variants = [];

  String unit = 'g';
  String minQtyStep = '10';
  bool isFeatured = false;
  bool isVisible = true;
  DateTime? expirationDate;

  final List<String> units = ['g', 'kg', 'ml', 'l', 'pcs', 'packet'];
  final List<String> minQtySteps = ['10', '50', '100', '250', '500', '1000'];

  // Multi-select category/sub-category support
  List<Map<String, String>> categorySubCatPairs = [];
  String? tempSelectedCategoryId;
  String? tempSelectedSubCategoryId;

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('categories').get();
    return snapshot.docs;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchSubCategories(String? categoryId) async {
    if (categoryId == null) return [];
    final snapshot = await FirebaseFirestore.instance
        .collection('sub_categories')
        .where('parent_id', isEqualTo: categoryId)
        .get();
    return snapshot.docs;
  }

  void _addCategorySubCatPair() {
    if (tempSelectedCategoryId != null && tempSelectedSubCategoryId != null) {
      setState(() {
        categorySubCatPairs.add({
          'categoryId': tempSelectedCategoryId!,
          'subCategoryId': tempSelectedSubCategoryId!,
        });
        tempSelectedCategoryId = null;
        tempSelectedSubCategoryId = null;
      });
    }
  }

  void _removePair(int index) {
    setState(() {
      categorySubCatPairs.removeAt(index);
    });
  }

  void _addVariant() {
    if (variantQtyController.text.isEmpty ||
        variantMrpController.text.isEmpty ||
        variantPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter all variant fields")));
      return;
    }
    setState(() {
      variants.add({
        'qty': variantQtyController.text,
        'mrp': double.tryParse(variantMrpController.text) ?? 0.0,
        'price': double.tryParse(variantPriceController.text) ?? 0.0,
      });
      variantQtyController.clear();
      variantMrpController.clear();
      variantPriceController.clear();
    });
  }

  @override
  void dispose() {
    for (final c in [
      nameEnController, nameTaController, descriptionController, otherDescriptionController,
      wholesalePriceController, retailPriceController, offerController, otherOfferController,
      fssaiController, hsnController, minQtyStepController, stockController, barcodeController,
      imagesController, notifyStockController, variantQtyController, variantMrpController, variantPriceController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final adminUserId = FirebaseAuth.instance.currentUser?.uid;
    if (adminUserId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("User not logged in!")));
      return;
    }

    try {
      final images = imagesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await FirebaseFirestore.instance.collection('products').add({
        'nameEn': nameEnController.text.trim(),
        'nameTa': nameTaController.text.trim(),
        'categoryIds': categorySubCatPairs.map((x) => x['categoryId']).toList(),
        'subCategoryIds': categorySubCatPairs.map((x) => x['subCategoryId']).toList(),
        'unit': unit,
        'pricePerUnitRetail': double.tryParse(retailPriceController.text) ?? 0,
        'pricePerUnitWholesale': double.tryParse(wholesalePriceController.text) ?? 0,
        'minOrderQty': int.tryParse(minQtyStep),
        'unitStep': int.tryParse(minQtyStep),
        'availableStock': double.tryParse(stockController.text) ?? 0,
        'offers': otherOfferController.text,
        'discount': int.tryParse(offerController.text) ?? 0,
        'notifyStock': int.tryParse(notifyStockController.text) ?? 0,
        'description': descriptionController.text,
        'otherDescription': otherDescriptionController.text,
        'fssai': fssaiController.text,
        'hsnCode': hsnController.text,
        'barcode': barcodeController.text,
        'expirationDate': expirationDate != null ? Timestamp.fromDate(expirationDate!) : null,
        'isFeatured': isFeatured,
        'isVisible': isVisible,
        'images': images,
        'variants': variants,
        'adminUserId': adminUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Product added successfully!')));
      _formKey.currentState!.reset();

      // Clear all
      for (final c in [
        nameEnController, nameTaController, descriptionController, otherDescriptionController,
        wholesalePriceController, retailPriceController, offerController, otherOfferController,
        fssaiController, hsnController, minQtyStepController, stockController, barcodeController,
        imagesController, notifyStockController, variantQtyController, variantMrpController, variantPriceController
      ]) {
        c.clear();
      }
      setState(() {
        categorySubCatPairs.clear();
        tempSelectedCategoryId = null;
        tempSelectedSubCategoryId = null;
        variants.clear();
        expirationDate = null;
        unit = 'g';
        minQtyStep = '10';
        isFeatured = false;
        isVisible = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Multi-selection chips for category/subcat pairs
              if (categorySubCatPairs.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: [
                    for (int i = 0; i < categorySubCatPairs.length; i++)
                      Chip(
                        label: Text('${categorySubCatPairs[i]['categoryId']} / ${categorySubCatPairs[i]['subCategoryId']}'),
                        onDeleted: () => _removePair(i),
                      ),
                  ],
                ),
              const SizedBox(height: 10),

              // Category/Sub-category selection row (with "+")
              Row(
                children: [
                  Expanded(
                    child: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                      future: _fetchCategories(),
                      builder: (ctx, catSnap) {
                        if (!catSnap.hasData) return const LinearProgressIndicator();
                        final cats = catSnap.data!;
                        return DropdownButtonFormField<String>(
                          hint: const Text('Category'),
                          value: tempSelectedCategoryId,
                          items: cats.map((cat) => DropdownMenuItem(
                            value: cat.id,
                            child: Text(cat['name']),
                          )).toList(),
                          onChanged: (id) {
                            setState(() {
                              tempSelectedCategoryId = id;
                              tempSelectedSubCategoryId = null;
                            });
                          },
                          validator: (val) => val == null || val.isEmpty ? "Choose Category" : null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                      future: _fetchSubCategories(tempSelectedCategoryId),
                      builder: (ctx, subCatSnap) {
                        if (tempSelectedCategoryId == null || !subCatSnap.hasData) {
                          return const SizedBox();
                        }
                        final subCats = subCatSnap.data!;
                        return DropdownButtonFormField<String>(
                          hint: const Text('Sub-Category'),
                          value: tempSelectedSubCategoryId,
                          items: subCats.map((sub) => DropdownMenuItem(
                            value: sub.id,
                            child: Text(sub['name']),
                          )).toList(),
                          onChanged: (id) {
                            setState(() => tempSelectedSubCategoryId = id);
                          },
                          validator: (val) => val == null || val.isEmpty ? "Choose Sub-Category" : null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _addCategorySubCatPair,
                    child: const Text('+'),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Variant entry
              Text('Product Variants (Weight & Price)', style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: variantQtyController,
                      decoration: const InputDecoration(labelText: "Qty (e.g. 1 kg)"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: variantMrpController,
                      decoration: const InputDecoration(labelText: "MRP"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: variantPriceController,
                      decoration: const InputDecoration(labelText: "Offered Price"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addVariant,
                  ),
                ],
              ),
              if (variants.isNotEmpty)
                Column(
                  children: List.generate(
                    variants.length,
                        (i) => ListTile(
                      title: Text('${variants[i]['qty']} - \$${variants[i]['price']} (MRP \$${variants[i]['mrp']})'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          setState(() {
                            variants.removeAt(i);
                          });
                        },
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              TextFormField(
                controller: nameEnController,
                decoration: const InputDecoration(labelText: "Item Name (English)"),
                validator: (v) => v!.isEmpty ? "Enter item name" : null,
              ),
              TextFormField(
                controller: nameTaController,
                decoration: const InputDecoration(labelText: "Item Name (Tamil)"),
              ),
              TextFormField(
                controller: wholesalePriceController,
                decoration: const InputDecoration(labelText: "Wholesale Price per unit"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: retailPriceController,
                decoration: const InputDecoration(labelText: "Retail Price per unit"),
                keyboardType: TextInputType.number,
              ),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: unit,
                      decoration: const InputDecoration(labelText: "Unit"),
                      items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (val) => setState(() => unit = val!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: minQtyStep,
                      decoration: const InputDecoration(labelText: "Min Qty Step"),
                      items: minQtySteps.map((step) => DropdownMenuItem(value: step, child: Text(step))).toList(),
                      onChanged: (val) => setState(() => minQtyStep = val!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: stockController,
                      decoration: const InputDecoration(labelText: "Stock"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: notifyStockController,
                decoration: const InputDecoration(labelText: "Notify Admin when stocks ≤"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: offerController,
                decoration: const InputDecoration(labelText: "Discount Offer (%)"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: otherOfferController,
                decoration: const InputDecoration(labelText: "Other Offer (Buy 2 Get 1 etc.)"),
              ),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 2,
              ),
              TextFormField(
                controller: otherDescriptionController,
                decoration: const InputDecoration(labelText: "Other Description"),
                maxLines: 2,
              ),
              TextFormField(
                controller: fssaiController,
                decoration: const InputDecoration(labelText: "FSSAI Number"),
              ),
              TextFormField(
                controller: hsnController,
                decoration: const InputDecoration(labelText: "Tax/HSN Code"),
              ),
              TextFormField(
                controller: barcodeController,
                decoration: const InputDecoration(labelText: "Barcode/SKU"),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Expiration Date (optional)"),
                subtitle: Text(expirationDate != null
                    ? DateFormat('yyyy-MM-dd').format(expirationDate!)
                    : "Select date"),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    DateTime? date = await showDatePicker(
                      context: context,
                      initialDate: expirationDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) setState(() => expirationDate = date);
                  },
                ),
              ),
              TextFormField(
                controller: imagesController,
                decoration: const InputDecoration(
                  labelText: "Image URLs (comma separated)",
                  helperText: "Paste 1 or more image links, separated by commas",
                ),
                maxLines: 2,
                validator: (s) => s == null || s.trim().isEmpty ? "At least 1 image link required" : null,
              ),
              SwitchListTile(
                value: isFeatured,
                onChanged: (v) => setState(() => isFeatured = v),
                title: const Text("Is Featured/New"),
              ),
              SwitchListTile(
                value: isVisible,
                onChanged: (v) => setState(() => isVisible = v),
                title: const Text("Visibility (Active)"),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text("Add Product"),
                onPressed: addProduct,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
