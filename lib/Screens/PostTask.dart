import 'package:cfcapp/BasePage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

class TaskSubmission extends StatefulWidget {
  const TaskSubmission({super.key});

  @override
  State<TaskSubmission> createState() => _TaskSubmissionState();
}

class _TaskSubmissionState extends State<TaskSubmission> {
  final List<String> _skills = [];
  final TextEditingController _skillController = TextEditingController();
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;
  final Uuid _uuid = Uuid();

  Future<void> _postTask() async {
    setState(() {
      _isLoading = true;
    });

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Fluttertoast.showToast(
        msg: "Please log in to post a task",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      Navigator.pushNamed(context, '/login'); // Navigate to the login screen
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      String taskId = _uuid.v4();

      await FirebaseFirestore.instance.collection('tasks').doc(taskId).set({
        'taskId': taskId,
        'projectName': _projectNameController.text,
        'category': _selectedCategory,
        'location': _locationController.text,
        'minBudget': _minController.text,
        'maxBudget': _maxController.text,
        'description': _descriptionController.text,
        'skills': _skills,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'bidderCount': 0, // Initialize bidder count to 0
      });

      Fluttertoast.showToast(
        msg: "Task posted successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // Clear the form data
      _projectNameController.clear();
      _locationController.clear();
      _minController.clear();
      _maxController.clear();
      _descriptionController.clear();
      _skillController.clear();
      setState(() {
        _skills.clear();
        _selectedCategory = null;
      });

      // Notify all freelancer users
      await _notifyFreelancers(taskId, _projectNameController.text);

      Navigator.pop(context); // Navigate back to TaskScreen
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to post task: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _notifyFreelancers(String taskId, String projectName) async {
    try {
      // Fetch all freelancer users
      QuerySnapshot freelancerSnapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .where('userType', isEqualTo: 'freelancer')
          .get();

      // Create a batch to perform multiple writes
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (QueryDocumentSnapshot freelancer in freelancerSnapshot.docs) {
        // Create notification document for each freelancer
        DocumentReference notificationRef = FirebaseFirestore.instance
            .collection('notifications')
            .doc(freelancer.id)
            .collection('userNotifications')
            .doc();

        batch.set(notificationRef, {
          'notificationId': notificationRef.id,
          'taskId': taskId,
          'projectName': projectName,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      // Commit the batch
      await batch.commit();
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to send notifications: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Submission',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _projectNameController,
                  decoration: InputDecoration(
                    labelText: 'Project Name',
                    labelStyle: GoogleFonts.poppins(
                      textStyle: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black),
                    ),
                    hintText: 'e.g. build me a website',
                    border: OutlineInputBorder(),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: GoogleFonts.poppins(
                      textStyle: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black),
                    ),
                    border: OutlineInputBorder(),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  items: <String>['Full Stack', 'Cyber Security', 'IoT', "BlockChain", "ML/DL", "AR VR"]
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: GoogleFonts.poppins(
                        textStyle: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black),
                      ),),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  value: _selectedCategory,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    labelStyle: GoogleFonts.poppins(
                      textStyle: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black),
                    ),
                    hintText: 'Anywhere',
                    border: OutlineInputBorder(),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minController,
                        decoration: InputDecoration(
                          labelText: 'Minimum',
                          labelStyle: GoogleFonts.poppins(
                            textStyle: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black),
                          ),
                          border: OutlineInputBorder(),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: TextFormField(
                        controller: _maxController,
                        decoration: InputDecoration(
                          labelText: 'Maximum',
                          labelStyle: GoogleFonts.poppins(
                            textStyle: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black),
                          ),
                          border: OutlineInputBorder(),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Describe Your Project',
                    labelStyle: GoogleFonts.poppins(
                      textStyle: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black),
                    ),
                    border: OutlineInputBorder(),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 16.0),
                Text(
                  'What skills are required?',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _skillController,
                        decoration: InputDecoration(
                          hintText: 'Add Skills',
                          hintStyle: GoogleFonts.poppins(
                            textStyle: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black),
                          ),
                          border: OutlineInputBorder(),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          if (_skillController.text.isNotEmpty) {
                            _skills.add(_skillController.text);
                            _skillController.clear();
                          }
                        });
                      },
                      child: const Icon(Icons.add, color: Colors.white,),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Wrap(
                  children: _skills.map((skill) => Chip(
                    label: Text(skill),
                    onDeleted: () {
                      setState(() {
                        _skills.remove(skill);
                      });
                    },
                  )).toList(),
                ),
                const SizedBox(height: 10.0),
                Center(
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton.icon(
                    onPressed: _postTask,
                    icon: const Icon(Icons.task, color: Colors.white),
                    label: Text(
                      'Post Task',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 50.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
