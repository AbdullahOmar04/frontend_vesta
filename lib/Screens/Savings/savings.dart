// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Screens/Savings/create_savings.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  final user = FirebaseAuth.instance.currentUser;

  void _navigateToCreateSavings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateSavings()),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _showAllocateBottomSheet(
    String goalId,
    Map<String, dynamic> goal,
  ) async {
    final amountController = TextEditingController();
    final goalTitle = goal['goalTitle'] ?? 'Goal';
    final currentAmount = (goal['currentAmount'] ?? 0).toDouble();
    final targetAmount = (goal['targetAmount'] ?? 0).toDouble();
    final remaining = targetAmount - currentAmount;

    final userId = user?.uid;
    if (userId == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    final totalSavings = (userDoc.data()?['totalSavings'] ?? 0).toDouble();

    final savingsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('savings')
        .get();

    double totalAllocated = 0.0;
    for (var doc in savingsSnapshot.docs) {
      totalAllocated += (doc.data()['currentAmount'] ?? 0).toDouble();
    }

    final available = totalSavings - totalAllocated;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Text(
                'Allocate to $goalTitle',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(32, 162, 0, 255),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available: JOD ${available.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current in goal: JOD ${currentAmount.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    Text(
                      'Remaining: JOD ${remaining.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount to Allocate',
                  prefixText: 'JOD ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: currentAmount > 0
                        ? () {
                            Navigator.pop(context);
                            _showDeallocateDialog(goalId, goal);
                          }
                        : null,
                    child: Text(
                      'Remove from goal',
                      style: TextStyle(
                        color: currentAmount > 0 ? Colors.red : Colors.grey,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final amount = double.tryParse(amountController.text);
                      if (amount != null && amount > 0) {
                        if (amount > available) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Insufficient available balance'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else {
                          _allocateToGoal(goalId, goal, amount);
                          Navigator.pop(context);
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid amount'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text('Allocate'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _deleteSavingGoalDialog(String goalId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Savings Goal'),
        content: const Text(
          'Are you sure you want to delete this savings goal? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final userId = user?.uid;
              if (userId == null) return;

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('savings')
                  .doc(goalId)
                  .delete();

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Savings goal deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeallocateDialog(String goalId, Map<String, dynamic> goal) {
    final amountController = TextEditingController();
    final goalTitle = goal['goalTitle'] ?? 'Goal';
    final currentAmount = (goal['currentAmount'] ?? 0).toDouble();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove from $goalTitle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Current in goal: JOD ${currentAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount to Remove',
                prefixText: 'JOD ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                amountController.text = currentAmount.toString();
              },
              child: const Text('Remove all'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                if (amount > currentAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Amount exceeds current allocation'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  _deallocateFromGoal(goalId, goal, amount);
                  Navigator.pop(context);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _allocateToGoal(
    String goalId,
    Map<String, dynamic> goal,
    double amount,
  ) async {
    final userId = user?.uid;
    if (userId == null) return;

    try {
      final currentAmount = (goal['currentAmount'] ?? 0).toDouble();
      final targetAmount = (goal['targetAmount'] ?? 0).toDouble();
      final newCurrentAmount = currentAmount + amount;
      final isCompleted = newCurrentAmount >= targetAmount;

      // Update only the goal - don't touch totalSavings
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savings')
          .doc(goalId)
          .update({
            'currentAmount': newCurrentAmount,
            'isCompleted': isCompleted,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'JOD ${amount.toStringAsFixed(2)} allocated successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deallocateFromGoal(
    String goalId,
    Map<String, dynamic> goal,
    double amount,
  ) async {
    final userId = user?.uid;
    if (userId == null) return;

    try {
      final currentAmount = (goal['currentAmount'] ?? 0).toDouble();
      final targetAmount = (goal['targetAmount'] ?? 0).toDouble();
      final newCurrentAmount = currentAmount - amount;
      final isCompleted = newCurrentAmount >= targetAmount;

      // Update only the goal - don't touch totalSavings
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savings')
          .doc(goalId)
          .update({
            'currentAmount': newCurrentAmount,
            'isCompleted': isCompleted,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'JOD ${amount.toStringAsFixed(2)} removed successfully!',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Icon(Icons.savings, size: 80, color: const Color.fromARGB(255, 98, 0, 255)),
          const SizedBox(height: 16),
          Text(
            "No Savings Goals Yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Create your first savings goal to\nstart managing your finances",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: largeButton(
              context,
              "Create Savings Goal",
              Theme.of(context).colorScheme.secondary,
              _navigateToCreateSavings,
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final userId = user?.uid;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.primary,
      appBar: AppBar(
        title: Text('Savings Goals', style: TextStyle(color: scheme.surface)),
        centerTitle: true,
        iconTheme: IconThemeData(color: scheme.surface),
        backgroundColor: scheme.primary,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateSavings,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: userId == null
          ? const Center(child: Text("Not logged in"))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .doc(userId)
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData =
                    userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                final totalSavings = (userData["totalSavings"] ?? 0).toDouble();

                return Container(
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Total Savings Header with StreamBuilder for allocated amount
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("users")
                            .doc(userId)
                            .collection("savings")
                            .snapshots(),
                        builder: (context, savingsSnapshot) {
                          double totalAllocated = 0.0;

                          if (savingsSnapshot.hasData) {
                            for (var doc in savingsSnapshot.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              totalAllocated += (data['currentAmount'] ?? 0)
                                  .toDouble();
                            }
                          }

                          final unallocated = totalSavings - totalAllocated;

                          return Container(
                            padding: const EdgeInsets.all(24),
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: scheme.onPrimary, //onPrimary
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Total Savings\n',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            'JOD ${totalSavings.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Available to Allocate: ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'JOD ${unallocated.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: unallocated > 0
                                              ? Colors.green[700]
                                              : Colors.red[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Savings Goals List
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("users")
                              .doc(userId)
                              .collection("savings")
                              .orderBy("createdAt", descending: true)
                              .snapshots(),
                          builder: (context, savingsSnapshot) {
                            if (savingsSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (!savingsSnapshot.hasData ||
                                savingsSnapshot.data!.docs.isEmpty) {
                              return _buildEmptyState();
                            }

                            final savingsGoals = savingsSnapshot.data!.docs;

                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: savingsGoals.length,
                              itemBuilder: (context, index) {
                                final goal =
                                    savingsGoals[index].data()
                                        as Map<String, dynamic>;
                                final goalId = savingsGoals[index].id;

                                return _buildSavingsGoalCard(goal, goalId);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSavingsGoalCard(Map<String, dynamic> goal, String goalId) {
    final goalTitle = goal['goalTitle'] ?? 'Unknown';
    final emoji = goal['emoji'] ?? '💰';
    final targetAmount = (goal['targetAmount'] ?? 0).toDouble();
    final currentAmount = (goal['currentAmount'] ?? 0).toDouble();
    final durationMonths = goal['durationMonths'] ?? 0;
    final monthlyAmount = (goal['monthlyAmount'] ?? 0).toDouble();
    final isCompleted = goal['isCompleted'] ?? false;

    final progress = targetAmount > 0 ? currentAmount / targetAmount : 0.0;
    final progressPercentage = (progress * 100).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showAllocateBottomSheet(goalId, goal),
        onLongPress: () => {_deleteSavingGoalDialog(goalId)},
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goalTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _convertMonthsToYearsAndMonths(durationMonths),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Completed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'JOD ${currentAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'JOD ${targetAmount.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? Colors.green : Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$progressPercentage% achieved',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInfoColumn(
                      'Monthly',
                      'JOD ${monthlyAmount.toStringAsFixed(2)}',
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey[300]),
                  Expanded(
                    child: _buildInfoColumn(
                      'Remaining',
                      'JOD ${(targetAmount - currentAmount).toStringAsFixed(2)}',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
