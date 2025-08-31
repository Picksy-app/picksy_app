import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubCategory {
  final String id;
  final String name;
  final String imageUrl;

  SubCategory({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory SubCategory.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubCategory(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}

class CategoryDetailScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryDetailScreen({
    required this.categoryId,
    required this.categoryName,
    Key? key,
  }) : super(key: key);

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  String? selectedSubCategoryId;
  int selectedVariantIndex = 0;
  int count = 0;
  List<String> categorySubCategoryIds = [];
  bool isLoadingSubCategories = true;

  Future<void> fetchSubCategoryIds() async {
    try {
      final base = FirebaseFirestore.instance.collection('sub_categories');
      final query = widget.categoryId == 'all'
          ? base
          : base.where('parent_id', isEqualTo: widget.categoryId);
      final snapshot = await query.get();
      final ids = snapshot.docs.map((d) => d.id).toList();
      if (!mounted) return;
      setState(() {
        categorySubCategoryIds = ids;
        isLoadingSubCategories = false;
        if (selectedSubCategoryId == null ||
            (selectedSubCategoryId != 'all' &&
                !categorySubCategoryIds.contains(selectedSubCategoryId))) {
          selectedSubCategoryId = 'all';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingSubCategories = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isLoadingSubCategories = true;
    fetchSubCategoryIds();
  }

  // Fetch all products under this category (union of all subcategories)
  Future<List<Map<String, dynamic>>> fetchAllProductsForCategory() async {
    if (widget.categoryId == 'all') {
      final snapshot = await FirebaseFirestore.instance.collection('products').get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    }

    Set<String> seenProductIds = {};
    List<Map<String, dynamic>> allProducts = [];

    for (int i = 0; i < categorySubCategoryIds.length; i += 10) {
      final batchIds = categorySubCategoryIds.skip(i).take(10).toList();
      if (batchIds.isEmpty) continue;

      // IMPORTANT: use arrayContainsAny for arrays
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('subCategoryIds', arrayContainsAny: batchIds)
          .get();

      for (var doc in snapshot.docs) {
        if (!seenProductIds.contains(doc.id)) {
          seenProductIds.add(doc.id);
          allProducts.add(doc.data() as Map<String, dynamic>);
        }
      }
    }

    return allProducts;
  }

  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot> subCategoryStream = widget.categoryId == 'all'
        ? FirebaseFirestore.instance.collection('sub_categories').snapshots()
        : FirebaseFirestore.instance
        .collection('sub_categories')
        .where('parent_id', isEqualTo: widget.categoryId)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
      ),
      body: isLoadingSubCategories
          ? const Center(child: CircularProgressIndicator())
          : Row(
        children: [
          // Sidebar: Subcategories + ALL option
          Container(
            width: 100,
            color: Colors.white,
            child: StreamBuilder<QuerySnapshot>(
              stream: subCategoryStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading subcategories'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final subcategories = snapshot.data!.docs
                    .map((doc) => SubCategory.fromDocument(doc))
                    .toList();

                final displaySubcategories = [
                  SubCategory(id: 'all', name: 'ALL', imageUrl: ''),
                  ...subcategories,
                ];

                if (selectedSubCategoryId == null && displaySubcategories.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      selectedSubCategoryId = 'all';
                    });
                  });
                }

                return ListView.builder(
                  itemCount: displaySubcategories.length,
                  itemBuilder: (context, index) {
                    final s = displaySubcategories[index];
                    final isSelected = s.id == selectedSubCategoryId;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedSubCategoryId = s.id;
                          selectedVariantIndex = 0;
                          count = 0;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.grey.shade200 : Colors.white,
                          border: isSelected
                              ? const Border(
                            left: BorderSide(color: Colors.blue, width: 4),
                          )
                              : null,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        child: Column(
                          children: [
                            if (s.id == 'all')
                              const Icon(Icons.all_inclusive, size: 40, color: Colors.blue)
                            else if (s.imageUrl.isNotEmpty)
                              Image.network(
                                s.imageUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
                              )
                            else
                              const SizedBox(height: 40, width: 40),
                            const SizedBox(height: 5),
                            Text(
                              s.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                                color: isSelected ? Colors.blue : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Main content: product list
          Expanded(
            child: selectedSubCategoryId == null
                ? const Center(child: Text('Select a sub-category'))
                : selectedSubCategoryId == 'all'
                ? _AllProductsForCategory(
              categoryId: widget.categoryId,
              categorySubCategoryIds: categorySubCategoryIds,
              fetchAllProductsForCategory: fetchAllProductsForCategory,
            )
                : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('subCategoryIds', arrayContains: selectedSubCategoryId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading products'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No products found'));
                }
                final products = snapshot.data!.docs
                    .map((doc) => doc.data() as Map<String, dynamic>)
                    .toList();
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return PrettyProductCard(data: products[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget that renders ALL products for the current category.
/// If categoryId == 'all' -> stream all products
/// Else -> use arrayContainsAny on the subcategory ids (stream if <= 10, otherwise batch fetch once)
class _AllProductsForCategory extends StatelessWidget {
  final String categoryId;
  final List<String> categorySubCategoryIds;
  final Future<List<Map<String, dynamic>>> Function() fetchAllProductsForCategory;

  const _AllProductsForCategory({
    required this.categoryId,
    required this.categorySubCategoryIds,
    required this.fetchAllProductsForCategory,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryId == 'all') {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading products'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No products found'));
          }
          final products = snapshot.data!.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => PrettyProductCard(data: products[index]),
          );
        },
      );
    }

    if (categorySubCategoryIds.isEmpty) {
      return const Center(child: Text('No products found'));
    }

    if (categorySubCategoryIds.length <= 10) {
      // Stream when it's safe to use a single arrayContainsAny
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('subCategoryIds', arrayContainsAny: categorySubCategoryIds)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading products'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No products found'));
          }
          final products = snapshot.data!.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => PrettyProductCard(data: products[index]),
          );
        },
      );
    }

    // Fallback: batch fetch when subcategory ids > 10
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchAllProductsForCategory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading products'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No products found'));
        }
        final products = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) => PrettyProductCard(data: products[index]),
        );
      },
    );
  }
}

