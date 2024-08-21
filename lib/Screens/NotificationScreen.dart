import 'package:cfcapp/BasePage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<Map<String, dynamic>> _fetchAdditionalData(String taskId, String userId) async {
    // Fetch task details
    DocumentSnapshot taskSnapshot =
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).get();
    Map<String, dynamic> taskData = taskSnapshot.data() as Map<String, dynamic>;

    // Fetch user profile
    DocumentSnapshot profileSnapshot =
    await FirebaseFirestore.instance.collection('profiles').doc(userId).get();
    Map<String, dynamic> profileData = profileSnapshot.data() as Map<String, dynamic>;

    return {'task': taskData, 'profile': profileData};
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("Please log in to view notifications."));
    }

    return BasePage(
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .doc(user.uid)
            .collection('userNotifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notifications found."));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> notificationData = doc.data() as Map<String, dynamic>;

              if (notificationData['type'] == 'bid_approved') {
                return ListTile(
                  title: Text(
                    notificationData['message'] ?? '',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  subtitle: Text(
                    notificationData['timestamp'] != null
                        ? (notificationData['timestamp'] as Timestamp).toDate().toString()
                        : '',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  trailing: notificationData['read'] == true
                      ? null
                      : const Icon(Icons.circle, color: Colors.redAccent, size: 12),
                  onTap: () async {
                    // Mark notification as read
                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(user.uid)
                        .collection('userNotifications')
                        .doc(doc.id)
                        .update({'read': true});
                  },
                );
              }

              return FutureBuilder<Map<String, dynamic>>(
                future: _fetchAdditionalData(notificationData['taskId'], user.uid),
                builder: (context, AsyncSnapshot<Map<String, dynamic>> asyncSnapshot) {
                  if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!asyncSnapshot.hasData) {
                    return const Center(child: Text("Error fetching details."));
                  }

                  Map<String, dynamic> taskData = asyncSnapshot.data!['task'];
                  Map<String, dynamic> profileData = asyncSnapshot.data!['profile'];

                  // Use null checks and default values
                  String name = profileData['name'] ?? 'Unknown';
                  String profileImage = profileData['profileImage'] ?? '';
                  String projectName = taskData['projectName'] ?? 'Unknown Project';
                  String taskId = taskData['taskId'] ?? 'Unknown Task ID';
                  List<dynamic> skillsList = taskData['skills'] ?? [];
                  String skills = skillsList.join(', ');

                  return Container(
                    color: Colors.white24,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(profileImage),
                        backgroundColor: profileImage.isEmpty ? Colors.grey : null,
                      ),
                      title: Text(
                        name,
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            projectName,
                            style: GoogleFonts.poppins(
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: skillsList.map<Widget>((skill) {
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
                        ],
                      ),
                      trailing: notificationData['read'] == true
                          ? null
                          : const Icon(Icons.circle, color: Colors.redAccent, size: 12),
                      onTap: () async {
                        // Mark notification as read
                        await FirebaseFirestore.instance
                            .collection('notifications')
                            .doc(user.uid)
                            .collection('userNotifications')
                            .doc(doc.id)
                            .update({'read': true});
                      },
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
