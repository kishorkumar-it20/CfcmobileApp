import 'package:cfcapp/BasePage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class BidderProfilesScreen extends StatelessWidget {
  final String taskId;

  const BidderProfilesScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return BasePage(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bids')
            .where('taskId', isEqualTo: taskId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No bidders.'));
          }
          final bids = snapshot.data!.docs;

          return ListView.builder(
            itemCount: bids.length,
            itemBuilder: (context, index) {
              final bid = bids[index];
              final userId = bid['userId'];
              final bidAmount = bid['bidAmount'];
              final bidId = bid.id; // Get the bid document ID

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('profiles')
                    .doc(userId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!userSnapshot.hasData) {
                    return const SizedBox();
                  }
                  final user = userSnapshot.data!;
                  final userName = user['name'];
                  final userSkills = user['skills'];
                  final profileImage = user['profileImage'];

                  return Card(
                    color: Colors.white12,
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Stack(
                      children: [
                        ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(profileImage),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                userName,
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontStyle: FontStyle.normal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bid Amount: \$${bidAmount.toString()}',
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10,),
                              Wrap(
                                spacing: 4.0,
                                runSpacing: 4.0,
                                children: userSkills.map<Widget>((skill) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Text(
                                      skill,
                                      style: GoogleFonts.poppins(
                                        textStyle: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                '\$${bidAmount.toString()}',
                                style: GoogleFonts.poppins(
                                  textStyle: const  TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                'Fixed Price',
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: false,
                          contentPadding: const EdgeInsets.all(16.0),
                        ),
                        Positioned(
                          bottom: 10,
                          right: 16,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.greenAccent,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.check, color: Colors.black),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FreelancerProfileScreen(
                                      userId: userId,
                                      bidAmount: bidAmount.toString(),
                                      bidId: bidId, // Pass the bidId here
                                      taskId: taskId, // Pass the taskId here
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class FreelancerProfileScreen extends StatefulWidget {
  final String userId;
  final String bidAmount;
  final String bidId; // Add this parameter
  final String taskId; // Add this parameter

  const FreelancerProfileScreen({
    super.key,
    required this.userId,
    required this.bidAmount,
    required this.bidId, // Add this parameter
    required this.taskId, // Add this parameter
  });

  @override
  _FreelancerProfileScreenState createState() => _FreelancerProfileScreenState();
}

class _FreelancerProfileScreenState extends State<FreelancerProfileScreen> {
  bool isBidApproved = false;

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _approveBid(String bidId) async {
    try {
      // Update the bid status in Firestore
      await FirebaseFirestore.instance
          .collection('bids')
          .doc(bidId) // Ensure the correct bid document ID is used here
          .update({
        'status': 'approved',
        'bidApproved': true, // Update the `bidApproved` field as well if necessary
      });

      // Create a notification for the user
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(widget.userId)
          .collection('userNotifications')
          .add({
        'type': 'bid_approved',
        'taskId': widget.taskId,
        'message': 'Congrats! Your bid has been approved for task',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      setState(() {
        isBidApproved = true;
      });
    } catch (e) {
      print('Error approving bid: $e'); // Error log
    }
  }

  void _showApprovalDialog(String bidId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Approve Bid',
            style: GoogleFonts.poppins(fontSize: 18),
          ),
          content: Text(
            'Bidding Amount: \$${widget.bidAmount}',
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: isBidApproved
                  ? null
                  : () {
                _approveBid(bidId); // Pass the bidId here
                Navigator.of(context).pop();
              },
              child: Text(
                isBidApproved ? 'Approved' : 'Approve',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('profiles')
            .doc(widget.userId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Profile not found.'));
          }
          final user = snapshot.data!;
          final userName = user['name'];
          final userSkills = user['skills'];
          final profileImage = user['profileImage'];
          final portfolioUrl = user['portfolioUrl'];

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(profileImage),
              ),
              const SizedBox(height: 16),
              Text(
                userName,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4.0,
                runSpacing: 4.0,
                children: userSkills.map<Widget>((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      skill,
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _launchURL(portfolioUrl),
                child: Text(
                  'View Portfolio',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showApprovalDialog(widget.bidId), // Pass the bidId here
                child: Text(
                  isBidApproved ? 'Bid Approved' : 'Approve Bid',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
