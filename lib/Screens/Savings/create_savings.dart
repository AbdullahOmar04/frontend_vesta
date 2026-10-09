// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';

/// Emoji in a tinted rounded square, used for goals.
class _GoalEmoji extends StatelessWidget {
  const _GoalEmoji(this.emoji, {this.size = 40});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.vesta.tint,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

class CreateSavings extends StatefulWidget {
  const CreateSavings({super.key});

  @override
  State<CreateSavings> createState() => _CreateSavingsState();
}

class _CreateSavingsState extends State<CreateSavings> {
  final List<Map<String, dynamic>> _savingsGoals = [
    {'title': 'New Car', 'emoji': '🚗'},
    {'title': 'Vacation', 'emoji': '🏝️'},
    {'title': 'House', 'emoji': '🏠'},
    {'title': 'Emergency Fund', 'emoji': '🆘'},
  ];

  void _onGoalTap(Map<String, dynamic> goal) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavingsGoalDetails(
          goalTitle: goal['title'],
          emoji: goal['emoji'],
        ),
      ),
    );

    if (result == true && mounted) {
      // Go back to SavingsPage which will show the success snackbar
      Navigator.pop(context, true);
    }
  }

  void _addNewGoal() {
    showDialog(
      context: context,
      builder: (context) => _CustomGoalDialog(
        onGoalCreated: (title, emoji) {
          setState(() {
            _savingsGoals.add({'title': title, 'emoji': emoji});
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VestaAppBar(title: 'New savings goal'),
      body: VestaBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VestaSpace.gutter,
            VestaSpace.xs,
            VestaSpace.gutter,
            VestaSpace.xl,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: VestaSpace.md),
              child: Text(
                'Pick what you are saving for.',
                style: TextStyle(fontSize: 13, color: context.vesta.muted),
              ),
            ),
            VestaCard(
              padding: const EdgeInsets.symmetric(
                horizontal: VestaSpace.lg,
                vertical: 4,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < _savingsGoals.length; i++)
                    _buildGoalCard(_savingsGoals[i], first: i == 0),
                ],
              ),
            ),
            const SizedBox(height: VestaSpace.lg),
            _buildAddNewGoalButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal, {required bool first}) {
    final v = context.vesta;
    return InkWell(
      onTap: () => _onGoalTap(goal),
      child: Container(
        decoration: BoxDecoration(
          border: first ? null : Border(top: BorderSide(color: v.divider)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _GoalEmoji(goal['emoji']),
            const SizedBox(width: VestaSpace.md),
            Expanded(child: Text(goal['title'])),
            Icon(PhosphorIconsRegular.caretRight, size: 16, color: v.muted),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewGoalButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _addNewGoal,
        icon: const Icon(PhosphorIconsRegular.plus, size: 18),
        label: const Text('Custom goal'),
      ),
    );
  }
}

////////////////////////////////

class _CustomGoalDialog extends StatefulWidget {
  final Function(String title, String emoji) onGoalCreated;

  const _CustomGoalDialog({required this.onGoalCreated});

  @override
  State<_CustomGoalDialog> createState() => _CustomGoalDialogState();
}

class _CustomGoalDialogState extends State<_CustomGoalDialog> {
  final _titleController = TextEditingController();
  String _selectedEmoji = '💰';

  final List<String> _emojis = [
    '💰',
    '🎓',
    '💍',
    '🎮',
    '📱',
    '💻',
    '🎸',
    '⚽',
    '🎨',
    '📚',
    '🏖️',
    '✈️',
    '🏥',
    '👶',
    '🐕',
    '🎁'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _createGoal() {
    if (_titleController.text.trim().isEmpty) {
      // Get the parent scaffold messenger to show snackbar on the right screen
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final errorColor = Theme.of(context).colorScheme.error;
      Navigator.pop(context);
      scaffoldMessenger.clearSnackBars();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Please enter a goal title'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    widget.onGoalCreated(_titleController.text.trim(), _selectedEmoji);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final scheme = Theme.of(context).colorScheme;

    return VestaDialog(
      title: 'Custom goal',
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Goal title',
                  hintText: 'e.g., Wedding, Gadget, etc.',
                ),
              ),
              const SizedBox(height: VestaSpace.lg),
              Text('Icon', style: TextStyle(fontSize: 12, color: v.muted)),
              const SizedBox(height: VestaSpace.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final emoji in _emojis)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedEmoji = emoji;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: emoji == _selectedEmoji
                              ? v.tint
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: emoji == _selectedEmoji
                                ? scheme.primary
                                : v.divider,
                          ),
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      confirmLabel: 'Create',
      onConfirm: _createGoal,
    );
  }
}

////////////////////////////////

class SavingsGoalDetails extends StatefulWidget {
  final String goalTitle;
  final String emoji;

  const SavingsGoalDetails({
    super.key,
    required this.goalTitle,
    required this.emoji,
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
    final errorColor = Theme.of(context).colorScheme.error;

    if (targetAmount == null || targetAmount <= 0) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid target amount'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    if (months == null || months <= 0) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid duration'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    if (monthlyAmount == null || monthlyAmount <= 0) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid monthly amount'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User not logged in'),
          backgroundColor: errorColor,
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
        // Pop first, then show snackbar (it will appear on the previous screen)
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating goal: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    const gap = SizedBox(height: VestaSpace.lg);
    final amountFormatter = FilteringTextInputFormatter.allow(
      RegExp(r'^\d+\.?\d{0,2}'),
    );

    return Scaffold(
      appBar: VestaAppBar(title: widget.goalTitle),
      body: VestaBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            VestaSpace.gutter,
            VestaSpace.sm,
            VestaSpace.gutter,
            VestaSpace.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Goal Icon
              Center(child: _GoalEmoji(widget.emoji, size: 72)),
              const SizedBox(height: VestaSpace.xl),

              // Target Amount
              TextField(
                controller: _targetAmountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [amountFormatter],
                decoration: const InputDecoration(
                  labelText: 'Target amount',
                  prefixText: 'JOD ',
                ),
                onChanged: (value) {
                  setState(() {
                    if (_isCalculatingFromMonths) {
                      _calculateMonthlyAmount();
                    } else {
                      _calculateMonths();
                    }
                  });
                },
              ),
              gap,

              // Duration Toggle
              Text(
                'Plan it by',
                style: TextStyle(fontSize: 12, color: v.muted),
              ),
              const SizedBox(height: VestaSpace.sm),
              Row(
                children: [
                  ChoiceTag(
                    label: 'Duration',
                    icon: PhosphorIconsRegular.calendarBlank,
                    selected: _isCalculatingFromMonths,
                    onTap: () {
                      setState(() {
                        _isCalculatingFromMonths = true;
                      });
                      // Automatically recalculate when switching modes
                      _calculateMonthlyAmount();
                    },
                  ),
                  const SizedBox(width: VestaSpace.sm),
                  ChoiceTag(
                    label: 'Monthly amount',
                    icon: PhosphorIconsRegular.coins,
                    selected: !_isCalculatingFromMonths,
                    onTap: () {
                      setState(() {
                        _isCalculatingFromMonths = false;
                      });
                      // Automatically recalculate when switching modes
                      _calculateMonths();
                    },
                  ),
                ],
              ),
              gap,

              // Duration Field
              TextField(
                controller: _monthsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: _isCalculatingFromMonths,
                decoration: InputDecoration(
                  labelText: 'Duration',
                  suffixText: 'months',
                  fillColor: _isCalculatingFromMonths ? null : v.raised,
                ),
                onChanged: (value) {
                  setState(() {
                    if (_isCalculatingFromMonths) {
                      _calculateMonthlyAmount();
                    }
                  });
                },
              ),
              if (_monthsController.text.isNotEmpty &&
                  int.tryParse(_monthsController.text) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    '≈ ${_convertMonthsToYearsAndMonths(int.parse(_monthsController.text))}',
                    style: TextStyle(fontSize: 12, color: v.muted),
                  ),
                ),
              gap,

              // Monthly Amount Field
              TextField(
                controller: _monthlyAmountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [amountFormatter],
                enabled: !_isCalculatingFromMonths,
                decoration: InputDecoration(
                  labelText: 'Monthly savings',
                  prefixText: 'JOD ',
                  fillColor: !_isCalculatingFromMonths ? null : v.raised,
                ),
                onChanged: (value) {
                  setState(() {
                    if (!_isCalculatingFromMonths) {
                      _calculateMonths();
                    }
                  });
                },
              ),
              const SizedBox(height: VestaSpace.xl),

              // Summary Card
              if (_targetAmountController.text.isNotEmpty &&
                  _monthsController.text.isNotEmpty &&
                  _monthlyAmountController.text.isNotEmpty) ...[
                VestaCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Summary', style: headingStyle(16)),
                      const SizedBox(height: VestaSpace.md),
                      _buildSummaryRow(
                        'Goal',
                        'JOD ${double.parse(_targetAmountController.text).toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: VestaSpace.sm),
                      _buildSummaryRow(
                        'Duration',
                        _convertMonthsToYearsAndMonths(
                          int.parse(_monthsController.text),
                        ),
                      ),
                      const SizedBox(height: VestaSpace.sm),
                      _buildSummaryRow(
                        'Monthly savings',
                        'JOD ${double.parse(_monthlyAmountController.text).toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: VestaSpace.xl),
              ],

              // Create Button
              PrimaryButton(
                label: 'Create savings goal',
                onPressed: _saveSavingGoal,
              ),
            ],
          ),
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
          style: TextStyle(fontSize: 13, color: context.vesta.muted),
        ),
        Text(value, style: amountStyle(14)),
      ],
    );
  }
}
