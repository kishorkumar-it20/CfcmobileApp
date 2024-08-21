import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  _ProfileSetupScreenState createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController specializationController = TextEditingController();
  final TextEditingController skillController = TextEditingController();
  final TextEditingController socialMediaLinksController = TextEditingController();
  final TextEditingController companyDetailsController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  String userType = 'freelancer'; // default selection
  List<String> skills = [];
  File? profileImage;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        profileImage = File(pickedFile.path);
      } else {
        Fluttertoast.showToast(msg: "No image selected", backgroundColor: Colors.red);
      }
    });
  }

  Future<void> uploadProfileImage(String userId) async {
    if (profileImage == null) return;
    final ref = FirebaseStorage.instance.ref().child('profile_images').child('$userId.jpg');
    await ref.putFile(profileImage!);
    final url = await ref.getDownloadURL();
    await FirebaseFirestore.instance.collection('profiles').doc(userId).update({'profileImage': url});
  }

  Future<void> saveProfile(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    final username = usernameController.text;

    try {
      // Check if the username already exists
      final querySnapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .where('username', isEqualTo: username)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Username already exists
        Fluttertoast.showToast(msg: "Username already exists, try again", backgroundColor: Colors.red);
        return;
      }

      final profileData = {
        'name': nameController.text,
        'username': username,
        'specialization': specializationController.text,
        'skills': skills,
        'socialMediaLinks': socialMediaLinksController.text,
        'companyDetails': companyDetailsController.text,
        'userType': userType,
      };

      await FirebaseFirestore.instance.collection('profiles').doc(userId).set(profileData);
      await uploadProfileImage(userId);

      // Check if the profile document exists
      final doc = await FirebaseFirestore.instance.collection('profiles').doc(userId).get();
      if (doc.exists) {
        Fluttertoast.showToast(msg: "Profile setup complete", backgroundColor: Colors.green);
        Navigator.pushReplacementNamed(context, userType == 'client' ? '/topfreelancers' : '/taskScreen');
      } else {
        Fluttertoast.showToast(msg: "Profile not found after saving", backgroundColor: Colors.red);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString(), backgroundColor: Colors.red);
    }
  }

  Future<void> fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Fluttertoast.showToast(msg: "User not authenticated", backgroundColor: Colors.red);
      return;
    }

    final userId = user.uid;
    final doc = await FirebaseFirestore.instance.collection('profiles').doc(userId).get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        setState(() {
          nameController.text = data['name'] ?? '';
          specializationController.text = data['specialization'] ?? '';
          skills = List<String>.from(data['skills'] ?? []);
          socialMediaLinksController.text = data['socialMediaLinks'] ?? '';
          companyDetailsController.text = data['companyDetails'] ?? '';
          userType = data['userType'] ?? 'freelancer';
          usernameController.text = data['username'] ?? '';
        });
      }
    } else {
      Fluttertoast.showToast(msg: "User profile not found", backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Profile Setup', style: GoogleFonts.poppins(color: Colors.greenAccent)),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: profileImage != null ? FileImage(profileImage!) : null,
                    child: profileImage == null
                        ? Icon(Icons.camera_alt, size: 50, color: Colors.greenAccent)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: GoogleFonts.poppins(
                    textStyle: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white),
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  prefixIcon: const Icon(Icons.person, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: specializationController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Specialization',
                  labelStyle: GoogleFonts.poppins(
                    textStyle: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white),
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  prefixIcon: const Icon(Icons.work, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: skillController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Skills',
                  labelStyle: GoogleFonts.poppins(
                    textStyle: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white),
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  prefixIcon: const Icon(Icons.star, color: Colors.white),
                ),
                onSubmitted: (value) {
                  setState(() {
                    skills.add(value);
                    skillController.clear();
                  });
                },
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8.0,
                children: skills.map((skill) {
                  return Chip(
                    label: Text(skill, style: GoogleFonts.poppins(color: Colors.white)),
                    backgroundColor: Colors.green,
                    deleteIcon: const Icon(Icons.cancel, color: Colors.white),
                    onDeleted: () {
                      setState(() {
                        skills.remove(skill);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: socialMediaLinksController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Social Media Links',
                  labelStyle: GoogleFonts.poppins(
                    textStyle: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white),
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  prefixIcon: const Icon(Icons.link, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: companyDetailsController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Company Details',
                  labelStyle: GoogleFonts.poppins(
                    textStyle: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white),
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  prefixIcon: const Icon(Icons.business, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: userType,
                dropdownColor: Colors.black,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'User Type',
                  labelStyle: GoogleFonts.poppins(
                    textStyle: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white),
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  prefixIcon: const Icon(Icons.person, color: Colors.white),
                ),
                items: <String>['freelancer', 'client'].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    userType = newValue!;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: GoogleFonts.poppins(
                    textStyle: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white),
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  prefixIcon: const Icon(Icons.person, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => saveProfile(context),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Save Profile',
                      style: GoogleFonts.poppins(color: Colors.black, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
