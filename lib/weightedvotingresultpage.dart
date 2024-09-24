import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class Voter {
  final String username;
  final String comment;

  Voter({required this.username, required this.comment});
}

class WeightedVotingResultPage extends StatefulWidget {
  final String username;

  const WeightedVotingResultPage({super.key, required this.username});

  @override
  State<WeightedVotingResultPage> createState() =>
      _WeightedVotingResultPageState();
}

class _WeightedVotingResultPageState extends State<WeightedVotingResultPage> {
  String? _selectedGroupName;
  String? _selectedPollTitle;
  List<String> _groupNames = [];
  List<String> _pollTitles = [];
  bool _isLoading = false;
  double _yesPercentage = 0.0;
  double _noPercentage = 0.0;
  bool _pollExpired = false;

  @override
  void initState() {
    super.initState();
    _fetchGroupNames();
  }

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

  Future<void> _fetchPollTitles(String groupname) async {
    try {
      final weightedVotingCollection =
          FirebaseFirestore.instance.collection('weightedvotingcollection');

      // Query Firestore based on the groupname field
      final groupQuerySnapshot = await weightedVotingCollection
          .where('groupname', isEqualTo: groupname)
          .get();

      // Map each document to its 'pollTitle' field
      List<String> listOfPollTitles = groupQuerySnapshot.docs.map((doc) {
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

  Future<void> _fetchLatestPollData(String pollTitle) async {
    final pollCollection =
        FirebaseFirestore.instance.collection('weightedvotingcollection');

    try {
      // Fetch the last poll document by ordering by the Firestore document ID
      final pollQuerySnapshot = await pollCollection
          .where('pollTitle', isEqualTo: pollTitle)
          .orderBy(FieldPath.documentId, descending: true)
          .limit(1)
          .get();

      if (pollQuerySnapshot.docs.isNotEmpty) {
        // Fetch the latest poll data
        final pollData = pollQuerySnapshot.docs.first.data();

        final expirationTime =
            (pollData['expirationTime'] as Timestamp).toDate();
        final currentTime = DateTime.now();

        // Calculate time difference
        final timeDifference = expirationTime.difference(currentTime).inSeconds;

        // If poll has expired, return a result indicating expiration
        if (timeDifference <= 0) {
          setState(() {
            _pollExpired = true;
          });
          return;
        }

        // Otherwise, calculate results
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

        setState(() {
          _yesPercentage = yesPercentage;
          _noPercentage = noPercentage;
          _pollExpired = false;
        });
      }
    } catch (e) {
      print('Error fetching poll data: $e');
    }
  }

  void _navigateToVotersListPage(String option, String groupname) {
    print(groupname);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VotersListPage(option: option, groupname: groupname),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weighted Voting Results'),
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

                        if (value != null) {
                          await _fetchPollTitles(value);
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
                          await _fetchLatestPollData(value);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    _pollExpired
                        ? const Text(
                            'Poll Expired',
                            style: TextStyle(fontSize: 18, color: Colors.red),
                          )
                        : _yesPercentage + _noPercentage > 0
                            ? GestureDetector(
                                onTapDown: (TapDownDetails details) {
                                  if (details.localPosition.dx <
                                      MediaQuery.of(context).size.width / 2) {
                                    // Clicked on "Yes" bar
                                    _navigateToVotersListPage(
                                        'Yes', _selectedGroupName!);
                                  } else {
                                    // Clicked on "No" bar
                                    _navigateToVotersListPage(
                                        'No', _selectedGroupName!);
                                  }
                                },
                                child: SizedBox(
                                  height: 300,
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      barGroups: [
                                        BarChartGroupData(
                                          x: 0,
                                          barRods: [
                                            BarChartRodData(
                                              toY: _yesPercentage,
                                              color: Colors.green,
                                              width: 20,
                                            ),
                                          ],
                                          showingTooltipIndicators: [0],
                                        ),
                                        BarChartGroupData(
                                          x: 1,
                                          barRods: [
                                            BarChartRodData(
                                              toY: _noPercentage,
                                              color: Colors.red,
                                              width: 20,
                                            ),
                                          ],
                                          showingTooltipIndicators: [0],
                                        ),
                                      ],
                                      titlesData: FlTitlesData(
                                        show: true,
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (double value, _) {
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
                                        leftTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false),
                                        ),
                                      ),
                                      gridData: FlGridData(show: false),
                                    ),
                                  ),
                                ),
                              )
                            : const Text('No votes yet'),
                  ],
                ),
              ),
            ),
    );
  }
}

