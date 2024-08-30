import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateGroup extends StatefulWidget {
  final String username;

  const CreateGroup({super.key, required this.username});

  @override
  _CreateGroupState createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _membersController = TextEditingController();
  // final TextEditingController _maxmembersController = TextEditingController();
  final TextEditingController _walletAddressController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? _selectedType;
  String? _selectedCurrency;
  bool _showLoader = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    _membersController.dispose();
    _walletAddressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submitGroup() async {
    final String groupName = _groupNameController.text;
    final String members = _membersController.text;
    // final String maxmembers = _maxmembersController.text;
    final String walletAddress = _walletAddressController.text;
    final String amount = _amountController.text;

    // Validate fields
    if (groupName.isEmpty) {
      _showSnackBar('Group name cannot be empty.');
      return;
    }

    if (int.tryParse(members) == null || int.parse(members) < 2) {
      _showSnackBar('Number of members must be at least 2.');
      return;
    }

    /* if (_selectedType == 'Raise fund' &&
        (walletAddress.length < 26 || walletAddress.length > 35)) {
      _showSnackBar(
          'Invalid address. Address must be between 26 and 35 characters.');
      return;
    }*/

    if (_selectedType == 'Raise fund' && int.tryParse(amount) == null) {
      _showSnackBar('Amount must be a valid number.');
      return;
    }

    setState(() {
      _showLoader = true;
    });

    try {
      final groupInfoCollection =
          FirebaseFirestore.instance.collection('groupinfo');

      // Check for duplicate group name
      final existingGroup = await groupInfoCollection
          .where('groupname', isEqualTo: groupName)
          .get();

      if (existingGroup.docs.isNotEmpty) {
        _showSnackBar('Group name already taken.');
        return;
      }

      // Add group info to Firestore
      await groupInfoCollection.add({
        'groupname': groupName,
        'typeOfGroup': _selectedType,
        'currency': _selectedCurrency,
        'amount': _selectedCurrency == null ? null : int.tryParse(amount),
        'walletAddress': _selectedType == 'Raise fund' ? walletAddress : null,
        'username': widget.username,
        'groupmembers': [widget.username],
        'numberofmembers': members
      });

      // Clear fields after submission
      _groupNameController.clear();
      _membersController.clear();
      _walletAddressController.clear();
      _amountController.clear();
      setState(() {
        _selectedType = null;
        _selectedCurrency = null;
      });

      _showSnackBar('Group created successfully.');
    } catch (e) {
      _showSnackBar('Error creating group: $e');
    } finally {
      setState(() {
        _showLoader = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _groupNameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedType = newValue;
                      if (_selectedType != 'Raise fund') {
                        _walletAddressController.clear();
                        _amountController.clear();
                        _selectedCurrency = null;
                      }
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Type of Group',
                    border: OutlineInputBorder(),
                  ),
                  items: <String>['Raise fund', 'Not monetary']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                if (_selectedType == 'Raise fund') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCurrency = newValue;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Currency',
                      border: OutlineInputBorder(),
                    ),
                    items: <String>['Naira', 'USDT', 'RWA'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: _selectedCurrency != null
                          ? 'Enter amount in $_selectedCurrency'
                          : 'Amount',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  /* const SizedBox(height: 16),
                  TextField(
                    controller: _walletAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Wallet Address',
                      border: OutlineInputBorder(),
                    ),
                  ),*/
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: int.tryParse(_membersController.text) ?? 2,
                  onChanged: (int? newValue) {
                    setState(() {
                      _membersController.text = newValue.toString();
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Number of Members',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(1000, (index) => index + 2)
                      .map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value'),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitGroup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Submit',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showLoader)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}



















/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateGroup extends StatefulWidget {
  final String username;

  const CreateGroup({super.key, required this.username});

  @override
  _CreateGroupState createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _membersController = TextEditingController();
  final TextEditingController _walletAddressController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? _selectedType;
  String? _selectedCurrency;
  bool _showLoader = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    _membersController.dispose();
    _walletAddressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submitGroup() async {
    final String groupName = _groupNameController.text;
    final String members = _membersController.text;
    final String walletAddress = _walletAddressController.text;
    final String amount = _amountController.text;

    // Validate fields
    if (groupName.isEmpty) {
      _showSnackBar('Group name cannot be empty.');
      return;
    }

    if (int.tryParse(members) == null || int.parse(members) < 2) {
      _showSnackBar('Number of members must be at least 2.');
      return;
    }

    if (_selectedType == 'Raise fund' &&
        (walletAddress.length < 26 || walletAddress.length > 35)) {
      _showSnackBar(
          'Invalid address. Address must be between 26 and 35 characters.');
      return;
    }

    if (_selectedType == 'Raise fund' && int.tryParse(amount) == null) {
      _showSnackBar('Amount must be a valid number.');
      return;
    }

    setState(() {
      _showLoader = true;
    });

    try {
      final groupInfoCollection =
          FirebaseFirestore.instance.collection('groupinfo');

      // Check for duplicate group name
      final existingGroup = await groupInfoCollection
          .where('groupname', isEqualTo: groupName)
          .get();

      if (existingGroup.docs.isNotEmpty) {
        _showSnackBar('Group name already taken.');
        return;
      }

      // Add group info to Firestore
      await groupInfoCollection.add({
        'groupname': groupName,
        'typeOfGroup': _selectedType,
        'currency': _selectedCurrency,
        'amount': _selectedCurrency == null ? null : int.tryParse(amount),
        'walletAddress': _selectedType == 'Raise fund' ? walletAddress : null,
        'username': widget.username,
        'groupmembers': [widget.username]
      });

      // Clear fields after submission
      _groupNameController.clear();
      _membersController.clear();
      _walletAddressController.clear();
      _amountController.clear();
      setState(() {
        _selectedType = null;
        _selectedCurrency = null;
      });

      _showSnackBar('Group created successfully.');
    } catch (e) {
      _showSnackBar('Error creating group: $e');
    } finally {
      setState(() {
        _showLoader = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _groupNameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedType = newValue;
                      if (_selectedType != 'Raise fund') {
                        _walletAddressController.clear();
                        _amountController.clear();
                        _selectedCurrency = null;
                      }
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Type of Group',
                    border: OutlineInputBorder(),
                  ),
                  items: <String>['Raise fund', 'Not monetary']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                if (_selectedType == 'Raise fund') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCurrency = newValue;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Currency',
                      border: OutlineInputBorder(),
                    ),
                    items: <String>['Naira', 'USDT', 'RWA'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: _selectedCurrency != null
                          ? 'Enter amount in $_selectedCurrency'
                          : 'Amount',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _walletAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Wallet Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: int.tryParse(_membersController.text) ?? 2,
                  onChanged: (int? newValue) {
                    setState(() {
                      _membersController.text = newValue.toString();
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Number of Members',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(1000, (index) => index + 2)
                      .map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value'),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitGroup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Submit',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showLoader)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}*/
