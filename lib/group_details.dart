import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jointventureapp/donatepage.dart';

class GroupDetailsPage extends StatelessWidget {
  final String username; // The username of the currently logged-in user

  const GroupDetailsPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlantis-UgarSoft'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groupinfo')
            .where('groupmembers', arrayContains: username)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No groups found.'));
          }

          final groups = snapshot.data!.docs;

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index].data() as Map<String, dynamic>;
              final groupName = group['groupname'] ?? 'Unknown';
              final groupCreator =
                  group['username'] ?? ''; // Group creator's username
              final groupMembers = group['groupmembers']
                  as List<dynamic>?; // Safely cast to List<dynamic> or null
              final numberOfMembers =
                  groupMembers?.length.toString() ?? '0'; // If null, set to '0'
              final typeOfGroup = group['typeOfGroup'] ?? 'Not specified';

              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          groupName,
                          style: const TextStyle(fontSize: 25),
                        ),
                      ),
                      const SizedBox(
                          width: 8.0), // Spacer between text and buttons
                      if (typeOfGroup != 'Not monetary') ...[
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to DonatePage with groupname
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => DonatePage(
                                  groupname: groupName, // Pass groupname
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue, // Blue background
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8.0), // Rounded corners
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                          ),
                          child: const Text('Contribute'),
                        ),
                        const SizedBox(width: 8.0),
                      ],
                      // Conditionally display the "Add" button only if the user is the creator
                      if (groupCreator == username)
                        ElevatedButton(
                          onPressed: () => _showAddMemberDialog(context,
                              groupName, groupMembers, numberOfMembers),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue, // Blue background
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8.0), // Rounded corners
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                          ),
                          child: const Text('Add'),
                        ),
                    ],
                  ),
                  subtitle: typeOfGroup == 'Not monetary'
                      ? null
                      : Text('Number of Members: $numberOfMembers'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, String groupName,
      List<dynamic>? groupMembers, String numberOfMembers) {
    final TextEditingController usernameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Member'),
          content: TextField(
            controller: usernameController,
            decoration: const InputDecoration(
              labelText: 'Enter username',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                final newUsername = usernameController.text.trim();
                //_addMember(context, newUsername, groupName, groupMembers);
                //print(groupMembers);
                addMee(context, newUsername, groupName, groupMembers,
                    numberOfMembers);
              },
            ),
          ],
        );
      },
    );
  }

  void addMee(BuildContext context, String newUsername, String groupName,
      List<dynamic>? groupMembers, String numberOfMembers) async {
    try {
      final usersCollection =
          FirebaseFirestore.instance.collection('jointventureuserdata');
      final groupCollection =
          FirebaseFirestore.instance.collection('groupinfo');
      final userDoc =
          await usersCollection.where('username', isEqualTo: newUsername).get();
      final firstDoc = userDoc.docs.first;

      if (firstDoc.exists) {
        print(firstDoc.exists);
        print('user found');
        final groupDoc = await groupCollection
            .where('groupname', isEqualTo: groupName)
            .get();
        final firstGroupDoc = groupDoc.docs.first;
        print(firstGroupDoc.exists);
      }
    } catch (e) {
      print(e);
      print('User not found');
      _showMessage(context, 'User not found');
      return;
    }

    // Update the groupmembers array
    final querySnapshot = await FirebaseFirestore.instance
        .collection('groupinfo')
        .where('groupname', isEqualTo: groupName)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      for (var doc in querySnapshot.docs) {
        final groupDocRef = doc.reference;
        List<dynamic> groupMembers = doc['groupmembers'];
        String numberOfMembers2 = doc['numberofmembers'];
        // compare grouMembers with numberOfMembers
        if (groupMembers.length == int.parse(numberOfMembers2)) {
          print(numberOfMembers2);
          print(groupMembers.length);
          _showMessage(context, 'Group is full');
        } else {
          if (groupMembers.contains(newUsername)) {
            print('Already a member');
            _showMessage(context, 'Already a member');
          } else {
            await groupDocRef.update({
              'groupmembers': FieldValue.arrayUnion([newUsername])
            });

            print('Member added successfully.');
            newUsername = '';
            _showMessage(context, 'Member added successfully');
          }
        }
      }
    } else {
      print('No document found with groupname = $groupName');
    }
  }

  void _showMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}










































