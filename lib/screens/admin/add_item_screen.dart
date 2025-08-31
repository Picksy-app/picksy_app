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

  // Controllers - Basic Fields
  final nameEnController = TextEditingController();
  final nameTaController = TextEditingController();
  final descriptionController = TextEditingController();
  final otherDescriptionController = TextEditingController();
  final fssaiController = TextEditingController();
  final hsnController = TextEditingController();
  final barcodeController = TextEditingController();
  final imagesController = TextEditingController();
  final ingredientsController = TextEditingController();
  final notifyStockController = TextEditingController();

  // Controllers - Variant Fields
  final qtyController = TextEditingController();
  final mrpController = TextEditingController();
  final offerRetailController = TextEditingController();
  final offerWholesaleController = TextEditingController();
  final stockController = TextEditingController();
  final otherOfferController = TextEditingController();

  String unitQty = 'g';            // unit measurement dropdown (g, kg, pcs, l, etc)
  String minQtyStep = '10';        // min qty step (unused in UI here but kept)

  bool isFeatured = false;
  bool isVisible = true;
  DateTime? expirationDate;

  List<Map<String, dynamic>> variants = [];
  List<Map<String, String>> categorySubCatPairs = [];

  String? tempSelectedCategoryId;
  String? tempSelectedSubCategoryId;

  final List<String> units = ['g', 'kg', 'pcs', 'ltr', 'ml', 'packet'];
  final List<String> minQtySteps = ['10', '50', '100', '250', '500', '1000'];

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
    if(tempSelectedCategoryId != null && tempSelectedSubCategoryId != null){
      // Avoid duplicates
      bool exists = categorySubCatPairs.any((e) =>
      e['categoryId'] == tempSelectedCategoryId && e['subCategoryId'] == tempSelectedSubCategoryId);
      if(!exists){
        setState(() {
          categorySubCatPairs.add({
            'categoryId': tempSelectedCategoryId!,
            'subCategoryId': tempSelectedSubCategoryId!,
          });
          tempSelectedCategoryId = null;
          tempSelectedSubCategoryId = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Category/Subcategory pair already added")));
      }
    }
  }

  void _removePair(int index){
    setState(() {
      categorySubCatPairs.removeAt(index);
    });
  }

  void _addVariant(){
    // Validate inputs
    if(qtyController.text.trim().isEmpty || mrpController.text.trim().isEmpty
        || offerRetailController.text.trim().isEmpty || offerWholesaleController.text.trim().isEmpty
        || stockController.text.trim().isEmpty || notifyStockController.text.trim().isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill Qty, MRP, Retail, Wholesale & Stock fields")));
      return;
    }
    final double? qtyValue = double.tryParse(qtyController.text);
    final double? mrpValue = double.tryParse(mrpController.text);
    final double? retailValue = double.tryParse(offerRetailController.text);
    final double? wholesaleValue = double.tryParse(offerWholesaleController.text);
    final double? stockValue = double.tryParse(stockController.text);
    final int? notifyStock = int.tryParse(notifyStockController.text);
    if(qtyValue==null || mrpValue==null || retailValue==null || wholesaleValue==null || stockValue==null || notifyStock == null){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter valid numbers in the variant fields")));
      return;
    }

    setState(() {
      variants.add({
        'qty': qtyValue,
        'unit': unitQty,
        'mrp': mrpValue,
        'priceRetail': retailValue,
        'priceWholesale': wholesaleValue,
        'stock': stockValue,
        "notifyStock": notifyStock,
        'otherOffer': otherOfferController.text.trim(),
      });
      // Clear variant input fields
      qtyController.clear();
      mrpController.clear();
      offerRetailController.clear();
      offerWholesaleController.clear();
      stockController.clear();
      notifyStockController.clear();
      otherOfferController.clear();
      unitQty = units[0]; // Reset unit dropdown
    });
  }

  @override
  void dispose(){
    [
      nameEnController,
      nameTaController,
      descriptionController,
      otherDescriptionController,
      fssaiController,
      hsnController,
      barcodeController,
      imagesController,
      ingredientsController,
      notifyStockController,
      qtyController,
      mrpController,
      offerRetailController,
      offerWholesaleController,
      stockController,
      otherOfferController,
    ].forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> addProduct() async{
    if(!_formKey.currentState!.validate()){
      return;
    }
    if(variants.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please add at least one product variant")));
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if(uid == null){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in")));
      return;
    }
    try{
      final images = imagesController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      await FirebaseFirestore.instance.collection('products').add({
        'nameEn': nameEnController.text.trim(),
        'nameTa': nameTaController.text.trim(),
        'description': descriptionController.text.trim(),
        'otherDescription': otherDescriptionController.text.trim(),
        'ingredients': ingredientsController.text.trim(),
        'categoryIds': categorySubCatPairs.map((e)=>e['categoryId']).toList(),
        'subCategoryIds': categorySubCatPairs.map((e)=>e['subCategoryId']).toList(),
        'unit': unitQty,
        'minQtyStep': int.tryParse(minQtyStep) ?? 1,
        'variants': variants,
        'stock': double.tryParse(stockController.text) ?? 0,
        'fssai': fssaiController.text.trim(),
        'hsnCode': hsnController.text.trim(),
        'barcode': barcodeController.text.trim(),
        'images': images,
        'expirationDate': expirationDate != null ? Timestamp.fromDate(expirationDate!) : null,
        'isFeatured': isFeatured,
        'isVisible': isVisible,
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'offerPercent': int.tryParse(offerRetailController.text) ?? 0,
        'otherOffer': otherOfferController.text.trim(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product added successfully")));
      _formKey.currentState!.reset();
      // Clear state and controllers
      setState(() {
        categorySubCatPairs.clear();
        variants.clear();
        expirationDate = null;
        unitQty = units[0];
        minQtyStep = '10';
        isFeatured = false;
        isVisible = true;
        tempSelectedCategoryId = null;
        tempSelectedSubCategoryId = null;
      });
      [
        nameEnController, nameTaController, descriptionController, otherDescriptionController,
        ingredientsController, fssaiController, hsnController, barcodeController,
        imagesController, notifyStockController, qtyController, mrpController,
        offerRetailController, offerWholesaleController, stockController,
        otherOfferController,
      ].forEach((c) => c.clear());
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add product: $e"))
      );
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text("Add Product")),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [

              // Display selected category-subcategory pairs as dismissible chips
              if (categorySubCatPairs.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: List.generate(categorySubCatPairs.length, (index) {
                    final pair = categorySubCatPairs[index];
                    return Chip(
                      label: Text("${pair['categoryId']} / ${pair['subCategoryId']}"),
                      onDeleted: () => _removePair(index),
                    );
                  }),
                ),

              const SizedBox(height: 10),

// Category and Subcategory dropdowns with Add button
              Row(
                children: [
                  // Category Dropdown
                  Expanded(
                    child: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                      future: _fetchCategories(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const LinearProgressIndicator();
                        final cats = snapshot.data!;

                        return DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Select Category',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          value: tempSelectedCategoryId,
                          items: cats.map((cat) {
                            final catName = cat.data()['name'] ?? '';
                            return DropdownMenuItem<String>(
                              value: cat.id,
                              child: Text(catName),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              tempSelectedCategoryId = val;
                              tempSelectedSubCategoryId = null;
                            });
                          },
                          validator: (val) => val == null || val.isEmpty ? 'Please select a category' : null,
                          isExpanded: true,
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Subcategory Dropdown
                  Expanded(
                    child: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                      future: _fetchSubCategories(tempSelectedCategoryId),
                      builder: (context, snapshot) {
                        if (tempSelectedCategoryId == null || !snapshot.hasData) return const SizedBox.shrink();
                        final subs = snapshot.data!;

                        return DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Select Subcategory',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          value: tempSelectedSubCategoryId,
                          items: subs.map((sub) {
                            final subName = sub.data()['name'] ?? '';
                            return DropdownMenuItem<String>(
                              value: sub.id,
                              child: Text(subName),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              tempSelectedSubCategoryId = val;
                            });
                          },
                          validator: (val) => val == null || val.isEmpty ? 'Please select a subcategory' : null,
                          isExpanded: true,
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Add Pair Button
                  ElevatedButton(
                    onPressed: _addCategorySubCatPair,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('+', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),

              const SizedBox(height: 20),

// Variants entry card with vertical layout for responsive UI
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Qty and Unit in one row
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: qtyController,
                              decoration: const InputDecoration(
                                labelText: "Quantity",
                                hintText: "e.g., 1.5",
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: "Unit"),
                              value: unitQty,
                              items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    unitQty = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // MRP, Offered Retail, Offered Wholesale prices row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: mrpController,
                              decoration: const InputDecoration(labelText: "MRP Price"),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: offerRetailController,
                              decoration: const InputDecoration(labelText: "Offered Retail Price"),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: offerWholesaleController,
                              decoration: const InputDecoration(labelText: "Offered Wholesale Price"),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Stock, Notify Stock, Other Offer in one row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: stockController,
                              decoration: const InputDecoration(labelText: "Stock"),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: notifyStockController,
                              decoration: const InputDecoration(labelText: "Notify When ≤"),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: otherOfferController,
                              decoration: const InputDecoration(labelText: "Other Offer"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Add variant button aligned right
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
                          tooltip: "Add Variant",
                          onPressed: _addVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

// List of added variants as Cards with details and delete option
              if (variants.isNotEmpty)
                Column(
                  children: variants.asMap().entries.map((entry) {
                    final index = entry.key;
                    final variant = entry.value;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: ListTile(
                        title: Text("${variant['qty']} ${variant['unit']}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("MRP: ₹${variant['mrp']}"),
                            Text("Retail: ₹${variant['priceRetail']}"),
                            Text("Wholesale: ₹${variant['priceWholesale']}"),
                            Text("Stock: ${variant['stock']}"),
                            if ((variant['otherOffer'] ?? '').isNotEmpty)
                              Text("Offer: ${variant['otherOffer']}"),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              variants.removeAt(index);
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 20),

              // Other product info fields
              TextFormField(
                controller: nameEnController,
                decoration: const InputDecoration(labelText: "Item Name (English)"),
                validator: (val) => (val==null || val.trim().isEmpty) ? "Required" : null,
              ),

              TextFormField(
                controller: nameTaController,
                decoration: const InputDecoration(labelText: "Item Name (Tamil)"),
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
                controller: ingredientsController,
                decoration: const InputDecoration(labelText: "Ingredients"),
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
                decoration: const InputDecoration(labelText: "Barcode / SKU"),
              ),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Expiration Date (optional)"),
                subtitle: Text(expirationDate != null ? DateFormat('yyyy-MM-dd').format(expirationDate!) : "Select a date"),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: expirationDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if(picked != null){
                      setState(() {
                        expirationDate = picked;
                      });
                    }
                  },
                ),
              ),

              TextFormField(
                controller: imagesController,
                decoration: const InputDecoration(
                  labelText: "Image URLs (comma-separated)",
                  helperText: "Enter one or more image URLs separated by commas",
                ),
                maxLines: 2,
                validator: (val) => (val==null || val.trim().isEmpty) ? "Required" : null,
              ),

              SwitchListTile(
                title: const Text("Is Featured / New"),
                value: isFeatured,
                onChanged: (val) => setState(() => isFeatured = val),
              ),

              SwitchListTile(
                title: const Text("Visible (Active)"),
                value: isVisible,
                onChanged: (val) => setState(() => isVisible = val),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Add Product"),
                onPressed: addProduct,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

