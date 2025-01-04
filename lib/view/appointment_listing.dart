import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentList extends StatefulWidget {
  final String email;

  const AppointmentList({Key? key, required this.email}) : super(key: key);


  @override
  State<AppointmentList> createState() => _AppointmentListState();
}

class _AppointmentListState extends State<AppointmentList> {
  final Set<int> assignedTokens = {};
  String selectedCategory = 'All';
  String searchQuery = '';

  Future<List<Map<String, dynamic>>> fetchAppointments() async {
    final List<Map<String, dynamic>> fetchedAppointments = [];
    try {
      // Query to find the clinic containing the receptionist with the specified email
      final clinicQuerySnapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .get();

      String? clinicId;

      // Search for the receptionist email within each clinic's `receptionists` subcollection
      for (var clinicDoc in clinicQuerySnapshot.docs) {
        final receptionistSnapshot = await clinicDoc.reference
            .collection('receptionists')
            .where('email', isEqualTo: widget.email)
            .get();

        if (receptionistSnapshot.docs.isNotEmpty) {
          clinicId = clinicDoc.id; // Get the clinicId
          break;
        }
      }

      if (clinicId == null) {
        throw 'Receptionist with the provided email not found.';
      }

      // Fetch bookings for the determined clinicId
      final bookingSnapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(clinicId)
          .collection('bookings')
          .get();

      for (var bookingDoc in bookingSnapshot.docs) {
        final data = bookingDoc.data();
        fetchedAppointments.add({
          'doctor': data['doctorName'] ?? 'Unknown Doctor',
          'category': data['specialization'] ?? 'Unknown Category',
          'patient': data['patientName'] ?? 'Unknown Patient',
          'token': data['token'],
          'times': [data['appointmentTime'] ?? 'N/A'], // Single time in list format
        });
      }
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
    }
    return fetchedAppointments;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No Appointments Found'));
          }

          final appointments = snapshot.data!;
          final filteredAppointments = appointments.where((appointment) {
            final matchesCategory = selectedCategory == 'All' || appointment['category'] == selectedCategory;
            final matchesSearch = appointment['patient'].toLowerCase().contains(searchQuery.toLowerCase());
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
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
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
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search patient...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(appointment['category']),
          radius: 25,
          child: Text(
            appointment['doctor'][0],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          appointment['patient'],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              appointment['doctor'],
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF34495E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              appointment['category'],
              style: TextStyle(
                fontSize: 14,
                color: _getCategoryColor(appointment['category']),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: appointment['token'] != null
                ? Colors.red.shade400
                : const Color(0xFF2ECC71),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            if (appointment['token'] == null) {
              _showTokenDialog(appointment);
            }
          },
          child: Text(
            appointment['token'] == null
                ? 'Assign Token'
                : 'Token ${appointment['token']}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Cardiology':
        return const Color(0xFF3498DB);
      case 'Dermatology':
        return const Color(0xFF9B59B6);
      case 'Neurology':
        return const Color(0xFFE67E22);
      default:
        return const Color(0xFF2ECC71);
    }
  }

  void _showTokenDialog(Map<String, dynamic> appointment) {
    // Same implementation as in your original code
  }
}
