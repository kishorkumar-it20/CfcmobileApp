import 'package:cfcapp/Screens/ManageBids.dart';
import 'package:cfcapp/Screens/ReviewSystem/ClientReview.dart';
import 'package:cfcapp/Screens/TaskScreen.dart';
import 'package:cfcapp/Screens/Widgets/Clients.dart';
import 'package:cfcapp/Screens/Widgets/Freelancers.dart';
import 'package:cfcapp/Screens/Widgets/IndividualBids.dart';
import 'package:cfcapp/Screens/Widgets/Myprofile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cfcapp/Screens/PostTask.dart';


class CustomBottomBar extends StatelessWidget {
  final String userType;

  const CustomBottomBar({required this.userType, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            height: 60.0,
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _buildBottomBarItems(context),
            ),
          ),
        ),
        if (userType == 'client') // Show floating button only for clients
          Positioned(
            bottom: 40.0, // Adjust as needed
            right: 180.0,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TaskSubmission()),
                );
              },
              child: const Icon(Icons.add),
              backgroundColor: Colors.greenAccent,
              elevation: 5,
            ),
          ),
      ],
    );
  }

  List<Widget> _buildBottomBarItems(BuildContext context) {
    if (userType == 'client') {
      return [
        _buildBottomBarItem(context, Icons.people, 'Freelancers',const Freelanscer()),
        _buildBottomBarItem(context, Icons.gavel, 'Manage Bid',const ManageBids()),
        const SizedBox(width: 50), // Space for the floating button
        _buildBottomBarItem(context, Icons.star, 'Reviews', ClientReview()),
        _buildBottomBarItem(context, Icons.person, 'My Profile', UserProfilePage()),
      ];
    } else {
      return [
        _buildBottomBarItem(context, Icons.assignment, 'Task', const TaskScreen()),
        _buildBottomBarItem(context, Icons.person, 'Clients', const Clients()),
        _buildBottomBarItem(context, Icons.local_offer, 'My Bids', const MyBidsScreen()),
        _buildBottomBarItem(context, Icons.rate_review, 'Review', null),
        _buildBottomBarItem(context, Icons.person_2_rounded, 'My Profile',UserProfilePage()),
      ];
    }
  }

  Widget _buildBottomBarItem(BuildContext context, IconData icon, String label, Widget? page) {
    return GestureDetector(
      onTap: () {
        if (page != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.greenAccent), // Set icon color to green accent
          Text(
            label,
            style: GoogleFonts.poppins(
              textStyle: const TextStyle(
                fontSize: 10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