class VotersListPage extends StatelessWidget {
  final String option;
  final String groupname;

  const VotersListPage(
      {super.key, required this.option, required this.groupname});

  Future<List<Voter>> _fetchVoters(String option) async {
    final pollCollection =
        FirebaseFirestore.instance.collection('weightedvotingcollection');
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
          .where('groupname', isEqualTo: groupname)
          .get();
      for (var groupDoc in groupInfoQuerySnapshot.docs) {
        groupMembers = groupDoc['groupmembers'] ?? [];
      }

      final userInfoQuerySnapshot = await userCollection.get();
      for (var userDoc in userInfoQuerySnapshot.docs) {
        print(userDoc['wightedvotingoption']);
        if (groupMembers.contains(userDoc['username']) &&
            userDoc['wightedvotingoption'] == 'Yes') {
          yesVotersUsername.add(userDoc['username']);
          yesVotersComment.add(userDoc['weightedvotingcomment']);
        } else if (groupMembers.contains(userDoc['username']) &&
            userDoc['wightedvotingoption'] == 'No') {
          noVotersUsername.add(userDoc['username']);
          noVotersComment.add(userDoc['weightedvotingcomment']);
        }
      }

      final pollQuerySnapshot =
          await pollCollection.where('groupname', isEqualTo: groupname).get();
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

  /*Future<List<Voter>> _fetchVoters(String option) async {
    final pollCollection =
        FirebaseFirestore.instance.collection('weightedvotingcollection');
    final groupInfoCollection =
        FirebaseFirestore.instance.collection('groupinfo');
    final userCollection =
        FirebaseFirestore.instance.collection('jointventureuserdata');

    try {
      final pollQuerySnapshot =
          await pollCollection.where('groupname', isEqualTo: groupname).get();

      final voters = pollQuerySnapshot.docs.expand((doc) {
        final options = doc['option'] as List<dynamic>;
        final comments = doc['comment'] as List<dynamic>;

        return options.asMap().entries.where((entry) {
          final index = entry.key;
          final selectedOption = entry.value;

          return selectedOption == option;
        }).map((entry) {
          final index = entry.key;
          final username = entry.value as String;
          final comment = comments.length > index ? comments[index] : '';

          return Voter(username: username, comment: comment);
        });
      }).toList();

      return voters;
    } catch (e) {
      print('Error fetching voters: $e');
      return [];
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(':$option: Voters Response'),
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
              return const Center(child: Text('"NO" voters response found.'));
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

  /* @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$option Voters'),
      ),
      body: FutureBuilder<List<Voter>>(
        future: _fetchVoters(option),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading voters'));
          }

          final voters = snapshot.data ?? [];

          return voters.isEmpty
              ? const Center(child: Text('No voters for this option'))
              : ListView.builder(
                  itemCount: voters.length,
                  itemBuilder: (context, index) {
                    final voter = voters[index];

                    return ListTile(
                      title: Text(voter.username),
                      subtitle: Text(voter.comment.isNotEmpty
                          ? voter.comment
                          : 'No comment'),
                    );
                  },
                );
        },
      ),
    );
  }*/
}


















/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class Voter {
  final String username;
  final String comment;

  Voter({required this.username, required this.comment});
}

class WeightedVotingResultPage extends StatefulWidget {
  final String username;

  const WeightedVotingResultPage({super.key, required this.username});

  @override
  State<WeightedVotingResultPage> createState() =>
      _WeightedVotingResultPageState();
}

class _WeightedVotingResultPageState extends State<WeightedVotingResultPage> {
  String? _selectedGroupName;
  String? _selectedPollTitle;
  List<String> _groupNames = [];
  List<String> _pollTitles = [];
  bool _isLoading = false;
  double _yesPercentage = 0.0;
  double _noPercentage = 0.0;
  bool _pollExpired = false;

  @override
  void initState() {
    super.initState();
    _fetchGroupNames();
  }

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
          .where((doc) => doc['pending'] == '')
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

