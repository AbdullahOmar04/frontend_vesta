// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreateSavings extends StatefulWidget {
  const CreateSavings({super.key});

  @override
  State<CreateSavings> createState() => _CreateSavingsState();
}

class _CreateSavingsState extends State<CreateSavings> {
  final List<Map<String, dynamic>> _savingsGoals = [
    {'title': 'New Car', 'emoji': '🚗', 'color': const Color(0xFFFFF3E0)},
    {'title': 'Vacation', 'emoji': '🏝️', 'color': const Color(0xFFE8F5E9)},
    {'title': 'House', 'emoji': '🏠', 'color': const Color(0xFFFCE4EC)},
    {
      'title': 'Emergency Fund',
      'emoji': '🆘',
      'color': const Color(0xFFFFEBEE),
    },
  ];

  void _onGoalTap(Map<String, dynamic> goal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavingsGoalDetails(
          goalTitle: goal['title'],
          emoji: goal['emoji'],
          backgroundColor: goal['color'],
        ),
      ),
    );
  }

  void _addNewGoal() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add custom saving goal'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Choose your Saving goal',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.grey[50],
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _savingsGoals.length,
                itemBuilder: (context, index) {
                  final goal = _savingsGoals[index];
                  return _buildGoalCard(goal);
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildAddNewGoalButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _onGoalTap(goal),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                goal['title'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: goal['color'],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    goal['emoji'],
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddNewGoalButton() {
    return InkWell(
      onTap: _addNewGoal,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.grey[700], size: 20),
            const SizedBox(width: 8),
            Text(
              'Add New Saving goal',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

////////////////////////////////

class SavingsGoalDetails extends StatefulWidget {
  final String goalTitle;
  final String emoji;
  final Color backgroundColor;

  const SavingsGoalDetails({
    super.key,
    required this.goalTitle,
    required this.emoji,
    required this.backgroundColor,
  });

  @override
  State<SavingsGoalDetails> createState() => _SavingsGoalDetailsState();
}

class _SavingsGoalDetailsState extends State<SavingsGoalDetails> {
  final _targetAmountController = TextEditingController();
  final _monthsController = TextEditingController();
  final _monthlyAmountController = TextEditingController();

  bool _isCalculatingFromMonths =
      true; // true = user enters months, false = user enters monthly amount

  @override
  void dispose() {
    _targetAmountController.dispose();
    _monthsController.dispose();
    _monthlyAmountController.dispose();
    super.dispose();
  }

  void _calculateMonthlyAmount() {
    final targetAmount = double.tryParse(_targetAmountController.text);
    final months = int.tryParse(_monthsController.text);

    if (targetAmount != null && months != null && months > 0) {
      final monthlyAmount = targetAmount / months;
      _monthlyAmountController.text = monthlyAmount.toStringAsFixed(2);
    }
  }

  void _calculateMonths() {
    final targetAmount = double.tryParse(_targetAmountController.text);
    final monthlyAmount = double.tryParse(_monthlyAmountController.text);

    if (targetAmount != null && monthlyAmount != null && monthlyAmount > 0) {
      final months = (targetAmount / monthlyAmount).ceil();
      _monthsController.text = months.toString();
    }
  }

  String _convertMonthsToYearsAndMonths(int totalMonths) {
    if (totalMonths < 12) {
      return '$totalMonths ${totalMonths == 1 ? 'month' : 'months'}';
    }
    final years = totalMonths ~/ 12;
    final months = totalMonths % 12;

    if (months == 0) {
      return '$years ${years == 1 ? 'year' : 'years'}';
    }
    return '$years ${years == 1 ? 'year' : 'years'} and $months ${months == 1 ? 'month' : 'months'}';
  }

  void _saveSavingGoal() async {
    final targetAmount = double.tryParse(_targetAmountController.text);
    final months = int.tryParse(_monthsController.text);
    final monthlyAmount = double.tryParse(_monthlyAmountController.text);

    if (targetAmount == null || targetAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid target amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (months == null || months <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid duration'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (monthlyAmount == null || monthlyAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid monthly amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savings')
          .add({
            'goalTitle': widget.goalTitle,
            'emoji': widget.emoji,
            'targetAmount': targetAmount,
            'currentAmount': 0.0,
            'durationMonths': months,
            'monthlyAmount': monthlyAmount,
            'createdAt': FieldValue.serverTimestamp(),
            'isCompleted': false,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.goalTitle} savings goal created!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating goal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.goalTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.grey[50],
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal Icon
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.emoji,
                    style: const TextStyle(fontSize: 50),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Target Amount
            const Text(
              'Target Amount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _targetAmountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                prefixText: 'JOD ',
                filled: true,
                fillColor: Colors.white,
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
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              onChanged: (value) {
                if (_isCalculatingFromMonths) {
                  _calculateMonthlyAmount();
                } else {
                  _calculateMonths();
                }
              },
            ),
            const SizedBox(height: 24),

            // Duration Toggle
            const Text(
              'Calculate by:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Duration'),
                  selected: _isCalculatingFromMonths,
                  onSelected: (selected) {
                    setState(() {
                      _isCalculatingFromMonths = true;
                      _calculateMonthlyAmount();
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Monthly Amount'),
                  selected: !_isCalculatingFromMonths,
                  onSelected: (selected) {
                    setState(() {
                      _isCalculatingFromMonths = false;
                      _calculateMonths();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Duration Field
            const Text(
              'Duration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _monthsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              enabled: _isCalculatingFromMonths,
              decoration: InputDecoration(
                suffixText: 'months',
                filled: true,
                fillColor: _isCalculatingFromMonths
                    ? Colors.white
                    : Colors.grey[100],
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
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              onChanged: (value) {
                if (_isCalculatingFromMonths) {
                  _calculateMonthlyAmount();
                }
              },
            ),
            if (_monthsController.text.isNotEmpty &&
                int.tryParse(_monthsController.text) != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '≈ ${_convertMonthsToYearsAndMonths(int.parse(_monthsController.text))}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Monthly Amount Field
            const Text(
              'Monthly Savings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _monthlyAmountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              enabled: !_isCalculatingFromMonths,
              decoration: InputDecoration(
                prefixText: 'JOD ',
                filled: true,
                fillColor: !_isCalculatingFromMonths
                    ? Colors.white
                    : Colors.grey[100],
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
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              onChanged: (value) {
                if (!_isCalculatingFromMonths) {
                  _calculateMonths();
                }
              },
            ),
            const SizedBox(height: 32),

            // Summary Card
            if (_targetAmountController.text.isNotEmpty &&
                _monthsController.text.isNotEmpty &&
                _monthlyAmountController.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.backgroundColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.backgroundColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      'Goal',
                      'JOD ${double.parse(_targetAmountController.text).toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Duration',
                      _convertMonthsToYearsAndMonths(
                        int.parse(_monthsController.text),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Monthly Savings',
                      'JOD ${double.parse(_monthlyAmountController.text).toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saveSavingGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Create Savings Goal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
