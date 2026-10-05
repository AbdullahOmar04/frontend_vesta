import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/pages/accounts.dart';

/// Account types offered when adding an account by hand. The codes match what
/// the budgeting screen looks for, so a savings account still feeds the
/// "total savings" figure.
const Map<String, String> accountTypeCodes = {
  'Current': 'CUR.IND',
  'Savings': 'SAV.IND',
  'Cash': 'CASH.IND',
};

class AddAccountPage extends StatefulWidget {
  const AddAccountPage({super.key});

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController(text: '0');
  final _currencyCtrl = TextEditingController(text: 'JOD');

  String _type = 'Current';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      final name = _nameCtrl.text.trim();
      final currency = _currencyCtrl.text.trim().toUpperCase();
      final balance = double.parse(_balanceCtrl.text.trim());

      final accounts = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('accounts');
      final doc = accounts.doc('manual_${accounts.doc().id}');

      await doc.set({
        'accountId': doc.id,
        'accountName': name,
        // the accounts page uses bankName as the card title
        'bankName': name,
        'accountTypeName': _type,
        'accountTypeCode': accountTypeCodes[_type],
        'balanceAmount': balance,
        'currency': currency,
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
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Account added')));
    } catch (e) {
      debugPrint('⚠️ Error adding account: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VestaAppBar(title: 'Add account'),
      body: VestaBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            VestaSpace.gutter,
            VestaSpace.md,
            VestaSpace.gutter,
            VestaSpace.xl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Account name',
                    hintText: 'e.g. Arab Bank, Cash, Wallet',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter an account name'
                      : null,
                ),
                const SizedBox(height: VestaSpace.lg),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: accountTypeCodes.keys
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v ?? 'Current'),
                ),
                const SizedBox(height: VestaSpace.lg),
                TextFormField(
                  controller: _currencyCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Currency'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter a currency'
                      : null,
                ),
                const SizedBox(height: VestaSpace.lg),
                TextFormField(
                  controller: _balanceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Current balance',
                  ),
                  validator: (v) {
                    final parsed = double.tryParse((v ?? '').trim());
                    if (parsed == null) return 'Enter a number';
                    return null;
                  },
                ),
                const SizedBox(height: VestaSpace.sm),
                Text(
                  'Transactions you add will be added to or taken off this balance.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Add account',
                  onPressed: _save,
                  loading: _saving,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
