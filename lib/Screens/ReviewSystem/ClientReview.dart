import 'package:cfcapp/BasePage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ClientReview extends StatefulWidget {
  const ClientReview({super.key});

  @override
  State<ClientReview> createState() => _ClientReviewState();
}

class _ClientReviewState extends State<ClientReview> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _freelancerUsernameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _submitReview() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? user = _auth.currentUser;
        if (user != null && _freelancerUsernameController.text.isNotEmpty) {
          QuerySnapshot freelancerSnapshot = await FirebaseFirestore.instance
              .collection('profiles')
              .where('username', isEqualTo: _freelancerUsernameController.text)
              .get();

          if (freelancerSnapshot.docs.isNotEmpty) {
            String freelancerId = freelancerSnapshot.docs.first.id;

            try {
              await FirebaseFirestore.instance.collection('reviews').add({
                'clientId': user.uid,
                'freelancerId': freelancerId,
                'freelancerUsername': _freelancerUsernameController.text,
                'reviewText': _reviewController.text,
                'timestamp': FieldValue.serverTimestamp(),
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Review posted successfully!')),
              );

              _reviewController.clear();
              _freelancerUsernameController.clear();
            } catch (e) {
              print('Failed to post review: $e');
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Freelancer not found')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter the freelancer\'s username')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post review: $e')),
        );
      }
    }
  }

  Future<void> _editReview(String reviewId) async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('reviews').doc(reviewId).update({
          'reviewText': _reviewController.text,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review updated successfully!')),
        );

        _reviewController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update review: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Post a Review',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _freelancerUsernameController,
                      style: GoogleFonts.poppins(color: Colors.greenAccent),
                      decoration: InputDecoration(
                        labelText: 'Freelancer Username',
                        labelStyle: GoogleFonts.poppins(
                          textStyle: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the freelancer\'s username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _reviewController,
                      style: GoogleFonts.poppins(color: Colors.greenAccent),
                      decoration: InputDecoration(
                        labelText: 'Write your review here',
                        labelStyle: GoogleFonts.poppins(
                          textStyle: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your review';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                      child: Text(
                        'Submit Review',
                        style: GoogleFonts.poppins(color: Colors.black, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Posted Reviews',
              style: GoogleFonts.poppins(color: Colors.greenAccent),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reviews')
                    .where('clientId', isEqualTo: _auth.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No reviews found.', style: TextStyle(color: Colors.white)));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot reviewDoc = snapshot.data!.docs[index];
                      String reviewId = reviewDoc.id;
                      String reviewText = reviewDoc['reviewText'];
                      String freelancerId = reviewDoc['freelancerId'];

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('profiles').doc(freelancerId).get(),
                        builder: (context, freelancerSnapshot) {
                          if (!freelancerSnapshot.hasData) {
                            return const CircularProgressIndicator();
                          }

                          String freelancerName = freelancerSnapshot.data!['name'];
                          String profilePicUrl = freelancerSnapshot.data!['profileImage'];

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(profilePicUrl),
                              ),
                              title: Text(freelancerName, style: GoogleFonts.poppins(color: Colors.white)),
                              subtitle: Text(reviewText, style: GoogleFonts.poppins(color: Colors.greenAccent)),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.greenAccent),
                                onPressed: () {
                                  _reviewController.text = reviewText;
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: Colors.black,
                                      title: const Text('Edit Review', style: TextStyle(color: Colors.white)),
                                      content: Form(
                                        key: _formKey,
                                        child: TextFormField(
                                          controller: _reviewController,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: const InputDecoration(
                                            labelText: 'Review',
                                            labelStyle: TextStyle(color: Colors.greenAccent),
                                          ),
                                          maxLines: 3,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            _editReview(reviewId);
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Save', style: TextStyle(color: Colors.greenAccent)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
