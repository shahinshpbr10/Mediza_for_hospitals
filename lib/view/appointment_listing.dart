import 'package:dashboard_nurse_hospital/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentList extends StatefulWidget {
  final String email;

  const AppointmentList({Key? key, required this.email}) : super(key: key);

  @override
  State<AppointmentList> createState() => _AppointmentListState();
}

class _AppointmentListState extends State<AppointmentList> {
  String selectedCategory = 'All';
  String searchQuery = '';
  final TextEditingController tokenController = TextEditingController();

  Future<String?> _getClinicId() async {
    try {
      final clinicQuerySnapshot =
      await FirebaseFirestore.instance.collection('clinics').get();

      for (var clinicDoc in clinicQuerySnapshot.docs) {
        final receptionistSnapshot = await clinicDoc.reference
            .collection('receptionists')
            .where('email', isEqualTo: widget.email)
            .get();

        if (receptionistSnapshot.docs.isNotEmpty) {
          return clinicDoc.id;
        }
      }
    } catch (e) {
      debugPrint('Error fetching clinic ID: $e');
    }
    return null;
  }

  Stream<QuerySnapshot> _appointmentStream(String clinicId) {
    return FirebaseFirestore.instance
        .collection('clinics')
        .doc(clinicId)
        .collection('bookings')
        .snapshots();
  }

  Future<void> _updateToken(
      String clinicId, String bookingId, int token) async {
    try {
      await FirebaseFirestore.instance
          .collection('clinics')
          .doc(clinicId)
          .collection('bookings')
          .doc(bookingId)
          .update({'token': token});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token $token assigned successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign token: $e')),
      );
    }
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: const Color(0xFF2C3E50),
        actions: [IconButton(
          icon: Icon(Icons.logout),
          onPressed: _logout, // Call the logout function
        )],
      ),
      body: FutureBuilder<String?>(
        future: _getClinicId(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Error loading clinic data.'));
          }

          final clinicId = snapshot.data!;
          return StreamBuilder<QuerySnapshot>(
            stream: _appointmentStream(clinicId),
            builder: (context, streamSnapshot) {
              if (streamSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (streamSnapshot.hasError ||
                  streamSnapshot.data == null) {
                return const Center(child: Text('Error loading appointments.'));
              }

              final appointments = streamSnapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {
                  'bookingId': doc.id,
                  'clinicId': clinicId,
                  'patientName': data['patientName'] ?? 'Unknown Patient',
                  'doctorName': data['doctorName'] ?? 'Unknown Doctor',
                  'specialization': data['specialization'] ?? 'General',
                  'token': data['token'] ?? 0,
                };
              }).toList();

              final filteredAppointments = appointments.where((appointment) {
                final matchesCategory = selectedCategory == 'All' ||
                    appointment['specialization'] == selectedCategory;
                final matchesSearch = appointment['patientName']
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase());
                return matchesCategory && matchesSearch;
              }).toList();

              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
                  ),
                ),
                child: Column(
                  children: [
                    _buildSearchAndFilterBar(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredAppointments.length,
                        itemBuilder: (context, index) {
                          final appointment = filteredAppointments[index];
                          return _buildAppointmentCard(appointment);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Row(
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCategory,
              style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 16),
              items: ['All', 'Cardiology', 'Dermatology', 'Neurology']
                  .map((category) => DropdownMenuItem(
                value: category,
                child: Text(category),
              ))
                  .toList(),
              onChanged: (value) => setState(() => selectedCategory = value!),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search patient...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final hasToken = appointment['token'] > 0;
    final cardColor = hasToken ? Colors.green[50] : Colors.white;
    final buttonColor = hasToken ? Colors.orange : Colors.blue;
    final buttonText = hasToken ? 'Reassign' : 'Assign';

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient: ${appointment['patientName']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Doctor: ${appointment['doctorName']}'),
            Text('Specialization: ${appointment['specialization']}'),
            const SizedBox(height: 8),
            Row(
              children: [
                if (hasToken)
                  Text('Token: ${appointment['token']}'),
                if (!hasToken || hasToken)
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: tokenController,
                      decoration: const InputDecoration(
                        hintText: 'Token',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                  ),
                  onPressed: () {
                    final token = int.tryParse(tokenController.text);
                    if (token != null) {
                      _updateToken(
                        appointment['clinicId'],
                        appointment['bookingId'],
                        token,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a valid token.')),
                      );
                    }
                  },
                  child: Text(buttonText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
