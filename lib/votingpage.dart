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
  int _pollDurationInSeconds = 0;
  bool _hasVoted = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPollData().then((pollData) {
      if (pollData != null) {
        int pollDurationInSeconds = pollData['pollDurationInSeconds'];
        setState(() {
          _pollDurationInSeconds = pollDurationInSeconds;
        });
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
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
          DateTime dateTimeNow = (pollDoc['dateTimeNow'] as Timestamp).toDate();
          DateTime expirationTime =
              (pollDoc['expirationTime'] as Timestamp).toDate();
          print(expirationTime);
          DateTime now = DateTime.now();
          if (now.isAfter(dateTimeNow) && now.isBefore(expirationTime)) {
            int pollDurationInSeconds = _parsePollDuration(pollDurationStr);

            return {
              'pollName': pollDoc['pollName'],
              'pollMessage': pollDoc['pollMessage'],
              'imageUrl': pollDoc['imageUrl'],
              'option': pollDoc['option'],
              'dateTimeNow': dateTimeNow,
              'expirationTime': expirationTime,
              'pollDuration': pollDurationStr,
              'username': pollDoc['username'],
              'pollDurationInSeconds': pollDurationInSeconds,
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

  int _parsePollDuration(String duration) {
    final match = RegExp(r'(\d+)').firstMatch(duration);
    return match != null
        ? int.parse(match.group(0)!) * 60
        : 0; // Assuming duration is in minutes
  }

  Future<void> _submitVote(String option, String comment) async {
    final userCollection =
        FirebaseFirestore.instance.collection('jointventureuserdata');
    final pollCollection =
        FirebaseFirestore.instance.collection('pollcollection');

    try {
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

      await userCollection
          .doc(userDocId)
          .update({'option': option, 'comment': comment});

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
      final pollDocSnapshot = await pollCollection.doc(pollDocId).get();
      List<dynamic> currentOptions = pollDocSnapshot.get('option') ?? [];
      currentOptions.add(option);

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
        final pollDuration = pollData['pollDuration'];
        final expirationTime = pollData['expirationTime'] as DateTime;
        final currentTime = DateTime.now();
        final duration = _convertPollDurationToSeconds(pollDuration);

        if (expirationTime != null) {
          final timeDifference =
              expirationTime.difference(currentTime).inSeconds;
          if (timeDifference <= 0) {
            return Scaffold(
              body: Center(
                child: Text('Poll has expired'),
              ),
            );
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(pollName),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
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
                            style: const TextStyle(
                                fontSize: 16.0, color: Colors.grey),
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            pollMessage,
                            style: const TextStyle(fontSize: 20.0),
                          ),
                          const SizedBox(height: 16.0),
                          // if (imageUrl != null) ...[
                          // Image.network(imageUrl),
                          //const SizedBox(height: 16.0),
                          //],
                          if (imageUrl != null &&
                              imageUrl.isNotEmpty &&
                              Uri.tryParse(imageUrl)?.hasAbsolutePath ==
                                  true) ...[
                            Image.network(imageUrl),
                            const SizedBox(height: 16.0),
                          ] else ...[
                            const Placeholder(
                              fallbackHeight:
                                  200, // Adjust the height as needed
                              fallbackWidth: double.infinity,
                            ),
                            const SizedBox(height: 16.0),
                          ],

                          TextFormField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              labelText: 'Comment',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () {
                              _submitVote('Yes', _commentController.text);
                              Future.delayed(const Duration(milliseconds: 500),
                                  () {
                                Navigator.pop(context);
                              });
                            },
                            child: const Text('Yes'),
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: () {
                              _submitVote('No', _commentController.text);
                              Navigator.pop(context);
                            },
                            child: const Text('No'),
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  int _convertPollDurationToSeconds(String duration) {
    final durationParts = duration.split(' ');
    if (durationParts.length == 2) {
      final value = int.tryParse(durationParts[0]);
      final unit = durationParts[1].toLowerCase();
      if (value != null) {
        switch (unit) {
          case 'hours':
            return value * 3600;
          case 'minutes':
            return value * 60;
        }
      }
    }
    return 0;
  }
}






























// THE CODE THAT IMPLEMENTS THE TIMES
/*import 'package:flutter/material.dart';
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
  int _pollDurationInSeconds = 0;
  bool _hasVoted = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPollData().then((pollData) {
      if (pollData != null) {
        int pollDurationInSeconds = pollData['pollDurationInSeconds'];
        setState(() {
          _pollDurationInSeconds = pollDurationInSeconds;
        });
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
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
          DateTime dateTimeNow = (pollDoc['dateTimeNow'] as Timestamp).toDate();
          DateTime expirationTime =
              (pollDoc['expirationTime'] as Timestamp).toDate();

          DateTime now = DateTime.now();
          if (now.isAfter(dateTimeNow) && now.isBefore(expirationTime)) {
            int pollDurationInSeconds = _parsePollDuration(pollDurationStr);

            return {
              'pollName': pollDoc['pollName'],
              'pollMessage': pollDoc['pollMessage'],
              'imageUrl': pollDoc['imageUrl'],
              'option': pollDoc['option'],
              'dateTimeNow': dateTimeNow,
              'expirationTime': expirationTime,
              'pollDuration': pollDurationStr,
              'username': pollDoc['username'],
              'pollDurationInSeconds': pollDurationInSeconds,
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

  int _parsePollDuration(String duration) {
    final match = RegExp(r'(\d+)').firstMatch(duration);
    return match != null
        ? int.parse(match.group(0)!) * 60
        : 0; // Assuming duration is in minutes
  }

  Future<void> _submitVote(String option, String comment) async {
    final userCollection =
        FirebaseFirestore.instance.collection('jointventureuserdata');
    final pollCollection =
        FirebaseFirestore.instance.collection('pollcollection');

    try {
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

      await userCollection
          .doc(userDocId)
          .update({'option': option, 'comment': comment});

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
      final pollDocSnapshot = await pollCollection.doc(pollDocId).get();
      List<dynamic> currentOptions = pollDocSnapshot.get('option') ?? [];
      currentOptions.add(option);

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
        final pollDuration = pollData['pollDuration'];
        final expirationTime = pollData['expirationTime'] as DateTime;
        final currentTime = DateTime.now();
        final duration = _convertPollDurationToSeconds(pollDuration);

        if (expirationTime != null) {
          final timeDifference =
              expirationTime.difference(currentTime).inSeconds;
          if (timeDifference <= 0) {
            return Scaffold(
              body: Center(
                child: Text('Poll has expired'),
              ),
            );
          }
        }

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
                TextFormField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    labelText: 'Comment',
                    border: OutlineInputBorder(),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    _submitVote('Yes', _commentController.text);
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
                    _submitVote('No', _commentController.text);
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

  int _convertPollDurationToSeconds(String pollDuration) {
    final durationParts = pollDuration.split(' ');
    if (durationParts.length == 2) {
      final value = int.tryParse(durationParts[0]);
      final unit = durationParts[1];
      if (value != null) {
        switch (unit) {
          case 'hour':
          case 'hours':
            return value * 3600;
          case 'minute':
          case 'minutes':
            return value * 60;
        }
      }
    }
    return 0;
  }
}

*/ 









