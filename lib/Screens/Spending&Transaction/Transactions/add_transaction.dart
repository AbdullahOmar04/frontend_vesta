import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/account_balance.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/Transactions/transaction_models.dart';
import 'package:frontend_vesta/Screens/pages/accounts.dart';

/// The prototype's "Add a transaction" sheet: paste a bank SMS, or type the
/// transaction in by hand.
Future<void> showAddTransactionSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _AddTransactionSheet(),
  );
}

// The sheet's tabs, in the prototype's order: (label, icon)
const _tabs = [
  ('SMS', PhosphorIconsRegular.chatText),
  ('Manual', PhosphorIconsRegular.pencilSimpleLine),
];
const _smsTab = 0;
const _manualTab = 1;

class _AddTransactionSheet extends StatefulWidget {
  const _AddTransactionSheet();

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  final _amountCtrl = TextEditingController();
  final _merchantCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  // SMS paste controller
  final _smsCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  int _tab = _manualTab;
  String? _smsError;
  bool _fromSms = false;

  List<Map<String, dynamic>> _accounts = [];
  List<String> _categories = [];

  String? _selectedAccountId;
  String? _selectedCategory;
  TransactionType _type = TransactionType.debit;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAccountsAndCategories();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _merchantCtrl.dispose();
    _noteCtrl.dispose();
    _smsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAccountsAndCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final uid = user.uid;
      final fire = FirebaseFirestore.instance;

      // Accounts
      final accountsSnap = await fire
          .collection('users')
          .doc(uid)
          .collection('accounts')
          .where('linked', isEqualTo: true)
          .get();

