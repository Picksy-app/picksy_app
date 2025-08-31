// add_category_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({Key? key}) : super(key: key);

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nameTaController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  Future<void> _submitCategory() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await FirebaseFirestore.instance.collection('categories').add({
          'name': _nameController.text.trim(),
          'name_ta': _nameTaController.text.trim(),
          'image_url': _imageUrlController.text.trim(),
          'created_at': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category added successfully')),
        );
        _formKey.currentState?.reset();
        _nameController.clear();
        _nameTaController.clear();
        _imageUrlController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add category: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameTaController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Category')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Category Name (English)'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter category name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nameTaController,
                decoration: const InputDecoration(labelText: 'Category Name (Tamil)'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter Tamil name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Category Image URL'),
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitCategory,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
