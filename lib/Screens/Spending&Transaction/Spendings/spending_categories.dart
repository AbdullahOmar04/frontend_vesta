import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SpendingCategories extends StatefulWidget {
  const SpendingCategories({super.key});

  @override
  State<SpendingCategories> createState() => _SpendingCategoriesState();
}

class _SpendingCategoriesState extends State<SpendingCategories> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // This shows the pop-up dialog to create a new category
  Future<void> _showCreateCategoryDialog() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    String selectedType = 'expense'; // Default type

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("New Category"),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Category Name",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter a name";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: "Category Type",
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'expense',
                          child: Text("Expense"),
                        ),
                        DropdownMenuItem(
                          value: 'income',
                          child: Text("Income"),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedType = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final categoryName = nameController.text.trim();

                      try {
                        // Use the category name as the document ID
                        await _db
                            .collection('users')
                            .doc(uid)
                            .collection('categories')
                            .doc(categoryName)
                            .set({
                          'total': 0.0,
                          'type': selectedType,
                        });

                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error: $e"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("No logged-in user.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Spending Categories"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateCategoryDialog,
        tooltip: "New Category",
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // This is the correct path, based on your screenshot
        stream: _db
            .collection('users')
            .doc(uid)
            .collection('categories')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No categories found. Create one!"),
            );
          }

          final categories = snapshot.data!.docs;

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final data = category.data();
              final categoryName = category.id; // The document ID is the name
              final type = data['type'] as String?;

              // Determine color and icon based on type
              final color =
                  (type == 'income') ? Colors.green[700] : Colors.red[700];
              final icon =
                  (type == 'income') ? Icons.arrow_downward : Icons.arrow_upward;

              return ListTile(
                leading: Icon(icon, color: color),
                title: Text(
                  categoryName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  "Type: $type",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                trailing: Text(
                  "JOD ${data['total']?.toStringAsFixed(2) ?? '0.00'}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                // You could add an onTap to see all transactions for this category
                onTap: () {
                  // Navigate to a detail page
                },
              );
            },
          );
        },
      ),
    );
  }
}