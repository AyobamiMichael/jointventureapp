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
  String walletAddress = 'wallet address not available';

  @override
  void initState() {
    super.initState();
    _fetchWalletAddress();
    print(widget.username);
  }

  Future<void> _fetchWalletAddress() async {
    final walletDoc = await FirebaseFirestore.instance
        .collection('walletcreationcollection')
        .doc('your-doc-id') // Replace with your actual document ID
        .get();

    if (walletDoc.exists) {
      setState(() {
        walletAddress = walletDoc['walletaddress']?.isNotEmpty == true
            ? walletDoc['walletaddress']
            : 'wallet address not available';
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

    // Set default values if they are not available
    final sharingFormular = '';
    final sharingTime = '';
    final walletAddr =
        walletAddress == 'wallet address not available' ? '' : walletAddress;
    final username = 'your-username'; // Replace with the actual username

    try {
      // Add a new document with the provided data
      await FirebaseFirestore.instance
          .collection('walletcreationcollection')
          .add({
        'jointpassword': FieldValue.arrayUnion([jointPassword]),
        'walletaddress': walletAddr,
        'sharingformular': sharingFormular,
        'sharingtime': sharingTime,
        'username': FieldValue.arrayUnion([username]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallet data submitted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting data: $e')),
      );
    }
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
                child: Text(walletAddress),
              ),
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
            ElevatedButton(
              onPressed: _submitWalletData,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
