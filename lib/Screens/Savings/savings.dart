// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
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
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Savings goal created successfully!')),
      );
    }
  }

  /// Small tinted panel used inside the dialogs for the current figures.
  Widget _infoPanel(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VestaSpace.md),
      decoration: BoxDecoration(
        color: context.vesta.tint,
        borderRadius: BorderRadius.circular(VestaRadius.button),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  void _showAllocateBottomSheet(
    String goalId,
    Map<String, dynamic> goal,
  ) async {
    final amountController = TextEditingController();
    final goalTitle = goal['goalTitle'] ?? 'Goal';
    final currentAmount = (goal['currentAmount'] ?? 0).toDouble();
    final targetAmount = (goal['targetAmount'] ?? 0).toDouble();
    final remaining = (targetAmount - currentAmount) > 0
        ? (targetAmount - currentAmount)
        : 0.0;

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

    // Store the parent scaffold messenger to use after bottom sheet closes
    final parentScaffoldMessenger = ScaffoldMessenger.of(context);

    if (!mounted) return;

    final v = context.vesta;
    final errorColor = Theme.of(context).colorScheme.error;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Allocate to $goalTitle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoPanel([
              Text(
                'Available: ${formatMoney(available)}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: v.tintText,
                ),
              ),
              const SizedBox(height: VestaSpace.xs),
              Text(
                'In this goal: ${formatMoney(currentAmount)}',
                style: TextStyle(fontSize: 12, color: v.muted),
              ),
              Text(
                'Still needed: ${formatMoney(remaining)}',
                style: TextStyle(fontSize: 12, color: v.muted),
              ),
            ]),
            const SizedBox(height: VestaSpace.lg),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount to allocate',
                prefixText: 'JOD ',
              ),
              autofocus: true,
            ),
            const SizedBox(height: VestaSpace.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: currentAmount > 0
                    ? () {
                        Navigator.pop(dialogContext);
                        _showDeallocateDialog(goalId, goal);
                      }
                    : null,
                style: TextButton.styleFrom(foregroundColor: v.neg),
                child: const Text('Remove from goal'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                parentScaffoldMessenger.clearSnackBars();
                parentScaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: const Text('Please enter a valid amount'),
                    backgroundColor: errorColor,
                  ),
                );
                return;
              }

              if (amount > available) {
                parentScaffoldMessenger.clearSnackBars();
                parentScaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: const Text('Insufficient available balance'),
                    backgroundColor: errorColor,
                  ),
                );
                return;
              }

              if (remaining <= 0) {
                parentScaffoldMessenger.clearSnackBars();
                parentScaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('This goal is already fully funded'),
                  ),
                );
                return;
              }

              // Cap the amount to remaining if user tries to allocate more
              final actualAmount = amount > remaining ? remaining : amount;

              if (amount > remaining) {
                parentScaffoldMessenger.clearSnackBars();
                parentScaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Allocating JOD ${actualAmount.toStringAsFixed(2)} (capped to remaining goal amount)',
                    ),
                  ),
                );
              }

              Navigator.pop(dialogContext);
              _allocateToGoal(goalId, goal, actualAmount);
            },
            child: const Text('Allocate'),
          ),
        ],
      ),
    );
  }

  void _deleteSavingGoalDialog(String goalId) {
    // Store parent scaffold messenger before showing dialog
    final parentScaffoldMessenger = ScaffoldMessenger.of(context);
    final neg = context.vesta.neg;
    final errorColor = Theme.of(context).colorScheme.error;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete savings goal'),
        content: const Text(
          'Are you sure you want to delete this savings goal? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final userId = user?.uid;
              if (userId == null) return;

              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('savings')
                    .doc(goalId)
                    .delete();

                if (mounted) {
                  Navigator.pop(dialogContext);
                  parentScaffoldMessenger.clearSnackBars();
                  parentScaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Savings goal deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  parentScaffoldMessenger.clearSnackBars();
                  parentScaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error deleting goal: $e'),
                      backgroundColor: errorColor,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: neg),
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

    // Store parent scaffold messenger before showing dialog
    final parentScaffoldMessenger = ScaffoldMessenger.of(context);
    final v = context.vesta;
    final errorColor = Theme.of(context).colorScheme.error;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove from $goalTitle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoPanel([
              Text(
                'In this goal: ${formatMoney(currentAmount)}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: v.tintText,
                ),
              ),
            ]),
            const SizedBox(height: VestaSpace.lg),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount to remove',
                prefixText: 'JOD ',
              ),
              autofocus: true,
            ),
            const SizedBox(height: VestaSpace.sm),
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                parentScaffoldMessenger.clearSnackBars();
                parentScaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: const Text('Please enter a valid amount'),
                    backgroundColor: errorColor,
                  ),
                );
                return;
              }

              if (amount > currentAmount) {
                parentScaffoldMessenger.clearSnackBars();
                parentScaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: const Text('Amount exceeds current allocation'),
                    backgroundColor: errorColor,
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);
              _deallocateFromGoal(goalId, goal, amount);
            },
            style: TextButton.styleFrom(foregroundColor: v.neg),
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
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'JOD ${amount.toStringAsFixed(2)} allocated successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
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
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'JOD ${amount.toStringAsFixed(2)} removed successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          const PixelIcon(PixelArt.save, size: 72),
          const SizedBox(height: 14),
          Text("No savings goals yet", style: headingStyle(22)),
          const SizedBox(height: VestaSpace.sm),
          Text(
            "Create a goal and move money from your savings into it as you go.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.vesta.muted),
          ),
          const SizedBox(height: VestaSpace.xl),
          PrimaryButton(
            label: "Create a savings goal",
            onPressed: _navigateToCreateSavings,
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

    return Scaffold(
      appBar: VestaAppBar(
        title: 'Savings',
        actions: [
          HeaderButton(label: 'New goal', onPressed: _navigateToCreateSavings),
        ],
      ),
      body: VestaBackground(
        child: userId == null
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
                  final totalSavings = (userData["totalSavings"] ?? 0)
                      .toDouble();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      VestaSpace.gutter,
                      VestaSpace.xs,
                      VestaSpace.gutter,
                      VestaSpace.xl,
                    ),
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

                          return _buildTotalCard(
                            totalSavings,
                            totalAllocated,
                            unallocated,
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Savings Goals List
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("users")
                            .doc(userId)
                            .collection("savings")
                            .orderBy("createdAt", descending: true)
                            .snapshots(),
                        builder: (context, savingsSnapshot) {
                          if (savingsSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 32),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (!savingsSnapshot.hasData ||
                              savingsSnapshot.data!.docs.isEmpty) {
                            return _buildEmptyState();
                          }

                          final savingsGoals = savingsSnapshot.data!.docs;

                          return VestaCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SectionHeader(title: "Saving goals"),
                                const SizedBox(height: VestaSpace.xs),
                                for (var i = 0; i < savingsGoals.length; i++)
                                  _buildSavingsGoalCard(
                                    savingsGoals[i].data()
                                        as Map<String, dynamic>,
                                    savingsGoals[i].id,
                                    first: i == 0,
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildTotalCard(
    double totalSavings,
    double totalAllocated,
    double unallocated,
  ) {
    final v = context.vesta;
    return VestaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Total saved", style: TextStyle(fontSize: 12, color: v.muted)),
          const SizedBox(height: VestaSpace.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: MoneyText.hero(totalSavings, size: 30),
          ),
          const SizedBox(height: VestaSpace.md),
          const Divider(),
          const SizedBox(height: 10),
          _buildInfoRow("Allocated to goals", MoneyText(totalAllocated)),
          const SizedBox(height: 6),
          _buildInfoRow(
            "Left to allocate",
            MoneyText(unallocated, color: unallocated > 0 ? v.pos : v.neg),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, Widget value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: context.vesta.muted),
          ),
        ),
        value,
      ],
    );
  }

  Widget _buildSavingsGoalCard(
    Map<String, dynamic> goal,
    String goalId, {
    required bool first,
  }) {
    final v = context.vesta;
    final goalTitle = goal['goalTitle'] ?? 'Unknown';
    final emoji = goal['emoji'] ?? '💰';
    final targetAmount = (goal['targetAmount'] ?? 0).toDouble();
    final currentAmount = (goal['currentAmount'] ?? 0).toDouble();
    final durationMonths = goal['durationMonths'] ?? 0;
    final monthlyAmount = (goal['monthlyAmount'] ?? 0).toDouble();
    final isCompleted = goal['isCompleted'] ?? false;

    final rawProgress = targetAmount > 0 ? currentAmount / targetAmount : 0.0;
    final progress = rawProgress > 1.0 ? 1.0 : rawProgress; // Cap at 100%
    final progressPercentage = (rawProgress * 100).toStringAsFixed(0);

    return InkWell(
      onTap: () => _showAllocateBottomSheet(goalId, goal),
      onLongPress: () => {_deleteSavingGoalDialog(goalId)},
      child: Container(
        decoration: BoxDecoration(
          border: first ? null : Border(top: BorderSide(color: v.divider)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: v.raised,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: VestaSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          goalTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCompleted)
                        TagChip.pill(
                          'Completed',
                          icon: PhosphorIconsRegular.check,
                          color: v.pos,
                        )
                      else
                        Text(
                          '$progressPercentage%',
                          style: amountStyle(13),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  VestaProgressBar(
                    value: progress,
                    height: 4,
                    color: isCompleted ? v.pos : v.accentInk,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${formatMoney(currentAmount)} of ${formatMoney(targetAmount)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${formatMoney(monthlyAmount)} a month · ${_convertMonthsToYearsAndMonths(durationMonths)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: VestaSpace.sm),
            Icon(PhosphorIconsRegular.caretRight, size: 16, color: v.muted),
          ],
        ),
      ),
    );
  }
}