      final accounts = accountsSnap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'name': data['accountName'] ?? d.id,
          'type': data['accountTypeName'],
        };
      }).toList();

      // Categories
      final categoriesSnap = await fire
          .collection('users')
          .doc(uid)
          .collection('categories')
          .get();

      final categories = categoriesSnap.docs.map((d) => d.id).toList();

      if (mounted) {
        setState(() {
          _accounts = accounts;
          _categories = categories;
          if (_accounts.isNotEmpty) {
            _selectedAccountId = _accounts.first['id'] as String;
          }
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("⚠️ Error loading accounts/categories: $e");
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final messenger = ScaffoldMessenger.of(context);

    final rawAmount = _amountCtrl.text.trim();
    final amount = double.tryParse(rawAmount);

    if (amount == null || amount <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Enter a valid amount.")),
      );
      return;
    }

    if (_selectedAccountId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Select an account.")),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final fire = FirebaseFirestore.instance;

      final newDoc = fire
          .collection('users')
          .doc(uid)
          .collection('accounts')
          .doc(_selectedAccountId)
          .collection('transactions')
          .doc();

      final txn = TransactionModel.manual(
        firestoreAccountId: _selectedAccountId!,
        id: newDoc.id,
        amount: amount,
        currency: "JOD",
        type: _type,
        date: _date,
        merchantName: _merchantCtrl.text.trim().isEmpty
            ? null
            : _merchantCtrl.text.trim(),
        description: _noteCtrl.text.trim().isEmpty
            ? null
            : _noteCtrl.text.trim(),
        accountLabel: null,
        category: _selectedCategory,
      );

      await saveTransactionAndApplyBalance(
        uid: uid,
        accountId: _selectedAccountId!,
        txn: txn,
      );
      await calcTotalBalance();

      if (mounted) {
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(content: Text("Transaction added.")),
        );
      }
    } catch (e) {
      debugPrint("⚠️ Error saving transaction: $e");
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ============ SMS PASTE FEATURE ============

  /// A message in the format [_fillFromSms] reads, dated yesterday.
  String _sampleSms() {
    final d = DateTime.now().subtract(const Duration(days: 1));
    String two(int n) => n.toString().padLeft(2, '0');
    return 'A purchase transaction from Corner Market amount JOD 18.750 was '
        'made with your card ending 7754 on '
        '${two(d.day)}/${two(d.month)}/${d.year} 14:05.';
  }

  void _readSms() {
    final smsText = _smsCtrl.text.trim();
    if (smsText.isEmpty) return;
    if (!_fillFromSms(smsText)) {
      setState(() {
        _smsError =
            "We couldn't find an amount in this message. Try the Manual tab.";
      });
      return;
    }
    setState(() {
      _smsError = null;
      _fromSms = true;
      _tab = _manualTab;
    });
  }

  /// Fills the manual fields from [sms]. False when no amount was found, in
  /// which case nothing is changed.
  bool _fillFromSms(String sms) {
    final lower = sms.toLowerCase();

    final amountMatch = RegExp(
      r'JOD\s+(\d+(\.\d+)?)',
      caseSensitive: false,
    ).firstMatch(sms);
    if (amountMatch == null) return false;
    _amountCtrl.text = amountMatch.group(1)!; // "3.000"

    final merchantMatch = RegExp(
      r'from\s+(.+?)\s+amount',
      caseSensitive: false,
    ).firstMatch(sms);
    if (merchantMatch != null) {
      _merchantCtrl.text = merchantMatch.group(1)!.trim();
    }

    // 3) Date & time: "on 16/11/2025 18:32"
    final dateMatch = RegExp(
      r'on\s+(\d{2}/\d{2}/\d{4})\s+(\d{2}:\d{2})',
      caseSensitive: false,
    ).firstMatch(sms);

    DateTime? parsedDate;
    if (dateMatch != null) {
      final dateStr = dateMatch.group(1)!; // dd/MM/yyyy
      final timeStr = dateMatch.group(2)!; // HH:mm

      final dParts = dateStr.split('/');
      final tParts = timeStr.split(':');

      try {
        final day = int.parse(dParts[0]);
        final month = int.parse(dParts[1]);
        final year = int.parse(dParts[2]);
        final hour = int.parse(tParts[0]);
        final minute = int.parse(tParts[1]);

        parsedDate = DateTime(year, month, day, hour, minute);
      } catch (_) {}
    }

    // 4) Type: "purchase transaction" => debit
    TransactionType guessedType = TransactionType.debit;
    if (lower.contains("received") ||
        (lower.contains("credit") && !lower.contains("credit card"))) {
      guessedType = TransactionType.credit;
    }

    setState(() {
      _type = guessedType;
      if (parsedDate != null) {
        _date = parsedDate;
      }
    });
    return true;
  }

  // ============ UI ============

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          VestaSpace.gutter,
          0,
          VestaSpace.gutter,
          VestaSpace.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Add a transaction', style: headingStyle(20)),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(PhosphorIconsRegular.x, color: v.muted),
                ),
              ],
            ),
            const SizedBox(height: VestaSpace.md),
            _TabSwitch(
              selected: _tab,
              onSelect: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: VestaSpace.lg),
            if (_loading)
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_tab == _smsTab)
              _buildSmsTab()
            else
              _buildManualTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSmsTab() {
    final v = context.vesta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Paste your bank SMS',
          style: TextStyle(fontSize: 12, color: v.muted),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _smsCtrl,
          minLines: 4,
          maxLines: 6,
          onChanged: (_) => setState(() => _smsError = null),
          decoration: const InputDecoration(
            hintText:
                'e.g. A purchase from Corner Market amount JOD 18.750 on '
                '21/10/2026 14:05',
          ),
        ),
        const SizedBox(height: VestaSpace.md),
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => setState(() {
              _smsCtrl.text = _sampleSms();
              _smsError = null;
            }),
            child: Text(
              'Try a sample message',
              style: TextStyle(fontSize: 12, color: v.accentInk),
            ),
          ),
        ),
        if (_smsError != null) ...[
          const SizedBox(height: VestaSpace.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(PhosphorIconsRegular.warningCircle, size: 15, color: v.neg),
              const SizedBox(width: VestaSpace.sm),
              Expanded(
                child: Text(
                  _smsError!,
                  style: TextStyle(fontSize: 12, color: v.neg),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: VestaSpace.md),
        PrimaryButton(
          label: 'Read message',
          onPressed: _smsCtrl.text.trim().isEmpty ? null : _readSms,
        ),
        const SizedBox(height: VestaSpace.md),
        Text(
          "We'll fill in the details so you can check them before saving.",
          style: TextStyle(fontSize: 12, color: v.muted),
        ),
      ],
    );
  }

  Widget _buildManualTab() {
    const gap = SizedBox(height: 14);
    final v = context.vesta;
    final bodyLarge = Theme.of(context).textTheme.bodyLarge;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_fromSms) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: v.tint,
              borderRadius: BorderRadius.circular(VestaRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIconsRegular.checkCircle,
                  size: 15,
                  color: v.tintText,
                ),
                const SizedBox(width: VestaSpace.sm),
                Expanded(
                  child: Text(
                    'Filled from your SMS. Check the details below.',
                    style: TextStyle(fontSize: 12, color: v.tintText),
                  ),
                ),
              ],
            ),
          ),
          gap,
        ],

        // Account
        if (_accounts.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: _selectedAccountId,
            style: bodyLarge,
            decoration: const InputDecoration(labelText: "Account"),
            items: _accounts
                .map(
                  (a) => DropdownMenuItem(
                    value: a['id'] as String,
                    child: Text(
                      a['type'] is String && (a['type'] as String).isNotEmpty
                          ? "${a['name']} · ${a['type']}"
                          : a['name'] as String,
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              setState(() => _selectedAccountId = val);
            },
          )
        else
          Text(
            "No accounts yet. Add one in Wallet first.",
            style: TextStyle(color: v.neg),
          ),
        gap,

        // Amount
        TextField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: "Amount"),
        ),
        gap,

        // Type
        Row(
          children: [
            ChoiceTag(
              label: "Expense",
              icon: PhosphorIconsRegular.arrowUpRight,
              selected: _type == TransactionType.debit,
              onTap: () {
                setState(() => _type = TransactionType.debit);
              },
            ),
            const SizedBox(width: VestaSpace.sm),
            ChoiceTag(
              label: "Income",
              icon: PhosphorIconsRegular.arrowDownLeft,
              selected: _type == TransactionType.credit,
              onTap: () {
                setState(() => _type = TransactionType.credit);
              },
            ),
          ],
        ),
        gap,

        // Date
        InkWell(
          borderRadius: BorderRadius.circular(VestaRadius.md),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _date.isAfter(DateTime.now())
                  ? DateTime.now()
                  : _date,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              final now = DateTime.now();
              setState(() {
                _date = DateTime(
                  picked.year,
                  picked.month,
                  picked.day,
                  now.hour,
                  now.minute,
                );
              });
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: "Date",
              suffixIcon: Icon(
                PhosphorIconsRegular.calendarBlank,
                color: v.accentInk,
              ),
            ),
            child: Text(
              "${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}",
              style: bodyLarge,
            ),
          ),
        ),
        gap,

        // Merchant
        TextField(
          controller: _merchantCtrl,
          decoration: const InputDecoration(labelText: "Merchant / From"),
        ),
        gap,

        // Category
        if (_categories.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            style: bodyLarge,
            decoration: const InputDecoration(labelText: "Category"),
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (val) {
              setState(() => _selectedCategory = val);
            },
          ),
        if (_categories.isNotEmpty) gap,

        // Note
        TextField(
          controller: _noteCtrl,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(labelText: "Note (optional)"),
        ),
        const SizedBox(height: VestaSpace.xl),

        PrimaryButton(
          label: 'Add transaction',
          loading: _saving,
          onPressed: () {
            if (!_saving) {
              _save();
            }
          },
        ),
      ],
    );
  }
}

/// The prototype's icon tabs: a sunken track with the chosen tab raised.
class _TabSwitch extends StatelessWidget {
  const _TabSwitch({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: Tooltip(
                message: _tabs[i].$1,
                child: InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: i == selected
                          ? theme.colorScheme.surfaceContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      _tabs[i].$2,
                      size: 20,
                      color: i == selected
                          ? theme.colorScheme.onSurface
                          : v.muted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
