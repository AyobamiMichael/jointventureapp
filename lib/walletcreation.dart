import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WalletCreationPage extends StatefulWidget {
  final String username;
  const WalletCreationPage({super.key, required this.username});

  @override
  _WalletCreationPageState createState() => _WalletCreationPageState();
}

class _WalletCreationPageState extends State<WalletCreationPage> {
  final TextEditingController _jointPasswordController =
      TextEditingController();
  // String walletAddress = 'wallet address not available';
  String? _selectedGroupName;
  final List<String> _groupNames = [];
  final List<String> _userNames = [];
  String walletAddressMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchWalletAddress();
    print(widget.username);
    checkGroups();
  }

  Future<void> _fetchWalletAddress() async {
    final walletDoc = await FirebaseFirestore.instance
        .collection('walletcreationcollection')
        .doc('your-doc-id') // Replace with your actual document ID
        .get();

    if (walletDoc.exists) {
      setState(() {
        walletAddressMessage = walletDoc['walletaddress']?.isNotEmpty == true
            ? walletDoc['walletaddress']
            : walletAddressMessage;
      });
    }
  }

  void checkGroups() async {
    final groupCollection = FirebaseFirestore.instance.collection('groupinfo');
    QuerySnapshot groupQuerySnapshot = await groupCollection
        .where('groupmembers', arrayContains: widget.username)
        .get();
    for (var groupDoc in groupQuerySnapshot.docs) {
      setState(() {
        _groupNames.add(groupDoc['groupname']);
      });
    }
  }

  Future<void> _submitWalletData() async {
    final jointPassword = _jointPasswordController.text.trim();

    if (jointPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a joint password')),
      );
      return;
    }
    // check if the password is ready for the wallet
    checkForJointPasswordsComplete();

    // Set default values if they are not available
    final sharingFormular = '';
    final sharingTime = '';
    //  final walletAddr =
    //    walletAddress == walletAddressMessage ? '' : walletAddress;
    final username = widget.username; // Replace with the actual
    String verifyUserName = '';

    final groupWalletCollection =
        FirebaseFirestore.instance.collection('walletcreationcollection');
    QuerySnapshot groupQuerySnapshot = await groupWalletCollection
        .where('username', arrayContains: widget.username)
        .get();
    for (var groupWalletDoc in groupQuerySnapshot.docs) {
      verifyUserName = groupWalletDoc['username'].toString();
    }

    final collectionSnapshot = await groupWalletCollection.limit(1).get();
    if (collectionSnapshot.docs.isNotEmpty) {
      print('Not Empty');
      print(verifyUserName.contains(username));
      if (verifyUserName.contains(username)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already created a password')),
        );
      } else {
        // Update the password list with the new password
        final querySnapshot = await FirebaseFirestore.instance
            .collection('walletcreationcollection')
            .where('groupname', isEqualTo: _selectedGroupName)
            .get();

        for (var doc in querySnapshot.docs) {
          final groupDocRef = doc.reference;
          await groupDocRef.update({
            'jointpassword': FieldValue.arrayUnion([jointPassword]),
            'username': FieldValue.arrayUnion([username])
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallet data submitted successfully')),
        );
      }
    } else {
      try {
        // Add a new document with the provided data

        await FirebaseFirestore.instance
            .collection('walletcreationcollection')
            .add({
          'jointpassword': FieldValue.arrayUnion([jointPassword]),
          'sharingformular': sharingFormular,
          'sharingtime': sharingTime,
          'username': FieldValue.arrayUnion([username]),
          'groupname': _selectedGroupName
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallet data submitted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          // SnackBar(content: Text('Error submitting data: $e')),
          const SnackBar(
              content:
                  Text('Error submitting data, Ensure you belong to a group')),
        );
      }
    }
  }

  void checkForJointPasswordsComplete() async {
    // Checking for time to create wallet for the group
    String numberOfGroupMembers = '';
    List<dynamic> listOfJointPasswords = [];

    final querySnapshotForNumberOfMembers = await FirebaseFirestore.instance
        .collection('groupinfo')
        .where('groupname', isEqualTo: _selectedGroupName)
        .get();
    final querySnapshotForNumberOfJointPasswords = await FirebaseFirestore
        .instance
        .collection('walletcreationcollection')
        .where('groupname', isEqualTo: _selectedGroupName)
        .get();

    for (var groupDoc in querySnapshotForNumberOfJointPasswords.docs) {
      listOfJointPasswords = groupDoc['jointpassword'];
    }

    for (var groupDoc in querySnapshotForNumberOfMembers.docs) {
      numberOfGroupMembers = groupDoc['numberofmembers'].toString();
    }

    if (listOfJointPasswords.length == int.parse(numberOfGroupMembers)) {
      createGroupMetaMaskWallet(listOfJointPasswords, _selectedGroupName!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group Wallet successfully created')),
      );
    } else {
      print('Wallet Address not ready, Joint Password Not completed');
      walletAddressMessage =
          "Joint Password Not completed, Wallet Address not ready";
    }
  }

  String _encryptPassword(String password) {
    // Convert password to bytes
    final bytes = utf8.encode(password);

    // Encrypt password using SHA256
    final digest = sha256.convert(bytes);

    // Convert digest to string
    return digest.toString();
  }

  void createGroupMetaMaskWallet(
      List<dynamic> listOfJointPasswords, String groupName) async {
    // if this numberOfGroupMembers is equall to the number of jointpasswords create wallet
    // message your wallet is ready now
    String randomWalletAddress = generateRandomWalletAddress();
    final encryptedPassword = _encryptPassword(listOfJointPasswords.join());
    print('Generated Wallet Address: $randomWalletAddress');

    await FirebaseFirestore.instance
        .collection('premetaskwalletcollection')
        .add({
      'groupname': groupName,
      'walletaddress': randomWalletAddress,
      'grouppassword': encryptedPassword,
    });
  }

  String generateRandomWalletAddress() {
    const String chars =
        '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    final Random random = Random.secure();
    final int addressLength = 34; // Typical length for a Bitcoin address

    return List.generate(
        addressLength, (index) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Creation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wallet Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(walletAddressMessage),
              ),
            ),
            const SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
              value: _selectedGroupName,
              items: _groupNames.map((name) {
                return DropdownMenuItem<String>(
                  value: name,
                  child: Text(name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGroupName = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a group';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Enter Joint Password',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _jointPasswordController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter joint password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitWalletData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
