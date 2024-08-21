import 'package:cfcapp/BasePage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyBidsScreen extends StatefulWidget {
  const MyBidsScreen({super.key});

  @override
  State<MyBidsScreen> createState() => _MyBidsScreenState();
}

class _MyBidsScreenState extends State<MyBidsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final User? currentUser;
  List<Map<String, dynamic>> myBids = [];

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    fetchMyBids();
  }

  Future<void> fetchMyBids() async {
    if (currentUser == null) return;

    final QuerySnapshot snapshot = await _firestore
        .collection('bids')
        .where('userId', isEqualTo: currentUser!.uid)
        .get();

    final List<Map<String, dynamic>> fetchedBids = [];

    for (var doc in snapshot.docs) {
      final taskSnapshot = await _firestore
          .collection('tasks')
          .doc(doc['taskId'])
          .get();

      if (taskSnapshot.exists) {
        final taskData = taskSnapshot.data() as Map<String, dynamic>;
        taskData['bidAmount'] = doc['bidAmount'];
        fetchedBids.add(taskData);
      }
    }

    setState(() {
      myBids = fetchedBids;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 70.0),
            child: Column(
              children: [
                Text(
                  'My Bids',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Expanded(
                  child: ListView.builder(
                    itemCount: myBids.length,
                    itemBuilder: (context, index) {
                      final bid = myBids[index];
                      final skills = bid['skills'] ?? [];
                      return Card(
                        color: Colors.grey[850],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    bid['projectName'] ?? 'No title',
                                    style: GoogleFonts.poppins(
                                      textStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, color: Colors.white70, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        bid['time'] ?? 'No time',
                                        style: GoogleFonts.poppins(
                                          textStyle: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                bid['minBudget'] != null && bid['maxBudget'] != null
                                    ? '\$${bid['minBudget']}-\$${bid['maxBudget']}'
                                    : 'No budget',
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                'Bid Amount: \$${bid['bidAmount']}',
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    color: Colors.greenAccent,
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
                                          color: Colors.black38,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    backgroundColor: Colors.yellowAccent,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
