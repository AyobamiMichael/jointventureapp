import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:jointventureapp/globals.dart';

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
    print(groupName);
    try {
      final pollQuerySnapshot =
          await pollCollection.where('groupname', isEqualTo: groupName).get();
      for (var pollDoc in pollQuerySnapshot.docs) {
        List<dynamic> options = pollDoc['option'] ?? [];
        for (var option in options) {
          if (option == 'Yes') {
            yesCount++;
          } else if (option == 'No') {
            noCount++;
          }
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
      ),
    );
  }
}

class VotersListPage extends StatelessWidget {
  final String option;

  const VotersListPage({super.key, required this.option});

  Future<List<String>> _fetchVoters(String option) async {
    final pollCollection =
        FirebaseFirestore.instance.collection('pollcollection');
    List<String> voters = [];

    try {
      final pollQuerySnapshot = await pollCollection
          .where('groupname', isEqualTo: globalGroupName)
          .get();
      for (var pollDoc in pollQuerySnapshot.docs) {
        List<dynamic> options = pollDoc['option'] ?? [];
        List<dynamic> usernames = pollDoc['usernames'] ?? [];

        for (int i = 0; i < options.length; i++) {
          if (options[i] == option && i < usernames.length) {
            voters.add(usernames[i]);
          }
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
      body: FutureBuilder<List<String>>(
        future: _fetchVoters(option),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final voters = snapshot.data ?? [];

          return ListView.builder(
            itemCount: voters.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(voters[index]),
              );
            },
          );
        },
      ),
    );
  }
}





























/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:jointventureapp/globals.dart';

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
    print(groupName);
    try {
      final pollQuerySnapshot =
          await pollCollection.where('groupname', isEqualTo: groupName).get();
      for (var pollDoc in pollQuerySnapshot.docs) {
        List<dynamic> options = pollDoc['option'] ?? [];
        for (var option in options) {
          if (option == 'Yes') {
            yesCount++;
          } else if (option == 'No') {
            noCount++;
          }
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

          final pollData = snapshot.data ?? {'Yes': 0, 'No': 0};

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                barTouchData: BarTouchData(enabled: false),
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
      ),
    );
  }
}
*/