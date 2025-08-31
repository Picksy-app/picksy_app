// add_sub_category_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddSubCategoryScreen extends StatefulWidget {
  const AddSubCategoryScreen({Key? key}) : super(key: key);

  @override
  State<AddSubCategoryScreen> createState() => _AddSubCategoryScreenState();
}

class _AddSubCategoryScreenState extends State<AddSubCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subCatNameController = TextEditingController();
  final TextEditingController _subCatNameTaController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  String? _selectedCategoryName;
  String? _selectedCategoryId;

  Future<List<Map<String, dynamic>>> _fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('categories').get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, 'name': doc['name'] as String})
        .toList();
  }

  Future<void> _submitSubCategory() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }
      try {
        await FirebaseFirestore.instance.collection('sub_categories').add({
          'name': _subCatNameController.text.trim(),
          'name_ta': _subCatNameTaController.text.trim(),
          'image_url': _imageUrlController.text.trim(),
          'parent_id': _selectedCategoryId,
          'created_at': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sub-category added successfully')),
        );
        _formKey.currentState?.reset();
        _subCatNameController.clear();
        _subCatNameTaController.clear();
        _imageUrlController.clear();
        setState(() {
          _selectedCategoryName = null;
          _selectedCategoryId = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add sub-category: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _subCatNameController.dispose();
    _subCatNameTaController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Sub-Category')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchCategories(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No categories available, please add categories first.'));
            }
            final categories = snapshot.data!;

            return Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _subCatNameController,
                    decoration: const InputDecoration(labelText: 'Sub-Category Name (English)'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter sub-category name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _subCatNameTaController,
                    decoration: const InputDecoration(labelText: 'Sub-Category Name (Tamil)'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter Tamil sub-category name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Select Category'),
                    value: _selectedCategoryName,
                    items: categories
                        .map((cat) => DropdownMenuItem(
                      value: cat['name'] as String,
                      child: Text(cat['name'] as String),
                    ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategoryName = val;
                        _selectedCategoryId = categories
                            .firstWhere((cat) => cat['name'] == val)['id'] as String;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(labelText: 'Sub-Category Image URL'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter image URL';
                      }
                      if (Uri.tryParse(value)?.hasAbsolutePath != true) {
                        return 'Please enter a valid URL';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitSubCategory,
                    child: const Text('Submit'),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