// ---------------- Product Card ----------------
class PrettyProductCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const PrettyProductCard({super.key, required this.data});

  @override
  State<PrettyProductCard> createState() => _PrettyProductCardState();
}

class _PrettyProductCardState extends State<PrettyProductCard> {
  int selectedVariantIndex = 0;
  int count = 0;

  @override
  Widget build(BuildContext context) {
    final List imgs = widget.data['images'] ?? [];
    final String name = widget.data['nameEn'] ?? widget.data['name'] ?? '';
    final String nameTa = widget.data['nameTa'] ?? '';
    final String firstImg = imgs.isNotEmpty ? imgs[0] : '';
    final bool isBestSeller = widget.data['isFeatured'] == true;
    final bool isFresh = widget.data['isFresh'] == true;
    final bool isOrganic = widget.data['isOrganic'] == true;
    final double avgRating = (widget.data['avgRating'] ?? 4.2).toDouble();
    final int ratings = widget.data['ratings'] ?? 1200;
    final List variants = widget.data['variants'] ?? [];
    final currentVariant =
    variants.isNotEmpty ? variants[selectedVariantIndex] : {'price': 0, 'qty': '', 'mrp': 0};

    final num unitPrice = currentVariant['price'] ?? 0;
    final String totalPrice = '\$${(unitPrice * (count == 0 ? 1 : count)).toStringAsFixed(2)}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(blurRadius: 8, spreadRadius: 1, color: Colors.black.withOpacity(0.07))
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image & Badges
          Container(
            margin: const EdgeInsets.all(16),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    firstImg,
                    width: 125,
                    height: 95,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(width: 125, height: 95),
                  ),
                ),
                if (isBestSeller)
                  Positioned(
                    top: 8,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Best Seller',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                if (isOrganic)
                  Positioned(
                    top: 34,
                    left: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      padding: const EdgeInsets.all(3.5),
                      child: const Icon(Icons.eco, size: 13, color: Colors.green),
                    ),
                  ),
              ],
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: Colors.black26),
                        onPressed: () {},
                      )
                    ],
                  ),
                  if (nameTa.isNotEmpty)
                    Text(nameTa, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      ...List.generate(4, (index) => const Icon(Icons.star, size: 18, color: Colors.amber)),
                      const Icon(Icons.star, size: 18, color: Colors.grey),
                      const SizedBox(width: 7),
                      Text(
                        '$avgRating ★  ${ratings > 1000 ? "${(ratings / 1000).toStringAsFixed(1)}k" : ratings} ratings',
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (isFresh)
                        Container(
                          margin: const EdgeInsets.only(right: 7),
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F3FE),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Text('Fresh', style: TextStyle(fontSize: 13, color: Colors.blue)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Weight & Price Dropdown section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Weight & Price", style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        if (variants.isNotEmpty)
                          DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: selectedVariantIndex,
                              isExpanded: true,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black),
                              icon: const Icon(Icons.keyboard_arrow_down),
                              items: List.generate(
                                variants.length,
                                    (i) {
                                  final v = variants[i];
                                  return DropdownMenuItem<int>(
                                    value: i,
                                    child: Row(
                                      children: [
                                        Text('${v["qty"] ?? ""} - \$${v["price"] ?? ""}'),
                                        if (v["mrp"] != null && v["price"] != v["mrp"])
                                          Padding(
                                            padding: const EdgeInsets.only(left: 7),
                                            child: Text(
                                              '\$${v["mrp"].toString()}',
                                              style: const TextStyle(
                                                decoration: TextDecoration.lineThrough,
                                                color: Colors.grey,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              onChanged: (i) {
                                setState(() {
                                  selectedVariantIndex = i!;
                                  count = 0;
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: count == 0
                            ? ElevatedButton.icon(
                          onPressed: () => setState(() => count = 1),
                          icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                          label: const Text("Add", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(fontSize: 16),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        )
                            : _QuantitySelector(
                          count: count,
                          onAdd: () => setState(() => count++),
                          onRemove: () => setState(() => count = (count > 1 ? count - 1 : 0)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: Colors.blue.shade50),
                          ),
                          child: Text("Total Price $totalPrice", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int count;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const _QuantitySelector({
    required this.count,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 20),
            splashRadius: 20,
            onPressed: onRemove,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text("$count", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            splashRadius: 20,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
