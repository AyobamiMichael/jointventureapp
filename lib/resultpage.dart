import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:jointventureapp/globals.dart';

class Voter {
  final String username;
  final String comment;

  Voter({required this.username, required this.comment});
}

class VoteResultPage extends StatefulWidget {
  const VoteResultPage({super.key});

  @override
  _VoteResultPageState createState() => _VoteResultPageState();
}

class _VoteResultPageState extends State<VoteResultPage> {
  late String groupName;

  @override
  void initState() {
    super.initState();
    groupName = globalGroupName; // Access the global groupName
  }

  Future<Map<String, dynamic>> _fetchLatestPollData() async {
    final pollCollection =
        FirebaseFirestore.instance.collection('pollcollection');

    try {
      // Fetch the last poll document by ordering by the Firestore document ID (__name__)
      final pollQuerySnapshot = await pollCollection
          .where('groupname', isEqualTo: groupName)
          .orderBy(FieldPath.documentId,
              descending: true) // Order by document ID
          .limit(1) // Get the last document
          .get();

      if (pollQuerySnapshot.docs.isNotEmpty) {
        // Fetch the latest poll data
        final pollData = pollQuerySnapshot.docs.first.data();

        final expirationTime =
            (pollData['expirationTime'] as Timestamp).toDate();
        final currentTime = DateTime.now();
        print(expirationTime);

        // Calculate time difference
        final timeDifference = expirationTime.difference(currentTime).inSeconds;

        // If poll has expired, return a result indicating expiration
        if (timeDifference <= 0) {
          return {'expired': true};
        }

        // Otherwise, return the poll data and calculated results
        int yesCount = 0;
        int noCount = 0;
        List<dynamic> options = pollData['option'] ?? [];

        for (var option in options) {
          if (option == 'Yes') {
            yesCount++;
          } else if (option == 'No') {
            noCount++;
          }
        }

        int totalVotes = yesCount + noCount;
        double yesPercentage =
            (totalVotes > 0) ? (yesCount / totalVotes) * 100 : 0;
        double noPercentage =
            (totalVotes > 0) ? (noCount / totalVotes) * 100 : 0;

        return {
          'expired': false,
          'yesPercentage': yesPercentage,
          'noPercentage': noPercentage,
        };
      }
    } catch (e) {
      print('Error fetching poll data: $e');
    }

    return {'expired': false, 'yesPercentage': 0.0, 'noPercentage': 0.0};
  }

  void _navigateToVotersListPage(String option) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VotersListPage(option: option),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Poll Results'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchLatestPollData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final pollData = snapshot.data ?? {};

          // Check if the poll has expired
          if (pollData['expired'] == true) {
            return const Center(
              child: Text('Poll has expired'),
            );
          }

