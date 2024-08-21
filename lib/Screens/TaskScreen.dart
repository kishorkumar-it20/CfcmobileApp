import 'package:cfcapp/BasePage.dart';
import 'package:cfcapp/Screens/TaskProfile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  List<Map<String, dynamic>> jobs = [];
  List<Map<String, dynamic>> filteredJobs = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, bool> bidStatus = {};
  String searchQuery = '';
  List<String> selectedSkills = [];

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  Future<void> fetchJobs() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .orderBy('timestamp', descending: true)
        .get();
    final List<Map<String, dynamic>> fetchedJobs =
    snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    setState(() {
      jobs = fetchedJobs;
      filteredJobs = fetchedJobs;
      fetchBidStatus();
    });
  }

  Future<void> fetchBidStatus() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final bidSnapshot = await FirebaseFirestore.instance
        .collection('bids')
        .where('userId', isEqualTo: currentUser.uid)
        .get();

    final Map<String, bool> fetchedBidStatus = {};
    for (var doc in bidSnapshot.docs) {
      fetchedBidStatus[doc['taskId']] = true;
    }

    setState(() {
      bidStatus = fetchedBidStatus;
    });
  }

  void filterJobs() {
    List<Map<String, dynamic>> tempJobs = jobs.where((job) {
      final matchesSearchQuery =
          job['projectName']?.toLowerCase().contains(searchQuery.toLowerCase()) ??
              false;
      final matchesSkills = selectedSkills.isEmpty ||
          (job['skills'] as List<dynamic>)
              .map((skill) => skill.toString().toLowerCase())
              .toSet()
              .containsAll(selectedSkills.map((skill) => skill.toLowerCase()));
      return matchesSearchQuery && matchesSkills;
    }).toList();

    setState(() {
      filteredJobs = tempJobs;
    });
  }

  void showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return FilterDialog(
          selectedSkills: selectedSkills,
          onApply: (List<String> skills) {
            setState(() {
              selectedSkills = skills;
            });
            filterJobs();
            Navigator.pop(context);
          },
        );
      },
    );
  }


  String timeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        filterJobs();
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  onPressed: showFilterDialog,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredJobs.length,
              itemBuilder: (context, index) {
                final job = filteredJobs[index];
                final hasBid = bidStatus[job['taskId']] ?? false;
                final skills = job['skills'] ?? [];
                final timestamp = job['timestamp'] != null
                    ? (job['timestamp'] as Timestamp).toDate()
                    : null;
                final formattedTime = timestamp != null
                    ? timeAgo(timestamp)
                    : 'N/A';

                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  color: Colors.white.withOpacity(0.24),
                  child: Stack(
                    children: [
                      ListTile(
                        title: Text(
                          job['projectName'] ?? 'No title',
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job['category'] ?? 'No category',
                              style: GoogleFonts.poppins(
                                textStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: skills.map<Widget>((skill) {
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
                        trailing: Text(
                          '\$${job['minBudget'] ?? 'N/A'} - \$${job['maxBudget'] ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TaskProfileScreen(job: job),
                            ),
                          );
                        },
                        leading: hasBid
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                      ),
                      Positioned(
                        right: 8.0,
                        top: 8.0,
                        child: Text(
                          formattedTime,
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FilterDialog extends StatefulWidget {
  final List<String> selectedSkills;
  final Function(List<String>) onApply;

  const FilterDialog({
    super.key,
    required this.selectedSkills,
    required this.onApply,
  });

  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  List<String> tempSelectedSkills = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    tempSelectedSkills = List.from(widget.selectedSkills);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> allSkills = [
      'Fullstack',
      'ML/DL',
      'AV/VR',
      'IoT',
      'DM'
    ];

    return Dialog(
      backgroundColor: Colors.black,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Filter by Skills',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: GoogleFonts.poppins(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
            Expanded(
              child: ListView(
                children: allSkills
                    .where((skill) => skill
                    .toLowerCase()
                    .contains(_searchController.text.toLowerCase()))
                    .map((skill) {
                  final isSelected = tempSelectedSkills.contains(skill);
                  return CheckboxListTile(
                    title: Text(
                      skill,
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          tempSelectedSkills.add(skill);
                        } else {
                          tempSelectedSkills.remove(skill);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.red)),
                  ),
                  TextButton(
                    onPressed: () => widget.onApply(tempSelectedSkills),
                    child: Text('Apply', style: GoogleFonts.poppins(color: Colors.green)),
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

