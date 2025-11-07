import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateHousehold extends StatefulWidget {
  const CreateHousehold({super.key});

  @override
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
        const SnackBar(
          content: Text("Please enter a household name"),
          backgroundColor: Colors.red,
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
      });

      batch.update(userRef, {
        'householdIds': FieldValue.arrayUnion([householdRef.id])
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
            backgroundColor: Colors.red,
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
      appBar: AppBar(
        title: const Text('Create Household'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _householdNameController,
              decoration: const InputDecoration(
                labelText: 'Household Name',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isCreating ? null : _createHousehold,
              child: _isCreating
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
