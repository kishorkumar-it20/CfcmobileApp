import 'package:cfcapp/BasePage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskProfileScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const TaskProfileScreen({super.key, required this.job});

  @override
  State<TaskProfileScreen> createState() => _TaskProfileScreenState();
}

class _TaskProfileScreenState extends State<TaskProfileScreen> {
  bool hasBid = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    checkIfUserHasBid();
  }

  Future<void> checkIfUserHasBid() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final bidSnapshot = await FirebaseFirestore.instance
        .collection('bids')
        .where('userId', isEqualTo: currentUser.uid)
        .where('taskId', isEqualTo: widget.job['taskId'])
        .get();

    if (bidSnapshot.docs.isNotEmpty) {
      setState(() {
        hasBid = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final skills = widget.job['skills'] ?? [];

    return BasePage(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: widget.job['logoUrl'] != null
                              ? Image.network(widget.job['logoUrl'], fit: BoxFit.cover)
                              : const Icon(Icons.work_outline_rounded, size: 50, color: Colors.white),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.job['projectName'] ?? 'No title',
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                widget.job['category'] ?? 'No category',
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                widget.job['location'] ?? 'No location',
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                '\$${widget.job['minBudget'] ?? 'N/A'} - \$${widget.job['maxBudget'] ?? 'N/A'}',
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'Skills Required',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: skills.map<Widget>((skill) {
                        return Chip(
                          label: Text(
                            skill,
                            style: GoogleFonts.poppins(
                              textStyle: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          backgroundColor: Colors.yellowAccent,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'Description',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      widget.job['description'] ?? 'No description',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: ElevatedButton(
                  onPressed: hasBid ? null : () => _showBidDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    hasBid ? 'Bid Placed' : 'Bid Now',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBidDialog(BuildContext context) {
    final TextEditingController bidController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Place Your Bid',
            style: GoogleFonts.poppins(
              textStyle: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          content: TextField(
            controller: bidController,
            decoration: InputDecoration(
              hintText: 'Enter your bid amount',
              hintStyle: GoogleFonts.poppins(
                textStyle: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final User? currentUser = _auth.currentUser;
                if (currentUser == null) return;

                final bidAmount = bidController.text;
                if (bidAmount.isNotEmpty) {
                  // Add bid entry to 'bids' collection
                  await FirebaseFirestore.instance.collection('bids').add({
                    'userId': currentUser.uid,
                    'taskId': widget.job['taskId'],
                    'bidAmount': bidAmount,
                    'timestamp': Timestamp.now(),
                    'bidApproved': false, // New field added for approval status
                  });

                  // Increment the bid count for the task
                  await FirebaseFirestore.instance.collection('tasks').doc(widget.job['taskId']).update({
                    'bidderCount': FieldValue.increment(1),
                  });

                  // Create notification for the client
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(widget.job['userId'])
                      .collection('userNotifications')
                      .add({
                    'clientId': widget.job['userId'],
                    'taskId': widget.job['taskId'],
                    'projectName': widget.job['projectName'],
                    'timestamp': Timestamp.now(),
                    'read': false,
                    'profileImage': currentUser.photoURL ?? '',
                    'name': currentUser.displayName ?? 'Freelancer',
                  });

                  setState(() {
                    hasBid = true;
                  });

                  Navigator.of(context).pop();
                }
              },
              child: Text(
                'Submit',
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
