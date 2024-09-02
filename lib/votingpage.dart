import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'globals.dart' as globals;

class VotingPage extends StatefulWidget {
  final String username;

  const VotingPage({
    super.key,
    required this.username,
  });

  @override
  _VotingPageState createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {
  // Remove CountdownManager and related variables
  int _pollDurationInSeconds = 0;
  bool _hasVoted = false;

  @override
  void initState() {
    super.initState();
    _fetchPollData().then((pollData) {
      if (pollData != null) {
        // Directly use the duration from the data without processing
        //   _pollDurationInSeconds = _parseDuration(pollData['pollDuration']);
        // No need to check vote status or initialize the countdown manager
      }
    });
  }

  @override
  void dispose() {
    // No countdown manager to dispose
    super.dispose();
  }

  Future<Map<String, dynamic>?> _fetchPollData() async {
    final groupCollection = FirebaseFirestore.instance.collection('groupinfo');
    final pollCollection =
        FirebaseFirestore.instance.collection('pollcollection');

    try {
      QuerySnapshot groupQuerySnapshot = await groupCollection
          .where('groupmembers', arrayContains: widget.username)
          .get();

      for (var groupDoc in groupQuerySnapshot.docs) {
        String groupName = groupDoc['groupname'];
        globals.globalGroupName = groupName;

        QuerySnapshot pollQuerySnapshot =
            await pollCollection.where('groupname', isEqualTo: groupName).get();

        for (var pollDoc in pollQuerySnapshot.docs) {
          String pollDurationStr = pollDoc['pollDuration'];
          //int pollDuration = _parsePollDuration(pollDurationStr);

          return {
            'pollName': pollDoc['pollName'],
            'pollMessage': pollDoc['pollMessage'],
            'imageUrl': pollDoc['imageUrl'],
            'option': pollDoc['option'],
            'dateTimeNow': (pollDoc['dateTimeNow'] as Timestamp).toDate(),
            'expirationTime': (pollDoc['expirationTime'] as Timestamp).toDate(),
            'pollDuration': pollDurationStr,
            'username': pollDoc['username'],
          };
        }
      }
    } catch (e) {
      print('Error fetching user groups and polls: $e');
    }
    return null;
  }

  int _parsePollDuration(String duration) {
    final match = RegExp(r'(\d+)').firstMatch(duration);
    return match != null
        ? int.parse(match.group(0)!) * 60
        : 0; // Assuming duration is in minutes
  }

  Future<void> _submitVote(String option) async {
    final userCollection =
        FirebaseFirestore.instance.collection('jointventureuserdata');
    final pollCollection =
        FirebaseFirestore.instance.collection('pollcollection');

    try {
      // Skip checking if user has voted
      // Check if the user exists
      final userDoc = await userCollection
          .where('username', isEqualTo: widget.username)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        print('User not found');
        return;
      }

      final userData = userDoc.docs.first;
      final userDocId = userData.id;

      await userCollection.doc(userDocId).update({
        'option': option,
      });

      final pollData = await _fetchPollData();
      if (pollData == null) {
        print('Poll data not found');
        return;
      }

      final pollGroupName = pollData['pollName'];
      final pollQuerySnapshot = await pollCollection
          .where('pollName', isEqualTo: pollGroupName)
          .limit(1)
          .get();

      if (pollQuerySnapshot.docs.isEmpty) {
        print('Poll not found');
        return;
      }

      final pollDocId = pollQuerySnapshot.docs.first.id;
      print(pollDocId);
      // Fetch the current options array
      final pollDocSnapshot = await pollCollection.doc(pollDocId).get();
      List<dynamic> currentOptions = pollDocSnapshot.get('option') ?? [];
      print('Current options before update: $currentOptions');

      // Add the new vote to the array
      currentOptions.add(option);

// Update the Firestore document with the new array
      await pollCollection.doc(pollDocId).update({
        'option': currentOptions,
      });

      print('Option submitted: $option');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Your vote has been submitted: $option')),
        );
      }
    } catch (e) {
      print('Error submitting vote: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit vote.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchPollData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Center(
                child: Text('Error: ${snapshot.error ?? 'Poll not found.'}')),
          );
        }

        final pollData = snapshot.data!;
        final pollName = pollData['pollName'] ?? 'Poll';
        final pollMessage = pollData['pollMessage'] ?? 'No message provided';
        final imageUrl = pollData['imageUrl'];

        return Scaffold(
          appBar: AppBar(
            title: Text(pollName),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    pollName,
                    style: const TextStyle(
                        fontSize: 24.0, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Duration: ${_pollDurationInSeconds ~/ 60} min ${_pollDurationInSeconds % 60} sec',
                  style: const TextStyle(fontSize: 16.0, color: Colors.grey),
                ),
                const SizedBox(height: 16.0),
                Text(
                  pollMessage,
                  style: const TextStyle(fontSize: 20.0),
                ),
                const SizedBox(height: 16.0),
                if (imageUrl != null) ...[
                  Image.network(imageUrl),
                  const SizedBox(height: 16.0),
                ],
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    _submitVote('Yes');
                    //Navigator.pop(context);
                    Future.delayed(const Duration(milliseconds: 500), () {
                      Navigator.pop(context);
                    });
                  },
                  child: const Text('Yes'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    _submitVote('No');
                    Navigator.pop(context);
                  },
                  child: const Text('No'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