  Future<void> _fetchLatestPollData(String pollTitle) async {
    final pollCollection =
        FirebaseFirestore.instance.collection('weightedvotingcollection');

    try {
      // Fetch the last poll document by ordering by the Firestore document ID
      final pollQuerySnapshot = await pollCollection
          .where('pollTitle', isEqualTo: pollTitle)
          .orderBy(FieldPath.documentId, descending: true)
          .limit(1)
          .get();

      if (pollQuerySnapshot.docs.isNotEmpty) {
        // Fetch the latest poll data
        final pollData = pollQuerySnapshot.docs.first.data();

        final expirationTime =
            (pollData['expirationTime'] as Timestamp).toDate();
        final currentTime = DateTime.now();

        // Calculate time difference
        final timeDifference = expirationTime.difference(currentTime).inSeconds;

        // If poll has expired, return a result indicating expiration
        if (timeDifference <= 0) {
          setState(() {
            _pollExpired = true;
          });
          return;
        }

        // Otherwise, calculate results
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

        setState(() {
          _yesPercentage = yesPercentage;
          _noPercentage = noPercentage;
          _pollExpired = false;
        });
      }
    } catch (e) {
      print('Error fetching poll data: $e');
    }
  }

  void _navigateToVotersListPage(String option, String groupname) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VotersListPage(option: option, groupname: groupname),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weighted Voting Results'),
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

                        if (value != null) {
                          await _fetchPollTitles(value);
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
                          await _fetchLatestPollData(value);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    _pollExpired
                        ? const Text(
                            'Poll Expired',
                            style: TextStyle(fontSize: 18, color: Colors.red),
                          )
                        : _yesPercentage + _noPercentage > 0
                            ? SizedBox(
                                height: 300,
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    barGroups: [
                                      BarChartGroupData(
                                        x: 0,
                                        barRods: [
                                          BarChartRodData(
                                            toY: _yesPercentage,
                                            color: Colors.green,
                                            width: 20,
                                          ),
                                        ],
                                        showingTooltipIndicators: [0],
                                      ),
                                      BarChartGroupData(
                                        x: 1,
                                        barRods: [
                                          BarChartRodData(
                                            toY: _noPercentage,
                                            color: Colors.red,
                                            width: 20,
                                          ),
                                        ],
                                        showingTooltipIndicators: [0],
                                      ),
                                    ],
                                    titlesData: FlTitlesData(
                                      show: true,
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (double value, _) {
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
                                      leftTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                    ),
                                    gridData: FlGridData(show: false),
                                  ),
                                ),
                              )
                            : const Text('No votes yet'),
                  ],
                ),
              ),
            ),
    );
  }
}

class VotersListPage extends StatelessWidget {
  final String option;
  final String groupname;

  const VotersListPage(
      {super.key, required this.option, required this.groupname});

  Future<List<Voter>> _fetchVoters(String option) async {
    final pollCollection =
        FirebaseFirestore.instance.collection('weightedvotingcollection');
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
          .where('groupname', isEqualTo: groupname)
          .get();
      for (var groupDoc in groupInfoQuerySnapshot.docs) {
        groupMembers = groupDoc['groupmembers'] ?? [];
      }

      final userInfoQuerySnapshot = await userCollection.get();
      for (var userDoc in userInfoQuerySnapshot.docs) {
        if (groupMembers.contains(userDoc['username']) &&
            userDoc['wightedvotingoption'] == 'Yes') {
          yesVotersUsername.add(userDoc['username']);
          yesVotersComment.add(userDoc['weightedvotingcomment']);
        } else if (groupMembers.contains(userDoc['username']) &&
            userDoc['wightedvotingoption'] == 'No') {
          noVotersUsername.add(userDoc['username']);
          noVotersComment.add(userDoc['weightedvotingcomment']);
        }
      }

      final pollQuerySnapshot = await pollCollection
          .where('groupname', isEqualTo: groupname)
          .get();
      for (var pollDoc in pollQuerySnapshot.docs) {
        List<dynamic> options = pollDoc['wightedvotingoption'] ?? [];
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
          title: Text(':$option: Voters Response'),
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
              return const Center(child: Text('"NO" voters response found.'));
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
*/




