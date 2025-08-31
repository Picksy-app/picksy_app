import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_detail_screen.dart';

class Category {
  final String id;
  final String name;
  final String nameTa;
  final String imageUrl;

  Category({
    required this.id,
    required this.name,
    required this.nameTa,
    required this.imageUrl,
  });

  factory Category.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      nameTa: data['name_ta'] ?? '',
      imageUrl: data['image_url'] ?? '',
    );
  }
}

class CategoryScreen extends StatelessWidget {
  final CollectionReference categoriesCollection =
  FirebaseFirestore.instance.collection('categories');

  CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Categories",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
            tooltip: "Search",
          )
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: categoriesCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data!.docs
              .map((doc) => Category.fromDocument(doc))
              .toList();

          if (categories.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: GridView.builder(
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.7,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                return CategoryTile(category: category);
              },
            ),
          );
        },
      ),
      // Removed other section headers and snack sections for simplicity
    );
  }
}

class CategoryTile extends StatelessWidget {
  final Category category;
  const CategoryTile({required this.category, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Pass category id and name to detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryDetailScreen(
              categoryId: category.id,
              categoryName: category.name,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade300, blurRadius: 1)
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: category.imageUrl.isNotEmpty
                ? Image.network(
              category.imageUrl,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 40),
            )
                : const Icon(Icons.image_not_supported, size: 40),
          ),
          const SizedBox(height: 4),
          Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            category.nameTa,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade700,
            ),
          )
        ],
      ),
    );
  }
}
