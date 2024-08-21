import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cfcapp/BasePage.dart';
import 'package:google_fonts/google_fonts.dart';

class Clients extends StatefulWidget {
  const Clients({super.key});

  @override
  State<Clients> createState() => _ClientsState();
}

class _ClientsState extends State<Clients> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Client>> fetchClients() async {
    QuerySnapshot snapshot = await _firestore
        .collection('profiles')
        .where('userType', isEqualTo: 'client')
        .get();
    return snapshot.docs
        .map((doc) => Client.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      body: FutureBuilder<List<Client>>(
        future: fetchClients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching clients'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No clients found'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final client = snapshot.data![index];
              return ClientProfileCard(client: client);
            },
          );
        },
      ),
    );
  }
}

class ClientProfileCard extends StatelessWidget {
  final Client client;

  const ClientProfileCard({Key? key, required this.client}) : super(key: key);

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
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(client.profileImage),
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
                    client.name,
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.business, color: Colors.white70, size: 16),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          client.companyDetails,
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.white70, size: 16),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          client.specialization,
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class Client {
  final String name;
  final String profileImage;
  final String specialization;
  final String companyDetails;
  final String userType;

  Client({
    required this.name,
    required this.profileImage,
    required this.specialization,
    required this.companyDetails,
    required this.userType,
  });

  factory Client.fromMap(Map<String, dynamic> data) {
    return Client(
      name: data['name'],
      profileImage: data['profileImage'],
      specialization: data['specialization'],
      companyDetails: data['companyDetails'],
      userType: data['userType'],
    );
  }
}
