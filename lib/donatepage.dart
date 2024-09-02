import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DonatePage extends StatefulWidget {
  final String groupname;

  const DonatePage({super.key, required this.groupname});

  @override
  _DonatePageState createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _walletaddressController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _currency;
  String? _walletAddress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGroupInfo();
  }

  Future<void> _fetchGroupInfo() async {
    try {
      final groupInfoCollection =
          FirebaseFirestore.instance.collection('groupinfo');
      final querySnapshot = await groupInfoCollection
          .where('groupname', isEqualTo: widget.groupname)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        setState(() {
          _currency = data['currency'];
          _walletAddress = data['walletAddress'];
          _isLoading = false;
          _walletaddressController.text = _walletAddress ?? '';
        });
      } else {
        // Handle case where no group is found
        setState(() {
          _currency = 'N/A';
          _walletAddress = 'N/A';
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error
      setState(() {
        _currency = 'Error';
        _walletAddress = 'Error';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _walletaddressController.dispose();
    super.dispose();
  }

  void _submitDonation() {
    if (_formKey.currentState?.validate() ?? false) {
      final amount = _amountController.text;

      // Handle donation logic here

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donation submitted!')),
      );
    }
  }

  String? _validateCryptoAddress(String? value) {
    // Add your crypto wallet address validation logic here
    if (value == null || value.isEmpty) {
      return 'Please enter the wallet address.';
    }
    if (!RegExp(r'^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$').hasMatch(value)) {
      return 'Please enter a valid crypto wallet address.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donate'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display currency type in a SizedBox with border
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        'Currency Type: $_currency',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Wallet address text box with validation
                  TextFormField(
                    controller: _walletaddressController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Wallet Address',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateCryptoAddress,
                  ),
                  const SizedBox(height: 16),

                  // Amount text box with validation
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Amount',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount.';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitDonation,
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

class DonatePage extends StatefulWidget {
  final String groupname;

  const DonatePage({super.key, required this.groupname});

  @override
  _DonatePageState createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _walletaddressController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _currency;
  String? _walletAddress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGroupInfo();
  }

  Future<void> _fetchGroupInfo() async {
    try {
      final groupInfoCollection =
          FirebaseFirestore.instance.collection('groupinfo');
      final querySnapshot = await groupInfoCollection
          .where('groupname', isEqualTo: widget.groupname)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        setState(() {
          _currency = data['currency'];
          _walletAddress = data['walletAddress'];
          _isLoading = false;
        });
      } else {
        // Handle case where no group is found
        setState(() {
          _currency = 'N/A';
          _walletAddress = 'N/A';
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error
      setState(() {
        _currency = 'Error';
        _walletAddress = 'Error';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submitDonation() {
    if (_formKey.currentState?.validate() ?? false) {
      final amount = _amountController.text;

      // Handle donation logic here

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donation submitted!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donate'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display wallet address in a SizedBox with border
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _walletaddressController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Wallet Address',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the group wallet address.';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid wallet address.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Display currency type in a SizedBox with border
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        'Currency Type: $_currency',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Text box for entering amount with validation
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Amount',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount.';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitDonation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Submit Donation',
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