/*import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jointventureapp/donatepage.dart';

class GroupDetailsPage extends StatelessWidget {
  final String username; // The username of the currently logged-in user

  const GroupDetailsPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlantis-UgarSoft'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groupinfo')
            .where('username', isEqualTo: username)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No groups found.'));
          }

          final groups = snapshot.data!.docs;

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index].data() as Map<String, dynamic>;
              final groupName = group['groupname'] ?? 'Unknown';
              final groupCreator =
                  group['username'] ?? ''; // Group creator's username
              final groupMembers = group['groupmembers']
                  as List<dynamic>?; // Safely cast to List<dynamic> or null
              final numberOfMembers =
                  groupMembers?.length.toString() ?? '0'; // If null, set to '0'
              final typeOfGroup = group['typeOfGroup'] ?? 'Not specified';

              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          groupName,
                          style: const TextStyle(fontSize: 25),
                        ),
                      ),
                      const SizedBox(
                          width: 8.0), // Spacer between text and buttons
                      if (typeOfGroup != 'Not monetary') ...[
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to DonatePage with groupname
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => DonatePage(
                                  groupname: groupName, // Pass groupname
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue, // Blue background
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8.0), // Rounded corners
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                          ),
                          child: const Text('Contribute'),
                        ),
                        const SizedBox(width: 8.0),
                      ],
                      // Conditionally display the "Add" button
                      if (groupCreator == username)
                        ElevatedButton(
                          onPressed: () => _showAddMemberDialog(
                              context, groupName, groupMembers),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue, // Blue background
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8.0), // Rounded corners
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                          ),
                          child: const Text('Add'),
                        ),
                    ],
                  ),
                  subtitle: typeOfGroup == 'Not monetary'
                      ? null
                      : Text('Number of Members: $numberOfMembers'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddMemberDialog(
      BuildContext context, String groupName, List<dynamic>? groupMembers) {
    final TextEditingController usernameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Member'),
          content: TextField(
            controller: usernameController,
            decoration: const InputDecoration(
              labelText: 'Enter username',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                final newUsername = usernameController.text.trim();
                //_addMember(context, newUsername, groupName, groupMembers);
                //print(groupMembers);
                addMee(context, newUsername, groupName, groupMembers);
              },
            ),
          ],
        );
      },
    );
  }

  void addMee(BuildContext context, String newUsername, String groupName,
      List<dynamic>? groupMembers) async {
    // print(groupName);
    print(groupMembers);
    try {
      final usersCollection =
          FirebaseFirestore.instance.collection('jointventureuserdata');
      final groupCollection =
          FirebaseFirestore.instance.collection('groupinfo');
      final userDoc =
          await usersCollection.where('username', isEqualTo: newUsername).get();
      final firstDoc = userDoc.docs.first;

      if (firstDoc.exists) {
        print(firstDoc.exists);
        print('user found');
        final groupDoc = await groupCollection
            .where('groupname', isEqualTo: groupName)
            .get();
        final firstGroupDoc = groupDoc.docs.first;
        print(firstGroupDoc.exists);
      }
    } catch (e) {
      print(e);
      print('User not found');
      _showMessage(context, 'User not found');
      return;
    }

    // for update
    // Step 1: Query the document(s) where 'groupname' matches the provided groupName
    final querySnapshot = await FirebaseFirestore.instance
        .collection('groupinfo')
        .where('groupname', isEqualTo: groupName)
        .get();

// Step 2: Check if any documents were found
    if (querySnapshot.docs.isNotEmpty) {
      // Step 3: Iterate over the matching documents (usually there should be one, but this handles multiple matches)
      for (var doc in querySnapshot.docs) {
        final groupDocRef = doc.reference; // Reference to the document

        // Step 4: Check if the new username is already in the groupmembers array
        List<dynamic> groupMembers = doc['groupmembers'];
        if (groupMembers.contains(newUsername)) {
          print('Already a member');
          _showMessage(context, 'Already a member');
        } else {
          print('Not a member. Adding new member.');

          // Step 5: Update the groupmembers field with the new username
          await groupDocRef.update({
            'groupmembers': FieldValue.arrayUnion([newUsername])
          });

          print('Member added successfully.');
          newUsername = '';
          _showMessage(context, 'Member added successfully');
        }
      }
    } else {
      // Handle the case where no matching document is found
      print('No document found with groupname = $groupName');
    }
  }

  void _showMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
*/