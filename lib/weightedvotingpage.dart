import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WeightedVotingPage extends StatefulWidget {
  final String username;

  const WeightedVotingPage({Key? key, required this.username})
      : super(key: key);

  @override
  _WeightedVotingPageState createState() => _WeightedVotingPageState();
}

class _WeightedVotingPageState extends State<WeightedVotingPage> {
  String? _selectedGroupName;
  String? _selectedPollTitle;
  List<String> _groupNames = [];
  List<String> _pollTitles = [];
  bool _isLoading = false;
  final TextEditingController _commentController = TextEditingController();

  // TextEditingControllers for the percentage ranges

  final TextEditingController _controllerPollCreator = TextEditingController();
  final TextEditingController _pollTitleController = TextEditingController();
  final TextEditingController _controllerMin1toMax1 = TextEditingController();
  //final TextEditingController _controllerMax1 = TextEditingController();
  final TextEditingController _controllerMin2toMax2 = TextEditingController();
  //final TextEditingController _controllerMax2 = TextEditingController();
  final TextEditingController _controllerMin3toMax3 = TextEditingController();
  //final TextEditingController _controllerMax3 = TextEditingController();
  final TextEditingController _controllerMin4toMax4 = TextEditingController();
  final TextEditingController _controllerMin5toMax5 = TextEditingController();
  //final TextEditingController _controllerMin5 = TextEditingController();
  //final TextEditingController _controllerMax5 = TextEditingController();
  final TextEditingController _controllerVotingPower1 = TextEditingController();
  final TextEditingController _controllerVotingPower2 = TextEditingController();
  final TextEditingController _controllerVotingPower3 = TextEditingController();
  final TextEditingController _controllerVotingPower4 = TextEditingController();
  final TextEditingController _controllerVotingPower5 = TextEditingController();

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

  String pending = '';
  Future<void> _fetchPollTitles(String groupname) async {
    try {
      final weightedVotingCollection =
          FirebaseFirestore.instance.collection('weightedvotingcollection');

      // Query Firestore based on the groupname field
      final groupQuerySnapshot = await weightedVotingCollection
          .where('groupname', isEqualTo: groupname)
          .get();

      // Map each document to its 'pollTitle' field
      List<String> listOfPollTitles = groupQuerySnapshot.docs
          .where((doc) => doc['pending'] == pending)
          .map((doc) {
        return doc['pollTitle'] as String;
      }).toList();
      // Update the state with the list of poll titles
      setState(() {
        _pollTitles = listOfPollTitles;
      });
    } catch (e) {
      print('Error fetching poll titles: $e');
    }
  }