          final yesPercentage = pollData['yesPercentage'] ?? 0.0;
          final noPercentage = pollData['noPercentage'] ?? 0.0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    if (event.isInterestedForInteractions &&
                        response != null &&
                        response.spot != null) {
                      final index = response.spot!.touchedBarGroupIndex;
                      if (index == 0) {
                        _navigateToVotersListPage('Yes');
                      } else if (index == 1) {
                        _navigateToVotersListPage('No');
                      }
                    }
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 10,
                      getTitlesWidget: (value, _) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(color: Colors.black),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        switch (value.toInt()) {
                          case 0:
                            return const Text('Yes');
                          case 1:
                            return const Text('No');
                          default:
                            return const Text('');
                        }
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: yesPercentage,
                        color: Colors.green,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: noPercentage,
                        color: Colors.red,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class VotersListPage extends StatelessWidget {
  final String option;

  const VotersListPage({super.key, required this.option});

  Future<List<Voter>> _fetchVoters(String option) async {
    final pollCollection =
        FirebaseFirestore.instance.collection('pollcollection');
    final groupInfoCollection =
        FirebaseFirestore.instance.collection('groupinfo');
    final userCollection =
        FirebaseFirestore.instance.collection('jointventureuserdata');

    List<Voter> voters = [];
    List<String> yesVotersUsername = [];
    List<String> yesVotersComment = [];
    List<String> noVotersComment = [];
    List<String> noVotersUsername = [];
    List<dynamic> yesResp = [];
    List<dynamic> noResp = [];
    List<dynamic> groupMembers = [];

    try {
      final groupInfoQuerySnapshot = await groupInfoCollection
          .where('groupname', isEqualTo: globalGroupName)
          .get();
      for (var groupDoc in groupInfoQuerySnapshot.docs) {
        groupMembers = groupDoc['groupmembers'] ?? [];
      }

      final userInfoQuerySnapshot = await userCollection.get();
      for (var userDoc in userInfoQuerySnapshot.docs) {
        if (groupMembers.contains(userDoc['username']) &&
            userDoc['option'] == 'Yes') {
          yesVotersUsername.add(userDoc['username']);
          yesVotersComment.add(userDoc['comment']);
        } else if (groupMembers.contains(userDoc['username']) &&
            userDoc['option'] == 'No') {
          noVotersUsername.add(userDoc['username']);
          noVotersComment.add(userDoc['comment']);
        }
      }

      final pollQuerySnapshot = await pollCollection
          .where('groupname', isEqualTo: globalGroupName)
          .get();
      for (var pollDoc in pollQuerySnapshot.docs) {
        List<dynamic> options = pollDoc['option'] ?? [];
        for (int i = 0; i < options.length; i++) {
          if (options[i] == 'Yes') {
            yesResp.add(options[i]);
          } else {
            noResp.add(options[i]);
          }
        }
      }

      if (yesResp.contains(option)) {
        for (int i = 0; i < yesVotersUsername.length; i++) {
          voters.add(Voter(
            username: yesVotersUsername[i],
            comment: yesVotersComment[i],
          ));
        }
      } else if (noResp.contains(option)) {
        for (int i = 0; i < noVotersUsername.length; i++) {
          voters.add(Voter(
            username: noVotersUsername[i],
            comment: noVotersComment[i],
          ));
        }
      }
    } catch (e) {
      print('Error fetching voters: $e');
    }

    return voters;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('$option Voters'),
        ),
        body: FutureBuilder<List<Voter>>(
          future: _fetchVoters(
              option), // This now matches the return type of _fetchVoters
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final voters = snapshot.data ?? [];

            if (voters.isEmpty) {
              return const Center(child: Text('No voters found.'));
            }

            return ListView.builder(
              itemCount: voters.length,
              itemBuilder: (context, index) {
                return Container(
                  width: double
                      .infinity, // Makes the SizedBox take full width of the parent
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal:
                          16.0), // Adjusts the space around the container
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey, // Border color
                      width: 1.0, // Border width
                    ),
                    borderRadius: BorderRadius.circular(
                        8.0), // Optional: Adds rounded corners
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.all(12.0), // Padding inside the border
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voters[index].username,
                          style: const TextStyle(
                            fontSize: 18, // Increase font size for username
                            fontWeight: FontWeight
                                .bold, // Optionally make the username bold
                          ),
                        ),
                        const SizedBox(
                            height:
                                4), // Add some space between username and comment
                        Text(
                          voters[index].comment,
                          style: const TextStyle(
                            fontSize: 16, // Increase font size for comment
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ));
  }
}

















































































































/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:jointventureapp/globals.dart';

class Voter {
  final String username;
  final String comment;

  Voter({required this.username, required this.comment});
}

class VoteResultPage extends StatefulWidget {
  const VoteResultPage({super.key});

  @override
  _VoteResultPageState createState() => _VoteResultPageState();
}

class _VoteResultPageState extends State<VoteResultPage> {
  late String groupName;

  @override
  void initState() {
    super.initState();
    groupName = globalGroupName; // Access the global groupName

    _fetchPollResults();
  }

  Future<Map<String, double>> _fetchPollResults() async {
    final pollCollection =
        FirebaseFirestore.instance.collection('pollcollection');
    int yesCount = 0;
    int noCount = 0;

    try {
      // Query the polls for the given groupname and order by expirationTime to get the most recent
      final pollQuerySnapshot = await pollCollection
          .where('groupname', isEqualTo: groupName)
          .orderBy('expirationTime', descending: true)
          .limit(1) // Get only the most recent poll
          .get();

      if (pollQuerySnapshot.docs.isEmpty) {
        return {'Yes': 0, 'No': 0};
      }

      final pollDoc = pollQuerySnapshot.docs.first;

      // Ensure `expirationTime` field is not null and is a timestamp
      final expirationTimestamp = pollDoc.get('expirationTime') as Timestamp?;
      if (expirationTimestamp == null) {
        print('Error: expirationTime is missing or not a Timestamp');
        return {
          'Yes': 0,
          'No': 0
        }; // Return 0% if expirationTime is missing or not a Timestamp
      }

      final DateTime expirationTime = expirationTimestamp.toDate();
      final DateTime now = DateTime.now();

      print(expirationTime);

      // Check if the poll has expired
      if (now.isAfter(expirationTime)) {
        return {'Yes': 0, 'No': 0}; // Return 0% if poll is expired
      }

      List<dynamic> options = pollDoc.get('option') as List<dynamic>? ?? [];
      for (var option in options) {
        if (option == 'Yes') {
          yesCount++;
        } else if (option == 'No') {
          noCount++;
        }
      }

      int totalVotes = yesCount + noCount;
      double yesPercentage =
          (totalVotes > 0) ? (yesCount / totalVotes) * 100 : 0;
      double noPercentage = (totalVotes > 0) ? (noCount / totalVotes) * 100 : 0;

      return {'Yes': yesPercentage, 'No': noPercentage};
    } catch (e) {
      print('Error fetching poll results: $e');
      return {'Yes': 0, 'No': 0};
    }
  }

