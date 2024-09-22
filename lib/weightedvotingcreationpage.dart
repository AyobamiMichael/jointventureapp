import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jointventureapp/weightedvotingpage.dart';

class Weightedvotingcreationpage extends StatefulWidget {
  final String username;

  const Weightedvotingcreationpage({super.key, required this.username});

  @override
  _WeightedvotingcreationpageState createState() =>
      _WeightedvotingcreationpageState();
}

class _WeightedvotingcreationpageState
    extends State<Weightedvotingcreationpage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pollTitleController = TextEditingController();
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
  String? _selectedDuration;
  bool _isLoading = false;
  final List<String> _pollDurations = [
    '30 mins',
    '1 hour',
    '4 hours',
    '12 hours',
    '1 day',
    '2 days',
    '3 days',
    '7 days'
  ];
  int theAmountOfMoney = 0;

  @override
  void initState() {
    super.initState();
    _loadGroupNames();
  }

  @override
  void dispose() {
    _pollTitleController.dispose();
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

  Future<void> _submitPoll() async {
    final groupCollection = FirebaseFirestore.instance.collection('groupinfo');
    final weightedVotingCollection =
        FirebaseFirestore.instance.collection('weightedvotingcollection');
    String pending = '';
    if (theAmountOfMoney != 0) {
      if (_formKey.currentState!.validate() && _selectedGroupName != null) {
        setState(() {
          _isLoading = true;
        });

        try {
          QuerySnapshot existingPolls = await weightedVotingCollection
              .where('pollTitle', isEqualTo: _pollTitleController.text.trim())
              .get();
          if (existingPolls.docs.isNotEmpty) {
            _showMessage(context, 'Title already exists');
            return;
          }

          final groupQuerySnapshot = await groupCollection
              .where('groupname', isEqualTo: _selectedGroupName)
              .where('groupmembers', arrayContains: widget.username)
              .get();
          if (groupQuerySnapshot.docs.isNotEmpty) {
            for (var groupDoc in groupQuerySnapshot.docs) {
              String groupName = groupDoc['groupname'];

              QuerySnapshot pollQuerySnapshot = await weightedVotingCollection
                  .where('groupname', isEqualTo: groupName)
                  .orderBy('groupname', descending: false)
                  .get();

              for (var pollDoc in pollQuerySnapshot.docs) {
                DateTime expirationTime =
                    (pollDoc['expirationTime'] as Timestamp).toDate();

                DateTime now = DateTime.now();
                if (now.isBefore(expirationTime)) {
                  _showMessage(
                      context, 'Voting is ongoing, but it will be queued');

                  setState(() {
                    pending = 'yes';
                  });
                }
              }
            }
          }

          final now = DateTime.now();
          final expiration = _getExpirationTime(now, _selectedDuration!);

          final pollData = {
            'pollTitle': _pollTitleController.text.trim(),
            'pollDuration': _selectedDuration,
            'username': widget.username,
            'option': [],
            'dateTimeNow': now,
            'votedusers': [],
            'groupname': _selectedGroupName,
            'expirationTime': expiration,
            'pending': pending,
            '0% - 10%': _controller0to10.text,
            '10% - 20%': _controller10to20.text,
            '20% - 30%': _controller20to30.text,
            '30% - 40%': _controller30to40.text,
            '40% - 50%': _controller40to50.text,
            '50% - 60%': _controller50to60.text,
            '60% - 70%': _controller60to70.text,
            '70% - 80%': _controller70to80.text,
            '80% - 90%': _controller80to90.text,
            '90% - 100%': _controller90to100.text,
          };

          await weightedVotingCollection.add(pollData);

          _showMessage(context, 'Poll created successfully');

          _pollTitleController.clear();
          _controller0to10.clear();
          _controller10to20.clear();
          _controller20to30.clear();
          _controller30to40.clear();
          _controller40to50.clear();
          _controller50to60.clear();
          _controller60to70.clear();
          _controller70to80.clear();
          _controller80to90.clear();
          _controller90to100.clear();
          setState(() {
            _selectedDuration = null;
            _selectedGroupName = null;
          });
        } catch (e) {
          _showMessage(
              context, 'An error occurred while creating the poll: $e');
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      _showMessage(context, 'No amount for the weighted voting');
    }
  }

  DateTime _getExpirationTime(DateTime start, String duration) {
    switch (duration) {
      case '30 mins':
        return start.add(Duration(minutes: 30));
      case '1 hour':
        return start.add(Duration(hours: 1));
      case '4 hours':
        return start.add(Duration(hours: 4));
      case '12 hours':
        return start.add(Duration(hours: 12));
      case '1 day':
        return start.add(Duration(days: 1));
      case '2 days':
        return start.add(Duration(days: 2));
      case '3 days':
        return start.add(Duration(days: 3));
      case '7 days':
        return start.add(Duration(days: 7));
      default:
        return start;
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildPercentageInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a value';
          }
          return null;
        },
      ),
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
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          Opacity(
            opacity: _isLoading ? 0.3 : 1,
            child: AbsorbPointer(
              absorbing: _isLoading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildPercentageInput('0% - 10%', _controller0to10),
                      _buildPercentageInput('10% - 20%', _controller10to20),
                      _buildPercentageInput('20% - 30%', _controller20to30),
                      _buildPercentageInput('30% - 40%', _controller30to40),
                      _buildPercentageInput('40% - 50%', _controller40to50),
                      _buildPercentageInput('50% - 60%', _controller50to60),
                      _buildPercentageInput('60% - 70%', _controller60to70),
                      _buildPercentageInput('70% - 80%', _controller70to80),
                      _buildPercentageInput('80% - 90%', _controller80to90),
                      _buildPercentageInput('90% - 100%', _controller90to100),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Select Duration',
                        ),
                        value: _selectedDuration,
                        items: _pollDurations.map((String duration) {
                          return DropdownMenuItem<String>(
                            value: duration,
                            child: Text(duration),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedDuration = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a duration';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: _pollTitleController,
                        decoration: const InputDecoration(
                          labelText: 'Poll Title',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a poll title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Select Group',
                        ),
                        value: _selectedGroupName,
                        items: _groupNames.map((String groupName) {
                          return DropdownMenuItem<String>(
                            value: groupName,
                            child: Text(groupName),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedGroupName = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a group';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      _buildButton('Request', Colors.blue, _submitPoll),
                      const SizedBox(height: 16.0),
                      _buildButton('Vote', Colors.green, () {
                        // Add functionality for Vote button here

                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => WeightedVotingPage(
                                  username: widget.username)),
                        );
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




/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jointventureapp/weightedvotingpage.dart';

class Weightedvotingcreationpage extends StatefulWidget {
  final String username;

  const Weightedvotingcreationpage({super.key, required this.username});

  @override
  _WeightedvotingcreationpageState createState() =>
      _WeightedvotingcreationpageState();
}

class _WeightedvotingcreationpageState
    extends State<Weightedvotingcreationpage> {
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
  String? _selectedDuration;
  bool _isLoading = false;
  final List<String> _pollDurations = ['30 mins', '45 mins', '1 hour'];
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

  Future<void> _submitPoll() async {
    final groupCollection = FirebaseFirestore.instance.collection('groupinfo');
    final weightedVotingCollection =
        FirebaseFirestore.instance.collection('weightedvotingcollection');

    if (theAmountOfMoney != 0) {
      if (_formKey.currentState!.validate() && _selectedGroupName != null) {
        setState(() {
          _isLoading = true;
        });

        try {
          // Check if poll has expaired before creating a new one
          final groupQuerySnapshot = await groupCollection
              .where('groupname', isEqualTo: _selectedGroupName)
              .where('groupmembers', arrayContains: widget.username)
              .get();
          if (groupQuerySnapshot.docs.isNotEmpty) {
            for (var groupDoc in groupQuerySnapshot.docs) {
              String groupName = groupDoc['groupname'];

              QuerySnapshot pollQuerySnapshot = await weightedVotingCollection
                  .where('groupname', isEqualTo: groupName)
                  .orderBy('groupname', descending: false)
                  .get();

              for (var pollDoc in pollQuerySnapshot.docs) {
                DateTime expirationTime =
                    (pollDoc['expirationTime'] as Timestamp).toDate();

                print(expirationTime);

                DateTime now = DateTime.now();
                if (now.isBefore(expirationTime)) {
                  _showMessage(
                      context, 'Voting is ongoing, but it will be qeued');
                  //return;
                }
              }
            }
          }

          final now = DateTime.now();
          final expiration = _getExpirationTime(now, _selectedDuration!);

          final pollData = {
            'pollName': 'Weightedvoting',
            'pollDuration': _selectedDuration,
            'username': widget.username,
            'option': [], // Empty array for options
            'dateTimeNow': now,
            'votedusers': [],
            'groupname': _selectedGroupName,
            'expirationTime': expiration,
            '0% - 10%': _controller0to10.text,
            '10% - 20%': _controller10to20.text,
            '20% - 30%': _controller20to30.text,
            '30% - 40%': _controller30to40.text,
            '40% - 50%': _controller40to50.text,
            '50% - 60%': _controller50to60.text,
            '60% - 70%': _controller60to70.text,
            '70% - 80%': _controller70to80.text,
            '80% - 90%': _controller80to90.text,
            '90% - 100%': _controller90to100.text,
          };

          await FirebaseFirestore.instance
              .collection('weightedvotingcollection')
              .add(pollData);

          _showMessage(context, 'Poll created successfully');

          // Clear all the controllers and reset the selections
          _controller0to10.clear();
          _controller10to20.clear();
          _controller20to30.clear();
          _controller30to40.clear();
          _controller40to50.clear();
          _controller50to60.clear();
          _controller60to70.clear();
          _controller70to80.clear();
          _controller80to90.clear();
          _controller90to100.clear();
          setState(() {
            _selectedDuration = null;
            _selectedGroupName = null;
          });
        } catch (e) {
          _showMessage(
              context, 'An error occurred while creating the poll: $e');
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      _showMessage(context, 'No amount for the weighted voting');
    }
  }

  DateTime _getExpirationTime(DateTime start, String duration) {
    switch (duration) {
      case '30 mins':
        return start.add(Duration(minutes: 30));
      case '45 mins':
        return start.add(Duration(minutes: 45));
      case '1 hour':
        return start.add(Duration(hours: 1));
      default:
        return start;
    }
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
          if (_isLoading) _buildLoadingIndicator(), // Modal loader
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
                      _buildPercentageInput('0% - 10%', _controller0to10),
                      _buildPercentageInput('10% - 20%', _controller10to20),
                      _buildPercentageInput('20% - 30%', _controller20to30),
                      _buildPercentageInput('30% - 40%', _controller30to40),
                      _buildPercentageInput('40% - 50%', _controller40to50),
                      _buildPercentageInput('50% - 60%', _controller50to60),
                      _buildPercentageInput('60% - 70%', _controller60to70),
                      _buildPercentageInput('70% - 80%', _controller70to80),
                      _buildPercentageInput('80% - 90%', _controller80to90),
                      _buildPercentageInput('90% - 100%', _controller90to100),
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
                      const SizedBox(height: 16.0),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Poll Duration',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedDuration,
                        items: _pollDurations.map((duration) {
                          return DropdownMenuItem<String>(
                            value: duration,
                            child: Text(duration),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDuration = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a duration';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      _buildButton('Request', Colors.blue, _submitPoll),
                      const SizedBox(height: 16.0),
                      _buildButton('Vote', Colors.green, () {
                        // Add functionality for Vote button here

                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => WeightedVotingPage(
                                  username: widget.username)),
                        );
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
  Widget _buildPercentageInput(String label, TextEditingController controller) {
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