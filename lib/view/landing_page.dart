import 'package:dashboard_nurse_hospital/view/add_users_page.dart';
import 'package:dashboard_nurse_hospital/view/create_hospital_profile.dart';
import 'package:dashboard_nurse_hospital/view/workAssign_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';

class LandingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hospitals", style: GoogleFonts.poppins()),
      ),
      body: _buildHospitalList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClinicProfileCreation(clinicId: ''),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
  Widget _buildHospitalList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clinics')
          .where('admins', arrayContains: user?.email)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No clinics added yet"));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          padding: EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final clinic = snapshot.data!.docs[index];
            final isPending = clinic['approvalStatus'] == 'pending';
            final cardColor = isPending ? Colors.red[100] : Colors.white;

            return Card(
              elevation: 3,
              margin: EdgeInsets.only(bottom: 12),
              color: cardColor,
              child: InkWell(
                onTap: isPending
                    ? null
                    : () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Options"),
                        content: Text("Choose an action"),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Close the dialog
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StaffCreation(
                                    clinicId: clinic['clinicId'],
                                  ),
                                ),
                              );
                            },
                            child: Text("Add Staffs"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AssignShiftPage(
                                    clinicId: clinic['clinicId'],
                                  ),
                                ),
                              );
                            },
                            child: Text("Assign Shift for Worker"),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: clinic['profilePhoto'] != null
                          ? CircleAvatar(
                        backgroundImage: NetworkImage(clinic['profilePhoto']),
                        radius: 25,
                      )
                          : CircleAvatar(
                        child: Icon(Icons.local_hospital),
                        radius: 25,
                      ),
                      title: Text(
                        clinic['name'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: ${clinic['clinicId']}'),
                          Text('Location: ${clinic['location']}'),
                          Text('Phone: ${clinic['phone']}'),
                        ],
                      ),
                      trailing: Container(
                        padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPending ? Colors.red : Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          clinic['approvalStatus'].toUpperCase(),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCounter(
                              'Doctors', clinic['doctors']?.length ?? 0),
                          _buildCounter('Staff', clinic['staffs']?.length ?? 0),
                          _buildCounter('Patients', clinic['patient_counter']),
                          _buildCounter('Bookings', clinic['booking_counter']),
                        ],
                      ),
                    ),
                    Divider(),
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('clinics')
                          .doc(clinic['clinicId'])
                          .collection('doctors')
                          .get(),
                      builder: (context, doctorSnapshot) {
                        if (!doctorSnapshot.hasData) {
                          return Center(
                              child: CircularProgressIndicator());
                        }

                        final doctors = doctorSnapshot.data!.docs;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "Available Doctors:",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            ...doctors.map((doc) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Text(doc['name']),
                              );
                            }).toList(),
                          ],
                        );
                      },
                    ),
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('clinics')
                          .doc(clinic['clinicId'])
                          .collection('nurses')
                          .get(),
                      builder: (context, nurseSnapshot) {
                        if (!nurseSnapshot.hasData) {
                          return Center(
                              child: CircularProgressIndicator());
                        }

                        final nurses = nurseSnapshot.data!.docs;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "Available Nurses:",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            ...nurses.map((nurse) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Text(nurse['name']),
                              );
                            }).toList(),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }




  Widget _buildCounter(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}