import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/ui.dart';

class CreateHousehold extends StatefulWidget {
  const CreateHousehold({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CreateHouseholdState createState() => _CreateHouseholdState();
}

class _CreateHouseholdState extends State<CreateHousehold> {
  final _householdNameController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _householdNameController.dispose();
    super.dispose();
  }

  Future<void> _createHousehold() async {
    final householdName = _householdNameController.text.trim();
    if (householdName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter a household name"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("No user logged in.");
      }
      final uid = currentUser.uid;
      final db = FirebaseFirestore.instance;

      final householdRef = db.collection('households').doc();
      final userRef = db.collection('users').doc(uid);

      WriteBatch batch = db.batch();

      batch.set(householdRef, {
        'householdName': householdName,
        'createdBy': uid,
        'members': [uid],
        'createdAt': FieldValue.serverTimestamp(),
        'budget': 0,
      });

      batch.update(userRef, {
        'householdIds': FieldValue.arrayUnion([householdRef.id]),
      });

      // 5. Commit the batch
      await batch.commit();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error creating household: $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VestaAppBar(title: 'New household'),
      body: VestaBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VestaSpace.gutter,
            VestaSpace.md,
            VestaSpace.gutter,
            VestaSpace.xl,
          ),
          children: [
            TextField(
              controller: _householdNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Household name',
                hintText: 'e.g. Home, Flat 3B',
              ),
            ),
            const SizedBox(height: VestaSpace.sm),
            Text(
              'You can invite the people you live with once it is created.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: VestaSpace.xl),
            PrimaryButton(
              label: 'Create household',
              loading: _isCreating,
              onPressed: () {
                if (!_isCreating) {
                  _createHousehold();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
