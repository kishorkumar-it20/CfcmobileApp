import 'package:cfcapp/Screens/ClientNotification.dart';
import 'package:cfcapp/Screens/NotificationScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAppBar extends StatefulWidget {
  const CustomAppBar({super.key});

  @override
  _CustomAppBarState createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  User? user;
  String? photoUrl;
  bool hasUnreadNotifications = false;
  String? userType;

  @override
  void initState() {
    super.initState();
    _getUser();
    _checkForUnreadNotifications();
  }

  Future<void> _getUser() async {
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch userType from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('profiles').doc(user!.uid).get();
      setState(() {
        photoUrl = user!.photoURL;
        userType = userDoc['userType'];
      });
    }
  }

  Future<void> _checkForUnreadNotifications() async {
    if (user != null) {
      FirebaseFirestore.instance
          .collection('notifications')
          .doc(user!.uid)
          .collection('userNotifications')
          .where('read', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          setState(() {
            hasUnreadNotifications = true;
          });
        } else {
          setState(() {
            hasUnreadNotifications = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          left: 20.0, top: 50.0, bottom: 20.0, right: 20.0),
      child: Container(
        height: 80.0,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10.0,
              spreadRadius: 5.0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipOval(
                child: Image.asset(
                  'assets/logo.jpg', // Your logo image
                  height: 40.0,
                  width: 40.0,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Text(
              'CFC',
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(
                    fontSize: 25,
                    fontStyle: FontStyle.italic,
                    color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications, color: Colors.white),
                        onPressed: () {
                          if (userType == 'client') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ClientNotificationsScreen()),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => NotificationsScreen()),
                            );
                          }
                        },
                      ),
                      if (hasUnreadNotifications)
                        Positioned(
                          right: 11,
                          top: 11,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: const Text(
                              ' ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (photoUrl != null)
                    PopupMenuButton<String>(
                      icon: CircleAvatar(
                        backgroundImage: NetworkImage(photoUrl!),
                      ),
                      onSelected: (String result) async {
                        if (result == 'Sign Out') {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushReplacementNamed(
                              context, '/introScreen');
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                         PopupMenuItem<String>(
                          value: 'Sign Out',
                          child: Text('Sign Out', style: GoogleFonts.poppins(
                            textStyle: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black),
                          ),),
                        ),
                      ],
                    )
                  else
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.person, color: Colors.white),
                      onSelected: (String result) async {
                        if (result == 'Sign Out') {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushReplacementNamed(
                              context, '/introScreen');
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                         PopupMenuItem<String>(
                          value: 'Sign Out',
                          child: Text('Sign Out',style: GoogleFonts.poppins(
                            textStyle: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black),
                          ),),
                        ),
                      ],
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
