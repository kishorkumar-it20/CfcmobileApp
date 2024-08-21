import 'package:cfcapp/BasePage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      _user = _auth.currentUser;
      if (_user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('profiles').doc(_user!.uid).get();
        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>?;
          });
        } else {
          print("User document does not exist");
        }
      } else {
        print("No current user");
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _buildReviewList() {
    if (_userData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('freelancerId') // Filter reviews by freelancer's ID
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('No reviews available.', style: TextStyle(color: Colors.white)));
        }

        return ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: snapshot.data!.docs.map((document) {
            Map<String, dynamic> data = document.data() as Map<String, dynamic>;
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('profiles').doc(data['clientId']).get(),
              builder: (context, clientSnapshot) {
                if (clientSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!clientSnapshot.hasData || !clientSnapshot.data!.exists) {
                  return const ListTile(
                    title: Text('Unknown Client', style: TextStyle(color: Colors.greenAccent)),
                    subtitle: Text('Review data missing', style: TextStyle(color: Colors.white)),
                  );
                }

                Map<String, dynamic> clientData = clientSnapshot.data!.data() as Map<String, dynamic>;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(clientData['profileImage'] ?? 'https://example.com/default-profile.jpg'),
                  ),
                  title: Text(clientData['name'] ?? 'Unknown Client', style: GoogleFonts.poppins(color: Colors.greenAccent)),
                  subtitle: Text(data['reviewText'], style: GoogleFonts.poppins(color: Colors.white)),
                  trailing: Text(
                    (data['timestamp'] as Timestamp).toDate().toString(),
                    style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      body: _userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      _userData!['profileImage'] ?? 'https://example.com/default-profile.jpg',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userData!['name'] ?? 'No Name',
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (_userData!['specialization'] != null)
                              const Icon(Icons.workspace_premium_sharp, color: Colors.white, size: 18),
                            const SizedBox(width: 5),
                            Text(
                              _userData!['specialization'] ?? 'No Specialization',
                              style: GoogleFonts.poppins(
                                textStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_userData!['userType'] == 'client') ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (_userData!['companyDetails'] != null)
                                const Icon(Icons.work_outline_sharp, color: Colors.white, size: 18),
                              const SizedBox(width: 5),
                              Text(
                                _userData!['companyDetails'] ?? 'No Company Details',
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              IconButton(
                                icon: const Icon(Icons.share, color: Colors.greenAccent),
                                onPressed: () {
                                  // Handle share action
                                },
                              ),
                              const SizedBox(width: 5),
                              IconButton(
                                icon: const Icon(Icons.message, color: Colors.greenAccent),
                                onPressed: () {
                                  // Handle message action
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Skills',
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _userData!['skills'] != null
                    ? List<Widget>.from(
                  (_userData!['skills'] as List).map<Widget>(
                        (skill) => Chip(
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
                    ),
                  ),
                )
                    : [],
              ),
              const SizedBox(height: 20),
              Text(
                'About',
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  _userData!['about'] ?? 'Every Task Has New Learning',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Expertise',
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_userData!['userType'] == 'client' && _userData!['socialMediaLinks'] != null)
                ElevatedButton.icon(
                  icon: const Icon(FontAwesomeIcons.link, color: Colors.white),
                  label: Text(
                    'Portfolio',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  onPressed: () {
                    _launchURL(_userData!['socialMediaLinks']);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                _userData!['userType'] == 'freelancer'
                    ? 'Bids: ${_userData!['bidsCount'] ?? 0}'
                    : 'Tasks: ${_userData!['tasksPosted'] ?? 0}',
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Reviews',
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildReviewList(),
            ],
          ),
        ),
      ),
    );
  }
}
