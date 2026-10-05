// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';

class PlanBudgetScreen extends StatefulWidget {
  const PlanBudgetScreen({super.key});

  @override
  State<PlanBudgetScreen> createState() => _PlanBudgetScreenState();
}

class _PlanBudgetScreenState extends State<PlanBudgetScreen> {
  final _formKey = GlobalKey<FormState>();

  final _savingController = TextEditingController();
  final _spendingController = TextEditingController();
  final _luxuriesController = TextEditingController();
  final _totalIncomeController = TextEditingController();

  bool _savingPlanLoading = false;
  bool _initialLoading = true;

  double _totalIncome = 0.0;

  @override
  void initState() {
    super.initState();
    _loadExistingBudget();
  }

  Future<void> _loadExistingBudget() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _initialLoading = false);
      return;
    }

    final String monthId =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

    try {
      setState(() => _initialLoading = true);

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("budget")
          .doc(monthId)
          .get();

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _savingController.text = (data["saving"] ?? 0).toString();
        _spendingController.text = (data["spending"] ?? 0).toString();
        _luxuriesController.text = (data["luxuries"] ?? 0).toString();
      }

      if (userDoc.exists) {
        final data = userDoc.data()!;
        final raw = data["totalIncome"] ?? 0;
        _totalIncome = double.tryParse(raw.toString()) ?? 0.0;
        _totalIncomeController.text = _totalIncome.toStringAsFixed(2);
      }
    } catch (e) {
      // silent fail, allow user to type manually
    } finally {
      if (mounted) {
        setState(() => _initialLoading = false);
      }
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

    setState(() => _savingPlanLoading = true);

    try {
      final double income =
          double.tryParse(_totalIncomeController.text.trim()) ?? 0.0;

      final String monthId =
          "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("budget")
          .doc(monthId)
          .set({
            "income": income,
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
        setState(() => _savingPlanLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    return Scaffold(
      appBar: const VestaAppBar(title: "Budget plan"),
      body: VestaBackground(
        child: _initialLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    VestaSpace.gutter,
                    VestaSpace.xs,
                    VestaSpace.gutter,
                    VestaSpace.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Income Section
                      _buildSectionHeader("Monthly income"),
                      const SizedBox(height: 10),
                      _buildIncomeField(),

                      const SizedBox(height: VestaSpace.xl),

                      _buildSectionHeader("Allocation"),
                      const SizedBox(height: 10),

                      _buildPercentageField(
                        controller: _savingController,
                        label: "Savings",
                        icon: PhosphorIconsRegular.piggyBank,
                        color: v.bucketSavings,
                        hint: "How much to save each month",
                      ),

                      const SizedBox(height: 14),

                      _buildPercentageField(
                        controller: _spendingController,
                        label: "Necessities",
                        icon: PhosphorIconsRegular.shoppingCart,
                        color: v.bucketEssential,
                        hint: "Rent, groceries, bills, etc.",
                      ),

                      const SizedBox(height: 14),

                      _buildPercentageField(
                        controller: _luxuriesController,
                        label: "Luxuries",
                        icon: PhosphorIconsRegular.sparkle,
                        color: v.bucketLuxury,
                        hint: "Dining out, entertainment, etc.",
                      ),

                      const SizedBox(height: VestaSpace.lg),

                      // Total percentage indicator
                      _buildTotalPercentageIndicator(),

                      const SizedBox(height: VestaSpace.xl),

                      PrimaryButton(
                        label: 'Save budget plan',
                        loading: _savingPlanLoading,
                        onPressed: _isValidPercentage
                            ? () {
                                if (_isValidPercentage) {
                                  _savePlan();
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: headingStyle(16));
  }

  Widget _buildIncomeField() {
    final totalIncome =
        double.tryParse(_totalIncomeController.text.trim()) ?? 0.0;

    // ignore: no_leading_underscores_for_local_identifiers
    Future<void> _openIncomeDialog() async {
      await inputIncome(context, totalIncome);
      await _loadExistingBudget();
    }

    return VestaCard(
      onTap: _openIncomeDialog,
      padding: const EdgeInsets.symmetric(horizontal: VestaSpace.lg, vertical: 14),
      child: Row(
        children: [
          IconBadge(
            PhosphorIconsRegular.handCoins,
            size: 40,
            circle: false,
            color: context.vesta.pos,
          ),
          const SizedBox(width: VestaSpace.md),
          Expanded(child: MoneyText(totalIncome, size: 18)),
          OutlinedButton(
            onPressed: _openIncomeDialog,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: Text(totalIncome > 0 ? "Edit" : "Enter"),
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
        labelText: label,
        hintText: hint,
        suffixText: "%",
        prefixIcon: Icon(icon, color: color),
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
    final v = context.vesta;
    final total = _totalPercentage;
    final isValid = _isValidPercentage;
    final remaining = 100 - total;
    final color = isValid ? v.pos : v.neg;

    double pct(TextEditingController c) =>
        (double.tryParse(c.text) ?? 0).clamp(0, 100) / 100;

    return VestaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isValid
                    ? PhosphorIconsRegular.checkCircle
                    : PhosphorIconsRegular.warningCircle,
                color: color,
                size: 18,
              ),
              const SizedBox(width: VestaSpace.sm),
              Text(
                "Allocated: ${total.toStringAsFixed(0)}%",
                style: TextStyle(fontWeight: FontWeight.w500, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (c, col) in [
                    (_savingController, v.bucketSavings),
                    (_spendingController, v.bucketEssential),
                    (_luxuriesController, v.bucketLuxury),
                  ])
                    if (pct(c) > 0)
                      Expanded(
                        flex: (pct(c) * 1000).round(),
                        child: ColoredBox(color: col),
                      ),
                  if (remaining > 0)
                    Expanded(
                      flex: (remaining * 10).round(),
                      child: ColoredBox(color: v.track),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: VestaSpace.sm),
          if (remaining > 0)
            Text(
              "Unallocated: ${remaining.toStringAsFixed(0)}%",
              style: TextStyle(fontSize: 12, color: v.muted),
            ),
          if (!isValid)
            Text(
              "Total allocation cannot exceed 100%",
              style: TextStyle(
                fontSize: 12,
                color: v.neg,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _savingController.dispose();
    _spendingController.dispose();
    _luxuriesController.dispose();
    _totalIncomeController.dispose();
    super.dispose();
  }
}
