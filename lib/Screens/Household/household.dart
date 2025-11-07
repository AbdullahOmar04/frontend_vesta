import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend_vesta/Screens/Household/create_household.dart'; // Assuming you have this
import 'package:share_plus/share_plus.dart';

// This is the detail page
class HouseholdDetailPage extends StatefulWidget {
  final String householdId;

  const HouseholdDetailPage({super.key, required this.householdId});

  @override
  State<HouseholdDetailPage> createState() => _HouseholdDetailPageState();
}

class _HouseholdDetailPageState extends State<HouseholdDetailPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // This is your default Firebase Hosting domain
  final String _appDomain = "https://vesta-7e96a.web.app";

  Future<void> _createAndShareInviteLink() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      // --- FIX 1: Get household name ---
      // 1. Get the household name *before* creating the invite
      final householdDoc = await _db
          .collection('households')
          .doc(widget.householdId)
          .get();
      final householdName =
          householdDoc.data()?['householdName'] ?? 'a household';
      // ---------------------------------

      // 2. Create the secure invite document in Firestore
      final inviteDoc = await _db.collection('invites').add({
        'householdId': widget.householdId,
        'inviterUid': user.uid,
        'inviterName': user.displayName ?? user.email,
        'householdName': householdName, // <-- ADDED THIS FIELD
        'status': 'pending', // Will be 'accepted' or 'expired'
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Create the deep link URL string
      final String inviteLink = "$_appDomain/join?inviteId=${inviteDoc.id}";

      // 4. Use the Share API from share_plus
      await SharePlus.instance.share(
        ShareParams(
          text:
              "Join my household '$householdName' on Vesta! Click the link: $inviteLink",
          subject: "You're invited to join my household on Vesta!",
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error creating invite: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primary,

      appBar: AppBar(
        backgroundColor: scheme.primary,
        iconTheme: IconThemeData(color: scheme.surface),
        title: Text(
          "Household Details",
          style: TextStyle(color: scheme.surface),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_alt_1),
            onPressed: _createAndShareInviteLink,
            tooltip: "Invite Member",
          ),
        ],
      ),
      // StreamBuilder to show household info and members
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _db
              .collection('households')
              .doc(widget.householdId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text("Household not found."));
            }

            final householdData = snapshot.data!.data()!;
            final List<String> memberUids = List<String>.from(
              householdData['members'] ?? [],
            );

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    householdData['householdName'] ?? 'Unnamed Household',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: 24),
                  Text(
                    "Members (${memberUids.length})",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  // This will show the list of members
                  Expanded(child: _buildMembersList(memberUids)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper widget to fetch and display user info for each member UID
  Widget _buildMembersList(List<String> memberUids) {
    if (memberUids.isEmpty) {
      return Center(child: Text("No members found."));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // We fetch all user documents where the ID is in our members list
      stream: _db
          .collection('users')
          .where(
            FieldPath.documentId,
            whereIn: memberUids.isNotEmpty ? memberUids : ['_'],
          ) // 'whereIn' cannot be empty
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final userDocs = userSnapshot.data!.docs;

        return ListView.builder(
          itemCount: userDocs.length,
          itemBuilder: (context, index) {
            final userData = userDocs[index].data();
            return ListTile(
              leading: Icon(Icons.person),
              title: Text(userData['username'] ?? 'No Name'),
              subtitle: Text(userData['email'] ?? 'No Email'),
            );
          },
        );
      },
    );
  }
}

// This is the main household list/manager page
class HouseholdPage extends StatefulWidget {
  const HouseholdPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HouseholdPageState createState() => _HouseholdPageState();
}

class _HouseholdPageState extends State<HouseholdPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Icon(Icons.house_sharp, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No Households Found",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Create a household to start managing your budget together.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateHousehold()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text("Create Household"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseholdList(List<String> householdIds) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('households')
          .where(FieldPath.documentId, whereIn: householdIds)
          .snapshots(),
      builder: (context, householdSnapshot) {
        if (householdSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (householdSnapshot.hasError) {
          return Center(child: Text("Error: ${householdSnapshot.error}"));
        }
        if (!householdSnapshot.hasData ||
            householdSnapshot.data!.docs.isEmpty) {
          return Center(child: Text("Could not find households."));
        }

        final householdDocs = householdSnapshot.data!.docs;

        return ListView.builder(
          itemCount: householdDocs.length,
          itemBuilder: (context, index) {
            final household = householdDocs[index].data();
            final householdId = householdDocs[index].id;

            return ListTile(
              leading: Icon(Icons.house_outlined),
              title: Text(household['householdName'] ?? 'Unnamed Household'),
              subtitle: Text(household['live_text'] ?? 'Tap to open'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        HouseholdDetailPage(householdId: householdId),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;
    final scheme = Theme.of(context).colorScheme;

    // Handle user not being logged in
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Households")),
        body: Center(child: Text("Please log in to see your households.")),
      );
    }

    // --- FIX 3: Get UID after null check ---
    final String uid = currentUser.uid;

    return Scaffold(
      backgroundColor: scheme.primary,
      appBar: AppBar(
        centerTitle: true,
        title: Text('Households', style: TextStyle(color: scheme.surface)),
        iconTheme: IconThemeData(color: scheme.surface),
        backgroundColor: scheme.primary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateHousehold()),
          );
        },
        child: Icon(Icons.add),
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          // 1. OUTER STREAM: Listens to the user's document
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _db
                .collection('users')
                .doc(uid)
                .snapshots(), // Use safe uid
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (userSnapshot.hasError) {
                return Center(child: Text("Error: ${userSnapshot.error}"));
              }
              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return Center(child: Text("User data not found."));
              }

              final userData = userSnapshot.data!.data();
              // This is the correct way to get the array
              final List<String> householdIds = List<String>.from(
                userData?['householdIds'] ?? [],
              );

              // HERE IS YOUR LOGIC
              if (householdIds.isEmpty) {
                return _buildEmptyState();
              } else {
                return _buildHouseholdList(householdIds);
              }
            },
          ),
        ),
      ),
    );
  }
}
