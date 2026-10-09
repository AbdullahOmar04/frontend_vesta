import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/icons.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/pages/accounts.dart';

/// Account types offered when adding an account by hand: (label, code, debt).
/// The codes match what the budgeting screen looks for, so a savings account
/// still feeds the "total savings" figure. Debt balances are stored negative.
const _accountTypes = [
  ('Current account', 'CUR.IND', false),
  ('Savings account', 'SAV.IND', false),
  ('Credit card', 'CC.IND', true),
  ('Loan', 'LOAN.IND', true),
  ('Investment account', 'INV.IND', false),
  ('Cash', 'CASH.IND', false),
];

/// The "Add account manually" sheet from the prototype.
Future<void> showAddAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _AddAccountSheet(),
  );
}

class _AddAccountSheet extends StatefulWidget {
  const _AddAccountSheet();

  @override
  State<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<_AddAccountSheet> {
  final _nameCtrl = TextEditingController();
  final _maskCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();

  String _bank = jordanBanks.first;
  int _type = 0;
  bool _saving = false;
  String? _error;

  bool get _isCash => _accountTypes[_type].$1 == 'Cash';
  bool get _isDebt => _accountTypes[_type].$3;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _maskCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final amount = double.tryParse(_balanceCtrl.text.trim().isEmpty
        ? '0'
        : _balanceCtrl.text.trim());
    if (amount == null) {
      setState(() => _error = 'Enter the balance as a number');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final (typeName, typeCode, debt) = _accountTypes[_type];
      final bankName = _isCash ? 'Cash' : _bank;
      final typed = _nameCtrl.text.trim();
      final mask = _maskCtrl.text.trim();

      final accounts = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('accounts');
      final doc = accounts.doc('manual_${accounts.doc().id}');

      await doc.set({
        'accountId': doc.id,
        // Lists label an account "name · type", so default to the bank
        'accountName': typed.isEmpty ? bankName : typed,
        'bankName': bankName,
        'accountTypeName': typeName,
        'accountTypeCode': typeCode,
        'balanceAmount': debt ? -amount.abs() : amount,
        'currency': 'JOD',
        if (mask.isNotEmpty) 'mask': mask,
        // linked drives every list in the app; a manual account is always "linked"
        'linked': true,
        'linkedAt': FieldValue.serverTimestamp(),
        'provider': 'Manual',
        'source': 'manual',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'linkedAccountIds': FieldValue.arrayUnion([doc.id]),
      }, SetOptions(merge: true));

      await calcTotalBalance();

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Account added')));
    } catch (e) {
      debugPrint('⚠️ Error adding account: $e');
      if (mounted) {
        setState(() {
          _saving = false;
          _error = "Couldn't add the account: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                  child: Text('Add account manually', style: headingStyle(20)),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(PhosphorIconsRegular.x, color: v.muted),
                ),
              ],
            ),
            const SizedBox(height: VestaSpace.md),
            if (!_isCash) ...[
              DropdownButtonFormField<String>(
                initialValue: _bank,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Bank'),
                items: [
                  for (final b in jordanBanks)
                    DropdownMenuItem(
                      value: b,
                      child: Text(b, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (b) => setState(() => _bank = b ?? _bank),
              ),
              const SizedBox(height: 14),
            ],
            DropdownButtonFormField<int>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Account type'),
              items: [
                for (var i = 0; i < _accountTypes.length; i++)
                  DropdownMenuItem(value: i, child: Text(_accountTypes[i].$1)),
              ],
              onChanged: (i) => setState(() => _type = i ?? _type),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameCtrl,
              maxLength: 30,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Account name',
                hintText: 'e.g. Salary account',
                counterText: '',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _maskCtrl,
                    enabled: !_isCash,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Last 4 digits',
                      hintText: 'Optional',
                    ),
                  ),
                ),
                const SizedBox(width: VestaSpace.md),
                Expanded(
                  child: TextField(
                    controller: _balanceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: _isDebt ? 'Amount owed' : 'Current balance',
                      prefixText: 'JOD ',
                      hintText: '0.00',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: VestaSpace.lg),
            Container(
              padding: const EdgeInsets.all(VestaSpace.md),
              decoration: BoxDecoration(
                color: v.raised,
                borderRadius: BorderRadius.circular(VestaRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(PhosphorIconsRegular.info, size: 16, color: v.accentInk),
                  const SizedBox(width: VestaSpace.sm),
                  Expanded(
                    child: Text(
                      "Manual accounts don't sync. You'll add transactions and "
                      'update the balance yourself.',
                      style: TextStyle(fontSize: 12, color: v.muted),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: VestaSpace.sm),
              Text(_error!, style: TextStyle(fontSize: 12, color: v.neg)),
            ],
            const SizedBox(height: VestaSpace.lg),
            Row(
              children: [
                Expanded(
                  child: OutlineButton(
                    label: 'Cancel',
                    onPressed: _saving ? null : () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: 'Add account',
                    loading: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
