import 'package:cfcapp/BasePage.dart';
import 'package:cfcapp/Screens/Widgets/ManageBidsProfile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ManageBids extends StatefulWidget {
  const ManageBids({super.key});

  @override
  State<ManageBids> createState() => _ManageBidsState();
}

class _ManageBidsState extends State<ManageBids> {
  late final User? currentUser;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('tasks')
            .where('userId', isEqualTo: currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No tasks posted.'));
          }
          final tasks = snapshot.data!.docs.map((doc) => Task.fromDocument(doc)).toList();

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  color: Colors.white12,
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.projectName,
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontStyle: FontStyle.normal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                task.location,
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            Icon(Icons.category, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                task.category,
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BidderProfilesScreen(taskId: task.taskId, ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.people),
                              label: Text(
                                'Manage Bidders (${task.bidderCount})',
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                backgroundColor: Colors.greenAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            IconButton(
                              onPressed: () {
                                // Delete task
                              },
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class Task {
  final String taskId;
  final String projectName;
  final String location;
  final String category;
  final int bidderCount;

  Task({
    required this.taskId,
    required this.projectName,
    required this.location,
    required this.category,
    required this.bidderCount,
  });

  factory Task.fromDocument(DocumentSnapshot doc) {
    return Task(
      taskId: doc.id,
      projectName: doc['projectName'],
      location: doc['location'],
      category: doc['category'],
      bidderCount: doc['bidderCount'],
    );
  }
}
