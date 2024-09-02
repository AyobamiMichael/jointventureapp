import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Walletaddresspage extends StatefulWidget {
  final String username;
  const Walletaddresspage({super.key, required this.username});

  @override
  _WalletaddresspageState createState() => _WalletaddresspageState();
}

class _WalletaddresspageState extends State<Walletaddresspage> {
  String? _selectedGroupName;
  final List<String> _groupNames = [];
  String walletAddressMessage = 'Wallet Address Not Available';
  String walletAddress = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    print(widget.username);
    checkGroups();
  }

  Future<void> _fetchWalletAddress(String groupName) async {
    setState(() {
      isLoading = true;
    });

    final walletDoc = await FirebaseFirestore.instance
        .collection('premetaskwalletcollection')
        .where('groupname', isEqualTo: groupName)
        .get();

    walletAddress = '';
    for (var groupWalletDoc in walletDoc.docs) {
      walletAddress = groupWalletDoc['walletaddress'].toString();
    }

    setState(() {
      walletAddressMessage = walletAddress.isNotEmpty
          ? walletAddress
          : 'Wallet Address Not Available';
      isLoading = false;
    });
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
    if (_selectedGroupName != null) {
      await _fetchWalletAddress(_selectedGroupName!);
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
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SelectableText(
                        walletAddressMessage,
                        style: const TextStyle(fontSize: 16),
                      ),
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


/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Walletaddresspage extends StatefulWidget {
  final String username;
  const Walletaddresspage({super.key, required this.username});

  @override
  _WalletaddresspageState createState() => _WalletaddresspageState();
}

class _WalletaddresspageState extends State<Walletaddresspage> {
  String? _selectedGroupName;
  final List<String> _groupNames = [];
  String walletAddressMessage = 'Wallet Address Not Available';
  String walletAddress = '';

  @override
  void initState() {
    super.initState();

    print(widget.username);
    checkGroups();
  }

  Future<void> _fetchWalletAddress(String groupName) async {
    final walletDoc = await FirebaseFirestore.instance
        .collection('premetaskwalletcollection')
        .where('groupname', isEqualTo: groupName)
        .get();

    print(groupName);
    for (var groupWalletDoc in walletDoc.docs) {
      walletAddress = groupWalletDoc['walletaddress'].toString();
    }
    print(walletAddress);
    if (walletAddress.isNotEmpty) {
      setState(() {
        walletAddressMessage = walletAddress;
      });
    } else {
      walletAddressMessage = walletAddressMessage;
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
    _fetchWalletAddress(_selectedGroupName!);
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
                child: SelectableText(
                  walletAddressMessage,
                  style: const TextStyle(fontSize: 16),
                ),
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
*/