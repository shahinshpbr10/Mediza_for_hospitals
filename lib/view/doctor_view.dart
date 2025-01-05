import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../main.dart';

class DoctorDashboard extends StatefulWidget {
  final String email; // Using email to identify the doctor

  const DoctorDashboard({Key? key, required this.email}) : super(key: key);

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _leaveReasonController = TextEditingController();
  String? _clinicId;
  String? _doctorId;
  String _status = "";

  @override
  void initState() {
    super.initState();
    _fetchDoctorDetails(); // Fetch doctorId and clinicId on initialization
  }
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut(); // Firebase Logout
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => AuthWrapper()), // Navigate to login page
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }
  Future<void> _fetchDoctorDetails() async {
    try {
      QuerySnapshot doctorQuery = await FirebaseFirestore.instance
          .collection('clinics')
          .get();

      for (var clinicDoc in doctorQuery.docs) {
        var doctor = await clinicDoc.reference
            .collection('doctors')
            .where('email', isEqualTo: widget.email)
            .limit(1)
            .get();

        if (doctor.docs.isNotEmpty) {
          setState(() {
            _clinicId = clinicDoc.id;
            _doctorId = doctor.docs.first.id;
          });
          break;
        }
      }

      if (_doctorId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Doctor not found")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching doctor details: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_clinicId == null || _doctorId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Doctor Dashboard", style: GoogleFonts.poppins()),
          actions: [IconButton(onPressed: () => _logout(), icon: Icon(Iconsax.logout))],
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Doctor Dashboard", style: GoogleFonts.poppins()),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildStatusSection(),
            SizedBox(height: 20),
            _buildLeaveSection(),
            SizedBox(height: 20),
            _buildAssignedNursesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return _buildCard(
      title: "Update Status",
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            decoration: _inputDecoration("Status"),
            value: _status,
            items: [
              DropdownMenuItem(value: "Available", child: Text("Available")),
              DropdownMenuItem(value: "Late", child: Text("Late")),
              DropdownMenuItem(value: "On Leave", child: Text("On Leave")),
            ],
            onChanged: (value) {
              if (value == "Late") {
                _showLateReasonDialog();
              } else {
                setState(() {
                  _status = value!;
                });
               // _updateStatus(value!);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveSection() {
    return _buildCard(
      title: "Apply for Leave",
      child: Column(
        children: [
          TextField(
            controller: _leaveReasonController,
            decoration: _inputDecoration("Reason for Leave"),
            maxLines: 3,
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _applyForLeave,
            style: _buttonStyle(),
            child: Text("Submit Leave", style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedNursesSection() {
    return _buildCard(
      title: "Assigned Nurses",
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('clinics')
            .doc(_clinicId)
            .collection('assignments')
            .where('doctorId', isEqualTo: _doctorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Text("No nurses assigned.");
          }

          return ListView.builder(
            shrinkWrap: true,
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final assignment = snapshot.data!.docs[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('clinics')
                    .doc(_clinicId)
                    .collection('nurses')
                    .doc(assignment['nurseId'])
                    .get(),
                builder: (context, nurseSnapshot) {
                  if (!nurseSnapshot.hasData) {
                    return ListTile(title: Text("Loading nurse info..."));
                  }

                  final nurse = nurseSnapshot.data!;
                  return ListTile(
                    leading: Icon(Icons.person, color: Colors.blueAccent),
                    title: Text(nurse['name']),
                    subtitle: Text("Shift: ${assignment['shift']}"),
                    trailing: Text("Start: ${assignment['startTime']}"),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.grey[100],
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.blueAccent,
      padding: EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  // void _updateStatus(String status) {
  //   FirebaseFirestore.instance
  //       .collection('clinics')
  //       .doc(_clinicId)
  //       .collection('doctors')
  //       .doc(_doctorId)
  //       .update({'status': status});
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text("Status updated to $status")),
  //   );
  // }

  void _applyForLeave() {
    final leaveReason = _leaveReasonController.text.trim();
    if (leaveReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please provide a reason for leave")),
      );
      return;
    }

    FirebaseFirestore.instance
        .collection('clinics')
        .doc(_clinicId)
        .collection('doctors')
        .doc(_doctorId)
        .update({
      'leaveApplications': FieldValue.arrayUnion([{
        'reason': leaveReason,
        'date': DateTime.now(),
      }]),
    });

    _leaveReasonController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Leave application submitted")),
    );
  }

  void _showLateReasonDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Reason for Being Late"),
          content: TextField(
            controller: _reasonController,
            decoration: _inputDecoration("Enter reason here"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = _reasonController.text.trim();
               // _updateStatus("Late");
                FirebaseFirestore.instance
                    .collection('clinics')
                    .doc(_clinicId)
                    .collection('doctors')
                    .doc(_doctorId)
                    .update({'lateReason': reason});
                _reasonController.clear();
                Navigator.pop(context);
              },
              child: Text("Submit"),
            ),
          ],
        );
      },
    );
  }
}
