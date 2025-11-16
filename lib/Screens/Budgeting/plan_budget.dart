// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';

class PlanBudgetScreen extends StatefulWidget {
  const PlanBudgetScreen({super.key});

  @override
  State<PlanBudgetScreen> createState() => _PlanBudgetScreenState();
}

class _PlanBudgetScreenState extends State<PlanBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _incomeController = TextEditingController();
  final _savingController = TextEditingController();
  final _spendingController = TextEditingController();
  final _luxuriesController = TextEditingController();
  final _totalIncomeController = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingBudget();
  }

  Future<void> _loadExistingBudget() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final String monthId =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("budget")
          .doc(monthId)
          .get();

      final doc2 = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _incomeController.text = (data["income"] ?? 0).toString();
        _savingController.text = (data["saving"] ?? 0).toString();
        _spendingController.text = (data["spending"] ?? 0).toString();
        _luxuriesController.text = (data["luxuries"] ?? 0).toString();
      }

      if (doc2.exists) {
        final data = doc2.data()!;
        _totalIncomeController.text = (data["totalIncome"] ?? 0).toString();
      }
    } catch (e) {
      // Handle error silently, user can still enter data
    }
  }

  double get _totalPercentage {
    final saving = double.tryParse(_savingController.text) ?? 0;
    final spending = double.tryParse(_spendingController.text) ?? 0;
    final luxuries = double.tryParse(_luxuriesController.text) ?? 0;
    return saving + spending + luxuries;
  }

  bool get _isValidPercentage => _totalPercentage <= 100;

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loading = true);

    try {
      // Get the totalIncome value
      final totalIncome = double.tryParse(_totalIncomeController.text) ?? 0;
      final String monthId =
          "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("budget")
          .doc(monthId)
          .set({
            "income": totalIncome,
            "saving": double.tryParse(_savingController.text) ?? 0,
            "spending": double.tryParse(_spendingController.text) ?? 0,
            "luxuries": double.tryParse(_luxuriesController.text) ?? 0,
            "updatedAt": FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving budget: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Plan Your Budget",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Income Section
              _buildSectionHeader("Monthly Income", Icons.attach_money),
              const SizedBox(height: 12),
              _buildIncomeField(),

              const SizedBox(height: 32),

              // Budget Allocation Section
              _buildSectionHeader("Budget Allocation", Icons.pie_chart),
              const SizedBox(height: 16),

              _buildPercentageField(
                controller: _savingController,
                label: "Savings",
                icon: Icons.savings,
                color: Colors.green,
                hint: "How much to save each month",
              ),

              const SizedBox(height: 16),

              _buildPercentageField(
                controller: _spendingController,
                label: "Essential Spending",
                icon: Icons.shopping_cart,
                color: Colors.blue,
                hint: "Rent, groceries, bills, etc.",
              ),

              const SizedBox(height: 16),

              _buildPercentageField(
                controller: _luxuriesController,
                label: "Luxuries & Entertainment",
                icon: Icons.diamond,
                color: Colors.orange,
                hint: "Dining out, entertainment, etc.",
              ),

              const SizedBox(height: 20),

              // Total percentage indicator
              _buildTotalPercentageIndicator(),

              const SizedBox(height: 32),

              _loading
                  ? const SizedBox(
                      height: 50,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : largeButton(
                      context,
                      'Save Budget Plan',
                      _isValidPercentage
                          ? Theme.of(context).colorScheme.secondary
                          : Colors.grey,
                      () {
                        if (_isValidPercentage) {
                          _savePlan();
                        }
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.black87, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeField() {
    final totalIncome = double.tryParse(_totalIncomeController.text) ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_money, color: Colors.green, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _totalIncomeController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "Enter your monthly income",
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() {}),
            ),
          ),
          ElevatedButton(
            onPressed: () => inputIncome(context, totalIncome),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              totalIncome > 0 ? "Edit" : "Enter",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: "$label Percentage",
        hintText: hint,
        suffixText: "%",
        prefixIcon: Icon(icon, color: color),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) => setState(() {}),
      validator: (value) {
        if (value == null || value.isEmpty) return null;
        final percentage = double.tryParse(value);
        if (percentage == null || percentage < 0 || percentage > 100) {
          return 'Please enter a valid percentage (0-100)';
        }
        return null;
      },
    );
  }

  Widget _buildTotalPercentageIndicator() {
    final total = _totalPercentage;
    final isValid = _isValidPercentage;
    final remaining = 100 - total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isValid ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.error,
                color: isValid ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Budget Allocation: ${total.toStringAsFixed(0)}%",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isValid ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (remaining > 0)
            Text(
              "Unallocated: ${remaining.toStringAsFixed(0)}%",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          if (!isValid)
            Text(
              "Total allocation cannot exceed 100%",
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _savingController.dispose();
    _spendingController.dispose();
    _luxuriesController.dispose();
    _totalIncomeController.dispose();
    super.dispose();
  }
}