  void _navigateToVotersListPage(String option) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VotersListPage(option: option),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Poll Results'),
        ),
        body: FutureBuilder<Map<String, double>>(
          future: _fetchPollResults(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('No data available.'));
            }

            final pollData = snapshot.data ?? {'Yes': 0, 'No': 0};

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchCallback: (event, response) {
                      if (event.isInterestedForInteractions &&
                          response != null &&
                          response.spot != null) {
                        final index = response.spot!.touchedBarGroupIndex;
                        if (index == 0) {
                          _navigateToVotersListPage('Yes');
                        } else if (index == 1) {
                          _navigateToVotersListPage('No');
                        }
                      }
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 10,
                        getTitlesWidget: (value, _) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(color: Colors.black),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text('Yes');
                            case 1:
                              return const Text('No');
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: pollData['Yes'] ?? 0,
                          color: Colors.green,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: pollData['No'] ?? 0,
                          color: Colors.red,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ));
  }
}

class VotersListPage extends StatelessWidget {
  final String option;

  const VotersListPage({super.key, required this.option});

  Future<List<Voter>> _fetchVoters(String option) async {
    final pollCollection =
        FirebaseFirestore.instance.collection('pollcollection');
    final groupInfoCollection =
        FirebaseFirestore.instance.collection('groupinfo');
    final userCollection =
        FirebaseFirestore.instance.collection('jointventureuserdata');

    List<Voter> voters = [];
    List<String> yesVotersUsername = [];
    List<String> yesVotersComment = [];
    List<String> noVotersComment = [];
    List<String> noVotersUsername = [];
    List<dynamic> yesResp = [];
    List<dynamic> noResp = [];
    List<dynamic> groupMembers = [];

    try {
      final groupInfoQuerySnapshot = await groupInfoCollection
          .where('groupname', isEqualTo: globalGroupName)
          .get();
      for (var groupDoc in groupInfoQuerySnapshot.docs) {
        groupMembers = groupDoc['groupmembers'] ?? [];
      }

      final userInfoQuerySnapshot = await userCollection.get();
      for (var userDoc in userInfoQuerySnapshot.docs) {
        if (groupMembers.contains(userDoc['username']) &&
            userDoc['option'] == 'Yes') {
          yesVotersUsername.add(userDoc['username']);
          yesVotersComment.add(userDoc['comment']);
        } else if (groupMembers.contains(userDoc['username']) &&
            userDoc['option'] == 'No') {
          noVotersUsername.add(userDoc['username']);
          noVotersComment.add(userDoc['comment']);
        }
      }

      final pollQuerySnapshot = await pollCollection
          .where('groupname', isEqualTo: globalGroupName)
          .get();
      for (var pollDoc in pollQuerySnapshot.docs) {
        List<dynamic> options = pollDoc['option'] ?? [];
        for (int i = 0; i < options.length; i++) {
          if (options[i] == 'Yes') {
            yesResp.add(options[i]);
          } else {
            noResp.add(options[i]);
          }
        }
      }

      if (yesResp.contains(option)) {
        for (int i = 0; i < yesVotersUsername.length; i++) {
          voters.add(Voter(
            username: yesVotersUsername[i],
            comment: yesVotersComment[i],
          ));
        }
      } else if (noResp.contains(option)) {
        for (int i = 0; i < noVotersUsername.length; i++) {
          voters.add(Voter(
            username: noVotersUsername[i],
            comment: noVotersComment[i],
          ));
        }
      }
    } catch (e) {
      print('Error fetching voters: $e');
    }

    return voters;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('$option Voters'),
        ),
        body: FutureBuilder<List<Voter>>(
          future: _fetchVoters(
              option), // This now matches the return type of _fetchVoters
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final voters = snapshot.data ?? [];

            if (voters.isEmpty) {
              return const Center(child: Text('No voters found.'));
            }

            return ListView.builder(
              itemCount: voters.length,
              itemBuilder: (context, index) {
                return Container(
                  width: double
                      .infinity, // Makes the SizedBox take full width of the parent
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal:
                          16.0), // Adjusts the space around the container
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey, // Border color
                      width: 1.0, // Border width
                    ),
                    borderRadius:
                        BorderRadius.circular(8.0), // Adds rounded corners
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Username: ${voters[index].username}'),
                        const SizedBox(height: 8.0),
                        Text('Comment: ${voters[index].comment}'),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ));
  }
}

*/









































































