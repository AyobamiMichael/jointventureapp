import 'package:flutter/material.dart';
import 'package:jointventureapp/creategroup.dart';
import 'package:jointventureapp/group_details.dart';
import 'package:jointventureapp/pollcreation.dart';
import 'package:jointventureapp/resultpage.dart';
import 'package:jointventureapp/walletcreation.dart';
import 'votingpage.dart';
import 'loginpage.dart';

class Dashboard extends StatefulWidget {
  final String username; // Change to accept only the username

  const Dashboard({super.key, required this.username});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  bool _notificationsEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlantis-UgarSoft'),
      ),
      drawer: _buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: [
            _buildDashboardItem(context, Icons.group_add, 'Create Group',
                onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) =>
                        CreateGroup(username: widget.username)),
              );
            }),
            _buildDashboardItem(
              context,
              Icons.wallet_giftcard,
              'Wallet',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) =>
                          WalletCreationPage(username: widget.username)),
                );
              },
            ),
            _buildDashboardItem(context, Icons.group, 'Groups', onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) =>
                        GroupDetailsPage(username: widget.username)),
              );
            }),
            _buildDashboardItem(context, Icons.poll, 'New Poll', onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) =>
                        PollCreationPage(username: widget.username)),
              );
            }),
            _buildDashboardItem(context, Icons.check_circle, 'Vote', onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) =>
                        VotingPage(username: widget.username)),
              );
            }),
            _buildDashboardItem(context, Icons.history, 'History', onTap: () {
              // Handle history icon tap, navigate to history page or perform any action
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const VoteResultPage()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem(BuildContext context, IconData icon, String label,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueGrey, width: 2.0),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blueGrey),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _showNewPollDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('New Poll'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Enter poll question',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Add your logic to handle the "Send" button click
              },
              child: Row(
                children: const [
                  Icon(Icons.send),
                  SizedBox(width: 8),
                  Text('Send'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blueGrey,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.person, size: 80, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  widget.username, // Use the username directly
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Invite a Friend'),
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.money),
            title: const Text('Money Sharing Formula'),
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () {
              _logout(context);
            },
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }
}