  Future<Map<String, dynamic>?> _fetchPollData(String pollTitle) async {
    final weightedVotingCollection =
        FirebaseFirestore.instance.collection('weightedvotingcollection');

    try {
      QuerySnapshot pollQuerySnapshot = await weightedVotingCollection
          .where('pollTitle', isEqualTo: pollTitle)
          .get();
      print(pollQuerySnapshot.docs);
      for (var pollDoc in pollQuerySnapshot.docs) {
        String pollDurationStr = pollDoc['pollDuration'];
        String pollPendingStatus = pollDoc['pending'];
        DateTime dateTimeNow = (pollDoc['dateTimeNow'] as Timestamp).toDate();
        DateTime expirationTime =
            (pollDoc['expirationTime'] as Timestamp).toDate();
        print('OKAY');
        print(expirationTime.toString());

        DateTime now = DateTime.now();
        if (pollPendingStatus == '' && now.isAfter(expirationTime)) {
          print('Expired');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Poll has expired')),
          );
          return null;
        }

        if (now.isAfter(dateTimeNow) && now.isBefore(expirationTime)) {
          return {
            'pollTitle': pollDoc['pollTitle'],
            'option': pollDoc['option'],
            'dateTimeNow': dateTimeNow,
            'expirationTime': expirationTime,
            'username': pollDoc['username'],
            'Min1 - Max1': pollDoc['Min1'] + '  -   ' + pollDoc['Max1'],
            'Min2 - Max2': pollDoc['Min2'] + '  -   ' + pollDoc['Max2'],
            'Min3 - Max3': pollDoc['Min3'] + '  -   ' + pollDoc['Max3'],
            'Min4 - Max4': pollDoc['Min4'] + '  -   ' + pollDoc['Max4'],
            'Min5 - Max5': pollDoc['Min5'] + '  -   ' + pollDoc['Max5'],
            'VotingPower1': pollDoc['VotingPower1'],
            'VotingPower2': pollDoc['VotingPower2'],
            'VotingPower3': pollDoc['VotingPower3'],
            'VotingPower4': pollDoc['VotingPower4'],
            'VotingPower5': pollDoc['VotingPower5'],
          };
        } else if (now.isAfter(expirationTime)) {
          setState(() {
            pending = 'yes';
          });
        } else if (pollPendingStatus == '' && now.isAfter(expirationTime)) {
          // Show a SnackBar if the poll has expired or is not yet active
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Poll has expired or is not yet active.')),
          );

          _resetControllers();
          return null;
        }
      }
    } catch (e) {
      print('Error fetching poll data: $e');
    }
    return null;
  }

  void _resetControllers() {
    _controllerPollCreator.clear();
    _controllerMin1toMax1.clear();
    _controllerMin2toMax2.clear();
    _controllerMin3toMax3.clear();
    _controllerMin4toMax4.clear();
    _controllerMin5toMax5.clear();
    _controllerVotingPower1.clear();
    _controllerVotingPower2.clear();
    _controllerVotingPower3.clear();
    _controllerVotingPower4.clear();
    _controllerVotingPower5.clear();
    _commentController.clear();
  }

  // Populate the controllers with the poll data
  void _populateControllers(Map<String, dynamic> pollData) {
    _controllerPollCreator.text = pollData['username'].toString();
    _controllerMin1toMax1.text = pollData['Min1 - Max1'].toString();
    _controllerMin2toMax2.text = pollData['Min2 - Max2'].toString();
    _controllerMin3toMax3.text = pollData['Min3 - Max3'].toString();
    _controllerMin4toMax4.text = pollData['Min4 - Max4'].toString();
    _controllerMin5toMax5.text = pollData['Min5 - Max5'].toString();
    _controllerVotingPower1.text = pollData['VotingPower1'].toString();
    _controllerVotingPower2.text = pollData['VotingPower2'].toString();
    _controllerVotingPower3.text = pollData['VotingPower3'].toString();
    _controllerVotingPower4.text = pollData['VotingPower4'].toString();
    _controllerVotingPower5.text = pollData['VotingPower5'].toString();
  }

  // Function to handle voting
  Future<void> _handleVote(String voteOption, String comment) async {
    final userCollection =
        FirebaseFirestore.instance.collection('jointventureuserdata');
    final pollCollection =
        FirebaseFirestore.instance.collection('weightedvotingcollection');

    if (_selectedGroupName != null) {
      try {
        final userDoc = await userCollection
            .where('username', isEqualTo: widget.username)
            .limit(1)
            .get();

        if (userDoc.docs.isEmpty) {
          print('User not found');
          return;
        }
        // Query to get the most recent poll based on the 'groupname' in descending order
        QuerySnapshot pollQuerySnapshot = await pollCollection
            .where('pollTitle', isEqualTo: _selectedPollTitle)
            .limit(1) // Fetch only the most recent one
            .get();

        if (pollQuerySnapshot.docs.isEmpty) {
          print('Poll not found');
          return;
        }

        // Update UserCollection
        final userData = userDoc.docs.first;
        final userDocId = userData.id;

        await userCollection.doc(userDocId).update({
          'wightedvotingoption': voteOption,
          'weightedvotingcomment': comment
        });
        // Get the first document (most recent one)
        final pollDocId = pollQuerySnapshot.docs.first.id;
        // Retrieve the existing voted users array
        final pollDocSnapshot = await pollCollection.doc(pollDocId).get();
        List<dynamic> currentVotedUsers =
            pollDocSnapshot.get('votedusers') ?? [];

        if (currentVotedUsers.contains(widget.username)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('You have already voted in this poll.')),
          );
          return;
        }
        // Add the current user to the votedusers list
        currentVotedUsers.add(widget.username);
        // Update the poll document with the new vote and voted users
        //  if (currentVotedUsers.contains(widget.username)) {
        //  print(currentVotedUsers.contains(widget.username));

        //if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        // const SnackBar(content: Text('Double Voting Not Allowed')),
        //);
        // }
        //return;
        //} else {
        await pollCollection.doc(pollDocId).update({
          'votedusers': currentVotedUsers, // Update voted users
        });
        //}
        List<dynamic> currentOptions = pollDocSnapshot.get('option') ?? [];
        print(currentOptions);
        currentOptions.add(voteOption);
        await pollCollection.doc(pollDocId).update({
          'option': currentOptions,
        });

        print('Option submitted: $voteOption');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Your vote has been submitted: $voteOption')),
          );
          _resetControllers();
        }
        setState(() {
          _isLoading = true;
        });
      } catch (e) {
        print('Error submitting vote: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a group to vote.')),
      );
    }
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
                labelText: '',
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
              child: SingleChildScrollView(
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
                        _resetControllers();
                        if (value != null) {
                          await _fetchPollTitles(value);
                          //if (pollData != null) {
                          //_populateControllers(pollData);
                          //}
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a group name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Poll Title',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedPollTitle,
                      items: _pollTitles.map((pollTitle) {
                        return DropdownMenuItem<String>(
                          value: pollTitle,
                          child: Text(pollTitle),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        setState(() {
                          _selectedPollTitle = value;
                        });

                        if (value != null) {
                          // set the polls here
                          final pollData = await _fetchPollData(value);
                          if (pollData != null) {
                            _populateControllers(pollData);
                            // Populate the poll list of dates
                          }
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a date';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildPercentageOutput(
                        'Created by', _controllerPollCreator),
                    _buildPercentageOutput(
                        'MinAmt1 - MaxAmt1', _controllerMin1toMax1),
                    _buildPercentageOutput(
                        'MinAmt2 - MaxAmt2', _controllerMin2toMax2),
                    _buildPercentageOutput(
                        'MinAmt3 - MaxAmt3', _controllerMin3toMax3),
                    _buildPercentageOutput(
                        'MinAmt4 - MaxAmt4', _controllerMin4toMax4),
                    _buildPercentageOutput(
                        'MinAmt5 - MaxAmt5', _controllerMin5toMax5),
                    _buildPercentageOutput(
                        'Voting Power1', _controllerVotingPower1),
                    _buildPercentageOutput(
                        'Voting Power2', _controllerVotingPower2),
                    _buildPercentageOutput(
                        'Voting Power3', _controllerVotingPower3),
                    _buildPercentageOutput(
                        'Voting Power4', _controllerVotingPower4),
                    _buildPercentageOutput(
                        'Voting Power5', _controllerVotingPower5),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        labelText: 'Comment',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Yes Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            _handleVote('Yes', _commentController.text),
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            backgroundColor: Colors.green),
                        child: const Text(
                          'Yes',
                          style: TextStyle(fontSize: 20, color: Colors.black),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            _handleVote('No', _commentController.text),
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            backgroundColor: Colors.red),
                        child: const Text(
                          'No',
                          style: TextStyle(fontSize: 20, color: Colors.black),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _controllerMin1toMax1.dispose();
    _controllerMin2toMax2.dispose();
    _controllerMin3toMax3.dispose();
    _controllerMin4toMax4.dispose();
    _controllerMin5toMax5.dispose();

    super.dispose();
  }
}







































/*import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WeightedVotingPage extends StatefulWidget {
  final String username;

  const WeightedVotingPage({Key? key, required this.username})
      : super(key: key);

  @override
  _WeightedVotingPageState createState() => _WeightedVotingPageState();
}

class _WeightedVotingPageState extends State<WeightedVotingPage> {
  String? _selectedGroupName;
  String? _selectedPollTitle;
  List<String> _groupNames = [];
  List<String> _pollTitles = [];
  bool _isLoading = false;
  final TextEditingController _commentController = TextEditingController();

  // TextEditingControllers for the percentage ranges

  final TextEditingController _controllerPollCreator = TextEditingController();
  final TextEditingController _controller0To10 = TextEditingController();
  final TextEditingController _controller10To20 = TextEditingController();
  final TextEditingController _controller20To30 = TextEditingController();
  final TextEditingController _controller30To40 = TextEditingController();
  final TextEditingController _controller40To50 = TextEditingController();
  final TextEditingController _controller50To60 = TextEditingController();
  final TextEditingController _controller60To70 = TextEditingController();
  final TextEditingController _controller70To80 = TextEditingController();
  final TextEditingController _controller80To90 = TextEditingController();
  final TextEditingController _controller90To100 = TextEditingController();

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

  String pending = '';
  Future<void> _fetchPollTitles(String groupname) async {
    try {
      final weightedVotingCollection =
          FirebaseFirestore.instance.collection('weightedvotingcollection');

      // Query Firestore based on the groupname field
      final groupQuerySnapshot = await weightedVotingCollection
          .where('groupname', isEqualTo: groupname)
          .get();

      // Map each document to its 'pollTitle' field
      List<String> listOfPollTitles = groupQuerySnapshot.docs
          .where((doc) => doc['pending'] == pending)
          .map((doc) {
        return doc['pollTitle'] as String;
      }).toList();
      // Update the state with the list of poll titles
      setState(() {
        _pollTitles = listOfPollTitles;
      });
    } catch (e) {
      print('Error fetching poll titles: $e');
    }
  }

  Future<Map<String, dynamic>?> _fetchPollData(String pollTitle) async {
    final weightedVotingCollection =
        FirebaseFirestore.instance.collection('weightedvotingcollection');

    try {
      QuerySnapshot pollQuerySnapshot = await weightedVotingCollection
          .where('pollTitle', isEqualTo: pollTitle)
          .get();
      print(pollQuerySnapshot.docs);
      for (var pollDoc in pollQuerySnapshot.docs) {
        String pollDurationStr = pollDoc['pollDuration'];
        String pollPendingStatus = pollDoc['pending'];
        DateTime dateTimeNow = (pollDoc['dateTimeNow'] as Timestamp).toDate();
        DateTime expirationTime =
            (pollDoc['expirationTime'] as Timestamp).toDate();
        print('OKAY');
        print(expirationTime.toString());

        DateTime now = DateTime.now();
        if (pollPendingStatus == '' && now.isAfter(expirationTime)) {
          print('Expired');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Poll has expired')),
          );
          return null;
        }

        if (now.isAfter(dateTimeNow) && now.isBefore(expirationTime)) {
          return {
            'pollTitle': pollDoc['pollTitle'],
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
            '90% - 100%': pollDoc['90% - 100%'],
          };
        } else if (now.isAfter(expirationTime)) {
          setState(() {
            pending = 'yes';
          });
        } else if (pollPendingStatus == '' && now.isAfter(expirationTime)) {
          // Show a SnackBar if the poll has expired or is not yet active
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Poll has expired or is not yet active.')),
          );

          _resetControllers();
          return null;
        }
      }
    } catch (e) {
      print('Error fetching poll data: $e');
    }
    return null;
  }

  void _resetControllers() {
    _controllerPollCreator.clear();
    _controller0To10.clear();
    _controller10To20.clear();
    _controller20To30.clear();
    _controller30To40.clear();
    _controller40To50.clear();
    _controller50To60.clear();
    _controller60To70.clear();
    _controller70To80.clear();
    _controller80To90.clear();
    _controller90To100.clear();
  }

  // Populate the controllers with the poll data
  void _populateControllers(Map<String, dynamic> pollData) {
    _controllerPollCreator.text = pollData['username'].toString();
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
  }

  // Function to handle voting
  Future<void> _handleVote(String voteOption, String comment) async {
    final userCollection =
        FirebaseFirestore.instance.collection('jointventureuserdata');
    final pollCollection =
        FirebaseFirestore.instance.collection('weightedvotingcollection');

    if (_selectedGroupName != null) {
      try {
        final userDoc = await userCollection
            .where('username', isEqualTo: widget.username)
            .limit(1)
            .get();

        if (userDoc.docs.isEmpty) {
          print('User not found');
          return;
        }
        // Query to get the most recent poll based on the 'groupname' in descending order
        QuerySnapshot pollQuerySnapshot = await pollCollection
            .where('pollTitle', isEqualTo: _selectedPollTitle)
            .limit(1) // Fetch only the most recent one
            .get();

        if (pollQuerySnapshot.docs.isEmpty) {
          print('Poll not found');
          return;
        }

        // Update UserCollection
        final userData = userDoc.docs.first;
        final userDocId = userData.id;

        await userCollection.doc(userDocId).update({
          'wightedvotingoption': voteOption,
          'weightedvotingcomment': comment
        });
        // Get the first document (most recent one)
        final pollDocId = pollQuerySnapshot.docs.first.id;
        // Retrieve the existing voted users array
        final pollDocSnapshot = await pollCollection.doc(pollDocId).get();
        List<dynamic> currentVotedUsers =
            pollDocSnapshot.get('votedusers') ?? [];

        if (currentVotedUsers.contains(widget.username)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('You have already voted in this poll.')),
          );
          return;
        }
        // Add the current user to the votedusers list
        currentVotedUsers.add(widget.username);
        // Update the poll document with the new vote and voted users
        //  if (currentVotedUsers.contains(widget.username)) {
        //  print(currentVotedUsers.contains(widget.username));

        //if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        // const SnackBar(content: Text('Double Voting Not Allowed')),
        //);
        // }
        //return;
        //} else {
        await pollCollection.doc(pollDocId).update({
          'votedusers': currentVotedUsers, // Update voted users
        });
        //}
        List<dynamic> currentOptions = pollDocSnapshot.get('option') ?? [];
        print(currentOptions);
        currentOptions.add(voteOption);
        await pollCollection.doc(pollDocId).update({
          'option': currentOptions,
        });

        print('Option submitted: $voteOption');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Your vote has been submitted: $voteOption')),
          );
          _resetControllers();
        }
      } catch (e) {
        print('Error submitting vote: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a group to vote.')),
      );
    }
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
              child: SingleChildScrollView(
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
                        _resetControllers();
                        if (value != null) {
                          await _fetchPollTitles(value);
                          //if (pollData != null) {
                          //_populateControllers(pollData);
                          //}
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a group name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Poll Title',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedPollTitle,
                      items: _pollTitles.map((pollTitle) {
                        return DropdownMenuItem<String>(
                          value: pollTitle,
                          child: Text(pollTitle),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        setState(() {
                          _selectedPollTitle = value;
                        });

                        if (value != null) {
                          // set the polls here
                          final pollData = await _fetchPollData(value);
                          if (pollData != null) {
                            _populateControllers(pollData);
                            // Populate the poll list of dates
                          }
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a date';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildPercentageOutput(
                        'Created by', _controllerPollCreator),
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
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        labelText: 'Comment',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Yes Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            _handleVote('Yes', _commentController.text),
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            backgroundColor: Colors.green),
                        child: const Text(
                          'Yes',
                          style: TextStyle(fontSize: 20, color: Colors.black),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            _handleVote('No', _commentController.text),
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            backgroundColor: Colors.red),
                        child: const Text(
                          'No',
                          style: TextStyle(fontSize: 20, color: Colors.black),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
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
}*/
