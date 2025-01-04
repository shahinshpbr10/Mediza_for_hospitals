import 'package:dashboard_nurse_hospital/view/get_started.dart';
import 'package:dashboard_nurse_hospital/view/workAssign_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import 'add_users_page.dart';
import 'create_hospital_profile.dart';

class LandingPage extends StatefulWidget {
  final String email;
  const LandingPage({Key? key,   required this.email}) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(toolbarHeight: 90,
        elevation: 0,

        flexibleSpace: Padding(

          padding: const EdgeInsets.all(8.0),
          child: Container(padding:  EdgeInsets.all(8.0),
            height: 90,
            decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade300, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Hospitals",
                style: GoogleFonts.lobster(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
        children: [ ElevatedButton.icon(
          onPressed: () => _logout(context),
          icon: Icon(Iconsax.logout,color: Colors.white,),
          label: Text("Logout"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
        ),
          Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Icon(Icons.person, color: Colors.blue),
                    ),
                  ),
        ],
      ),
            ],
          ),),

        ),


      ),
      body: _buildHospitalList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClinicProfileCreation(clinicId: ''),
            ),
          );
        },
        icon: Icon(Icons.add),
        label: Text('Add Hospital'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }
  Future<void> _logout(BuildContext context) async {
    try {
      // Sign out the user
      await FirebaseAuth.instance.signOut();

      // Navigate to the login screen or a specified route
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => GetStartedPage()), // Replace LoginPage with your destination widget
            (Route<dynamic> route) => false, // Removes all previous routes
      );

    } catch (e) {
      // Handle error, if any
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  Widget _buildHospitalList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clinics')
          .where('admins', arrayContains: widget.email)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_hospital_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "No hospitals added yet",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          padding: EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final clinic = snapshot.data!.docs[index];
            return HospitalCard(clinic: clinic);
          },
        );
      },
    );
  }
}

class HospitalCard extends StatelessWidget {
  final DocumentSnapshot clinic;

  const HospitalCard({Key? key, required this.clinic}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPending = clinic['approvalStatus'] == 'pending';

    return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade300, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
      child: Column(
        children: [
          _buildHeader(context, isPending),
          _buildStatistics(),
          DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.black,
                  indicatorColor: Colors.white,
                  tabs: [
                    Tab(
                      icon: Icon(Icons.medical_services),
                      text: 'Doctors',
                    ),
                    Tab(
                      icon: Icon(Icons.health_and_safety),
                      text: 'Nurses',
                    ),
                  ],
                ),
                SizedBox(
                  height: 300, // Fixed height for the tab content
                  child: TabBarView(
                    children: [
                      _buildDoctorsList(),
                      _buildNursesList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isPending) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPending ? Colors.red[50] : Colors.white24,
          borderRadius:BorderRadius.circular(20)),

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHospitalAvatar(),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clinic['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      _buildInfoRow(Icons.location_on_outlined, clinic['location']),
                      _buildInfoRow(Icons.phone_outlined, clinic['phone']),
                    ],
                  ),
                ),
                _buildStatusBadge(clinic['approvalStatus']),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(

                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StaffCreation(
                          clinicId: clinic['clinicId'],
                        ),
                      ),
                    );
                  },
                  icon: Icon(Iconsax.personalcard,color: Colors.black,),
                  label: Text('Add Staff'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black
                  ),
                ),
                ElevatedButton.icon(
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
                  icon: Icon(Iconsax.timer,color: Colors.black,),
                  label: Text('Assign Shifts'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalAvatar() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue[100],
      ),
      child: clinic['profilePhoto'] != null
          ? ClipOval(
        child: Image.network(
          clinic['profilePhoto'],
          fit: BoxFit.cover,
        ),
      )
          : Icon(
        Icons.local_hospital,
        size: 32,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isApproved = status != 'pending';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: isApproved ? Colors.green[700] : Colors.red[700],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container( decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius:BorderRadius.circular(20)),
        padding: EdgeInsets.all(16),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(Icons.medical_services, 'Doctors',
                clinic['doctors']?.length ?? 0),
            _buildStatItem(Icons.people, 'Staff',
                clinic['staffs']?.length ?? 0),
            _buildStatItem(Icons.person, 'Patients',
                clinic['patient_counter']),
            _buildStatItem(Icons.calendar_today, 'Bookings',
                clinic['booking_counter']),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, int count) {
    return Column(
      children: [
        Icon(icon, color: Colors.black, size: 24),
        SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
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

  Widget _buildDoctorsList() {
    return _buildStaffList('doctors');
  }

  Widget _buildNursesList() {
    return _buildStaffList('nurses');
  }

  Widget _buildStaffList(String collection) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('clinics')
          .doc(clinic['clinicId'])
          .collection(collection)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final staff = snapshot.data!.docs;
        if (staff.isEmpty) {
          return Center(
            child: Text(
              'No ${collection} available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return ListView.builder(
          itemCount: staff.length,
          padding: EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final person = staff[index];
            return Container(
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius:BorderRadius.circular(20)),
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(
                    collection == 'doctors'
                        ? Icons.medical_services
                        : Icons.health_and_safety,
                    color: Colors.blue,
                  ),
                ),
                title: Text(
                  person['name'],
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle:
                collection == 'doctors'?Text(person['specialization'] ?? 'General'):null,
                trailing: IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () {
                    // Add staff member options here
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}