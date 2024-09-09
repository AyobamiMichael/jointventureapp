import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WeightedVotingPage extends StatefulWidget {
  final String username;

  const WeightedVotingPage({Key? key, required this.username})
      : super(key: key);

  @override
  _WeightedVotingPageState createState() => _WeightedVotingPageState();
}

class _WeightedVotingPageState extends State<WeightedVotingPage> {
  String? _selectedGroupName;
  List<String> _groupNames = [];
  bool _isLoading = false;

  // TextEditingControllers for the percentage ranges
  TextEditingController _controller0To10 = TextEditingController();
  TextEditingController _controller10To20 = TextEditingController();
  TextEditingController _controller20To30 = TextEditingController();
  TextEditingController _controller30To40 = TextEditingController();
  TextEditingController _controller40To50 = TextEditingController();
  TextEditingController _controller50To60 = TextEditingController();
  TextEditingController _controller60To70 = TextEditingController();
  TextEditingController _controller70To80 = TextEditingController();
  TextEditingController _controller80To90 = TextEditingController();
  TextEditingController _controller90To100 = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchGroupNames();
  }

  // Fetch group names for dropdown
  Future<void> _fetchGroupNames() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final groupCollection =
          FirebaseFirestore.instance.collection('groupinfo');
      final groupQuerySnapshot = await groupCollection
          .where('groupmembers', arrayContains: widget.username)
          .get();

      List<String> groupNames = groupQuerySnapshot.docs.map((doc) {
        return doc['groupname'] as String;
      }).toList();

      setState(() {
        _groupNames = groupNames;
      });
    } catch (e) {
      print('Error fetching group names: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch poll data
  Future<Map<String, dynamic>?> _fetchPollData(String groupname) async {
    final groupCollection = FirebaseFirestore.instance.collection('groupinfo');
    final weightedVotingCollection =
        FirebaseFirestore.instance.collection('weightedvotingcollection');

    try {
      final groupQuerySnapshot = await groupCollection
          .where('groupname', isEqualTo: groupname)
          .where('groupmembers', arrayContains: widget.username)
          .get();

      for (var groupDoc in groupQuerySnapshot.docs) {
        String groupName = groupDoc['groupname'];

        QuerySnapshot pollQuerySnapshot = await weightedVotingCollection
            .where('groupname', isEqualTo: groupName)
            .get();

        for (var pollDoc in pollQuerySnapshot.docs) {
          String pollDurationStr = pollDoc['pollDuration'];
          DateTime dateTimeNow = (pollDoc['dateTimeNow'] as Timestamp).toDate();
          DateTime expirationTime =
              (pollDoc['expirationTime'] as Timestamp).toDate();

          DateTime now = DateTime.now();
          if (now.isAfter(dateTimeNow) && now.isBefore(expirationTime)) {
            return {
              'pollName': pollDoc['pollName'],
              'option': pollDoc['option'],
              'dateTimeNow': dateTimeNow,
              'expirationTime': expirationTime,
              'username': pollDoc['username'],
              '0% - 10%': pollDoc['0% - 10%'],
              '10% - 20%': pollDoc['10% - 20%'],
              '20% - 30%': pollDoc['20% - 30%'],
              '30% - 40%': pollDoc['30% - 40%'],
              '40% - 50%': pollDoc['40% - 50%'],
              '50% - 60%': pollDoc['50% - 60%'],
              '60% - 70%': pollDoc['60% - 70%'],
              '70% - 80%': pollDoc['70% - 80%'],
              '80% - 90%': pollDoc['80% - 90%'],
              '90% - 100%': pollDoc['90% - 100%']
            };
          } else {
            print('Poll has expired or is not yet active.');
          }
        }
      }
    } catch (e) {
      print('Error fetching poll data: $e');
    }
    return null;
  }

  // Populate the controllers with the poll data
  void _populateControllers(Map<String, dynamic> pollData) {
    _controller0To10.text = pollData['0% - 10%'].toString();
    _controller10To20.text = pollData['10% - 20%'].toString();
    _controller20To30.text = pollData['20% - 30%'].toString();
    _controller30To40.text = pollData['30% - 40%'].toString();
    _controller40To50.text = pollData['40% - 50%'].toString();
    _controller50To60.text = pollData['50% - 60%'].toString();
    _controller60To70.text = pollData['60% - 70%'].toString();
    _controller70To80.text = pollData['70% - 80%'].toString();
    _controller80To90.text = pollData['80% - 90%'].toString();
    _controller90To100.text = pollData['90% - 100%'].toString();

    print(pollData['10% - 20%']);
  }

  // Widget to display percentage outputs
  Widget _buildPercentageOutput(
      String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: TextFormField(
              controller: controller,
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Vote Weight',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weighted Voting'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
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
                    onChanged: (value) async {
                      setState(() {
                        _selectedGroupName = value;
                      });

                      if (value != null) {
                        final pollData = await _fetchPollData(value);
                        if (pollData != null) {
                          _populateControllers(pollData);
                        }
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a group';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildPercentageOutput('0% - 10%', _controller0To10),
                  _buildPercentageOutput('10% - 20%', _controller10To20),
                  _buildPercentageOutput('20% - 30%', _controller20To30),
                  _buildPercentageOutput('30% - 40%', _controller30To40),
                  _buildPercentageOutput('40% - 50%', _controller40To50),
                  _buildPercentageOutput('50% - 60%', _controller50To60),
                  _buildPercentageOutput('60% - 70%', _controller60To70),
                  _buildPercentageOutput('70% - 80%', _controller70To80),
                  _buildPercentageOutput('80% - 90%', _controller80To90),
                  _buildPercentageOutput('90% - 100%', _controller90To100),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    // Dispose controllers when the widget is removed
    _controller0To10.dispose();
    _controller10To20.dispose();
    _controller20To30.dispose();
    _controller30To40.dispose();
    _controller40To50.dispose();
    _controller50To60.dispose();
    _controller60To70.dispose();
    _controller70To80.dispose();
    _controller80To90.dispose();
    _controller90To100.dispose();
    super.dispose();
  }
}










































/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Weightedvotingpage extends StatefulWidget {
  final String username;

  const Weightedvotingpage({super.key, required this.username});

  @override
  _WeightedvotingpageState createState() => _WeightedvotingpageState();
}

class _WeightedvotingpageState extends State<Weightedvotingpage> {
  final _formKey = GlobalKey<FormState>();
  // Controllers for the text fields
  final TextEditingController _controller0to10 = TextEditingController();
  final TextEditingController _controller10to20 = TextEditingController();
  final TextEditingController _controller20to30 = TextEditingController();
  final TextEditingController _controller30to40 = TextEditingController();
  final TextEditingController _controller40to50 = TextEditingController();
  final TextEditingController _controller50to60 = TextEditingController();
  final TextEditingController _controller60to70 = TextEditingController();
  final TextEditingController _controller70to80 = TextEditingController();
  final TextEditingController _controller80to90 = TextEditingController();
  final TextEditingController _controller90to100 = TextEditingController();
  String? _selectedGroupName;
  final List<String> _groupNames = [];
  // String? _selectedDuration;
  bool _isLoading = false;
  // final List<String> _pollDurations = ['30 mins', '45 mins', '1 hour'];
  int theAmountOfMoney = 0;

  @override
  void initState() {
    super.initState();
    _loadGroupNames();
  }

  @override
  void dispose() {
    _controller0to10.dispose();
    _controller10to20.dispose();
    _controller20to30.dispose();
    _controller30to40.dispose();
    _controller40to50.dispose();
    _controller50to60.dispose();
    _controller60to70.dispose();
    _controller70to80.dispose();
    _controller80to90.dispose();
    _controller90to100.dispose();
    super.dispose();
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  int _parsePollDuration(String duration) {
    final match = RegExp(r'(\d+)').firstMatch(duration);
    return match != null
        ? int.parse(match.group(0)!) * 60
        : 0; // Assuming duration is in minutes
  }

  Future<void> _loadGroupNames() async {
    try {
      final groupCollection =
          FirebaseFirestore.instance.collection('groupinfo');

      QuerySnapshot groupQuerySnapshot = await groupCollection
          .where('groupmembers', arrayContains: widget.username)
          .get();
      for (var groupDoc in groupQuerySnapshot.docs) {
        setState(() {
          _groupNames.add(groupDoc['groupname']);
          theAmountOfMoney = groupDoc['amount'];
        });
      }
    } catch (e) {
      print('Error loading group names: $e');
    }
  }

  Future<Map<String, dynamic>?> _fetchPollData(String groupname) async {
    final groupCollection = FirebaseFirestore.instance.collection('groupinfo');
    final weightedVotingCollection =
        FirebaseFirestore.instance.collection('weightedvotingcollection');

    try {
      final groupQuerySnapshot = await groupCollection
          .where('groupname', isEqualTo: groupname)
          .where('groupmembers', arrayContains: widget.username)
          .get();

      // groupQuerySnapshot = await groupCollection
      //  .where('groupmembers', arrayContains: widget.username)
      //.get();

      for (var groupDoc in groupQuerySnapshot.docs) {
        String groupName = groupDoc['groupname'];

        QuerySnapshot pollQuerySnapshot = await weightedVotingCollection
            .where('groupname', isEqualTo: groupName)
            .get();

        for (var pollDoc in pollQuerySnapshot.docs) {
          String pollDurationStr = pollDoc['pollDuration'];
          DateTime dateTimeNow = (pollDoc['dateTimeNow'] as Timestamp).toDate();
          DateTime expirationTime =
              (pollDoc['expirationTime'] as Timestamp).toDate();

          DateTime now = DateTime.now();
          if (now.isAfter(dateTimeNow) && now.isBefore(expirationTime)) {
            int pollDurationInSeconds = _parsePollDuration(pollDurationStr);

            return {
              'pollName': pollDoc['pollName'],
              'option': pollDoc['option'],
              'dateTimeNow': dateTimeNow,
              'expirationTime': expirationTime,
              'username': pollDoc['username'],
              'pollDurationInSeconds': pollDurationInSeconds,
              '0% - 10%': pollDoc['0% - 10%'],
              '10% - 20%': pollDoc['10% - 20%'],
              '20% - 30%': pollDoc['20% - 30%'],
              '30% - 40%': pollDoc['30% - 40%'],
              '40% - 50%': pollDoc['40% - 50%'],
              '50% - 60%': pollDoc['50% - 60%'],
              '60% - 70%': pollDoc['60% - 70%'],
              '70% - 80%': pollDoc['70% - 80%'],
              '80% - 90%': pollDoc['80% - 90%'],
              '90% - 100%': pollDoc['90% - 100%']
            };
          } else {
            print('Poll has expired or is not yet active.');
          }
        }
      }
    } catch (e) {
      print('Error fetching user groups and polls: $e');
    }
    return null;
  }

  // Modal loader widget
  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weighted Voting Page'),
      ),
      body: Stack(
        children: [
          if (_isLoading) _buildLoadingIndicator(),
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
              _fetchPollData(_selectedGroupName!);

              
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a group';
              }
              return null;
            },
          ),
          // the data will load after the user has selected the groupname
          Opacity(
            opacity: _isLoading ? 0.3 : 1, // Dim background when loading
            child: AbsorbPointer(
              absorbing: _isLoading, // Disable interactions while loading
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildPercentageOutput('0% - 10%', _controller0to10),
                      _buildPercentageOutput('10% - 20%', _controller10to20),
                      _buildPercentageOutput('20% - 30%', _controller20to30),
                      _buildPercentageOutput('30% - 40%', _controller30to40),
                      _buildPercentageOutput('40% - 50%', _controller40to50),
                      _buildPercentageOutput('50% - 60%', _controller50to60),
                      _buildPercentageOutput('60% - 70%', _controller60to70),
                      _buildPercentageOutput('70% - 80%', _controller70to80),
                      _buildPercentageOutput('80% - 90%', _controller80to90),
                      _buildPercentageOutput('90% - 100%', _controller90to100),
                      const SizedBox(height: 16.0),
                      _buildButton('Yes', Colors.green, () {
                        // Add functionality for Vote button here
                      }),
                      _buildButton('No', Colors.green, () {
                        // Add functionality for Vote button here
                      }),
                      const SizedBox(height: 16.0),
                      _buildButton('Results', Colors.blue, () {
                        // Add functionality for Results button here
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Builds the input field with a label for each percentage range
  Widget _buildPercentageOutput(
      String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter Vote Weight',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a vote weight';
                }
                final parsedValue = int.tryParse(value);
                if (parsedValue == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  // Reusable function for building buttons
  Widget _buildButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity, // Stretch button across the full width
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 20, color: Colors.black),
        ),
      ),
    );
  }
}
*/