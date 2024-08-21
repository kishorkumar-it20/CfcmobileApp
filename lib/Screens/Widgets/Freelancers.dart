import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cfcapp/BasePage.dart';
import 'package:google_fonts/google_fonts.dart';

class Freelanscer extends StatefulWidget {
  const Freelanscer({super.key});

  @override
  State<Freelanscer> createState() => _FreelanscerState();
}

class _FreelanscerState extends State<Freelanscer> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Freelancer>> fetchFreelancers() async {
    QuerySnapshot snapshot = await _firestore
        .collection('profiles')
        .where('userType', isEqualTo: 'freelancer')
        .get();
    return snapshot.docs
        .map((doc) => Freelancer.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      body: FutureBuilder<List<Freelancer>>(
        future: fetchFreelancers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching freelancers'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No freelancers found'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final freelancer = snapshot.data![index];
              return FreelancerProfileCard(freelancer: freelancer);
            },
          );
        },
      ),
    );
  }
}

class FreelancerProfileCard extends StatelessWidget {
  final Freelancer freelancer;

  const FreelancerProfileCard({Key? key, required this.freelancer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white12,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(10), // Border radius for profile picture
                image: DecorationImage(
                  image: NetworkImage(freelancer.profileImageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    freelancer.name,
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Text(freelancer.specialization, style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: freelancer.skills.map((skill) {
                      return Chip(
                        label: Text(
                          skill,
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        backgroundColor: Colors.greenAccent.withOpacity(0.8), // Yellow background for skills
                      );
                    }).toList(),
                  ),
                  // const SizedBox(height: 10),
                  // Align(
                  //   alignment: Alignment.bottomRight,
                  //   child: Container(
                  //     decoration: BoxDecoration(
                  //       color: Colors.greenAccent,
                  //       borderRadius: BorderRadius.circular(10),
                  //     ),
                  //     child: ElevatedButton(
                  //       onPressed: () {
                  //         // Handle bid action
                  //       },
                  //       style: ElevatedButton.styleFrom(
                  //         elevation: 0,
                  //         backgroundColor: Colors.transparent,
                  //         shadowColor: Colors.transparent,
                  //       ),
                  //       child: Text(
                  //         'View Profile',
                  //         style: GoogleFonts.poppins(
                  //           textStyle: const TextStyle(
                  //             fontSize: 16,
                  //             fontStyle: FontStyle.italic,
                  //             color: Colors.white,
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Freelancer {
  final String name;
  final String profileImageUrl;
  final List<String> skills;
  final String socialMediaLinks;
  final String specialization;
  final String userType;

  Freelancer({
    required this.name,
    required this.profileImageUrl,
    required this.skills,
    required this.socialMediaLinks,
    required this.specialization,
    required this.userType,
  });

  factory Freelancer.fromMap(Map<String, dynamic> data) {
    return Freelancer(
      name: data['name'],
      profileImageUrl: data['profileImage'],
      skills: List<String>.from(data['skills']),
      socialMediaLinks: data['socialMediaLinks'],
      specialization: data['specialization'],
      userType: data['userType'],
    );
  }
}
