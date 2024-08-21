import 'package:cfcapp/widgets/Appbar.dart';
import 'package:cfcapp/widgets/Bottombar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BasePage extends StatefulWidget {
  final Widget body;

  const BasePage({required this.body, Key? key}) : super(key: key);

  @override
  _BasePageState createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  String userType = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserType();
  }

  Future<void> _fetchUserType() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('User ID: ${user.uid}');
        final userDoc = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          print('User Document: ${userDoc.data()}');
          setState(() {
            userType = userDoc['userType'];
            isLoading = false;
          });
        } else {
          print('User document does not exist');
        }
      } else {
        print('No user is currently signed in');
      }
    } catch (e) {
      print('Error fetching user type: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const CustomAppBar(),
          Expanded(child: widget.body),
        ],
      ),
      bottomNavigationBar: isLoading
          ? const CircularProgressIndicator() // Show a loading indicator while fetching user type
          : CustomBottomBar(userType: userType),
    );
  }
}
