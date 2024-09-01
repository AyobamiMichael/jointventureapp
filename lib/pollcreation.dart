import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PollCreationPage extends StatefulWidget {
  final String username;
  const PollCreationPage({super.key, required this.username});

  @override
  _PollCreationPageState createState() => _PollCreationPageState();
}

class _PollCreationPageState extends State<PollCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _pollNameController = TextEditingController();
  final _pollMessageController = TextEditingController();
  String? _selectedDuration;
  File? _image;
  String? _selectedGroupName;
  final List<String> _pollDurations = [
    '30 mins',
    '45 mins',
    '1 hour',
  ];
  List<String> _groupNames = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGroupNames();
  }

  Future<void> _loadGroupNames() async {
    try {
      final groupCollection =
          FirebaseFirestore.instance.collection('groupinfo');
      // final snapshot =
      //await FirebaseFirestore.instance.collection('groupinfo').get();

      //final List<String> names =
      //  snapshot.docs.map((doc) => doc['groupname'] as String).toList();

      QuerySnapshot groupQuerySnapshot = await groupCollection
          .where('groupmembers', arrayContains: widget.username)
          .get();
      for (var groupDoc in groupQuerySnapshot.docs) {
        // groupName = groupDoc['groupname'];
        setState(() {
          _groupNames.add(groupDoc['groupname']);
        });
      }
      print(_groupNames);
      // setState(() {
      // _groupNames = names;
      //});
    } catch (e) {
      print('Error loading group names: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitPoll() async {
    if (_formKey.currentState!.validate() && _selectedGroupName != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final now = DateTime.now();
        final expiration = _getExpirationTime(now, _selectedDuration!);

        final pollData = {
          'pollName': _pollNameController.text,
          'pollDuration': _selectedDuration,
          'pollMessage': _pollMessageController.text,
          'imageUrl': _image != null ? await _uploadImage() : '',
          'username': widget.username,
          'option': [], // Empty array for options
          'dateTimeNow': now,
          'groupname': _selectedGroupName,
          'expirationTime': expiration,
        };

        await FirebaseFirestore.instance
            .collection('pollcollection')
            .add(pollData);

        _showMessage(context, 'Poll created successfully');

        // Clear the text fields
        _pollNameController.clear();
        _pollMessageController.clear();
        setState(() {
          _image = null;
          _selectedDuration = null;
          _selectedGroupName = null;
        });
      } catch (e) {
        _showMessage(context, 'An error occurred while creating the poll: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
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

  Future<String> _uploadImage() async {
    // Logic to upload image to Firebase Storage and return the image URL
    // Implement this according to your Firebase setup
    return 'image-url'; // Placeholder
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _pollNameController.dispose();
    _pollMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Poll'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _pollNameController,
                    decoration: const InputDecoration(
                      labelText: 'Poll Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a poll name';
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
                  TextFormField(
                    controller: _pollMessageController,
                    decoration: const InputDecoration(
                      labelText: 'Poll Message',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a poll message';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  _image != null
                      ? Column(
                          children: [
                            Image.file(_image!),
                            const SizedBox(height: 16.0),
                          ],
                        )
                      : Container(),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Upload Image'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _submitPoll,
                    child: const Text('Send Poll'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
