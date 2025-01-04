import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TokenManagement extends StatefulWidget {
  final String email;

  const TokenManagement({required this.email, super.key});

  @override
  _TokenManagementState createState() => _TokenManagementState();
}

class _TokenManagementState extends State<TokenManagement> {
  List<Map<String, dynamic>> doctors = [];
  String? selectedDoctor;
  List<Map<String, dynamic>> tokens = [];
  String? clinicId;

  @override
  void initState() {
    super.initState();
    findClinicByEmail(); // First find clinic by email
  }

  // Find clinic by checking staff email
  Future<void> findClinicByEmail() async {
    try {
      final clinicsSnapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .where('staffs', arrayContains: widget.email)
          .get();

      if (clinicsSnapshot.docs.isNotEmpty) {
        // Get the first clinic where this staff works
        clinicId = clinicsSnapshot.docs.first.id;
        await fetchDoctors(); // Then fetch doctors for this clinic
      } else {
        debugPrint('No clinic found for this email');
      }
    } catch (e) {
      debugPrint('Error finding clinic: $e');
    }
  }

  // Fetch doctors from Firestore
  Future<void> fetchDoctors() async {
    if (clinicId == null) return;

    try {
      final doctorSnapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(clinicId)
          .collection('doctors')
          .get();

      final fetchedDoctors = doctorSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'doctor': data['name'] ?? 'Unknown Doctor',
          'category': data['category'] ?? 'General',
        };
      }).toList();

      setState(() {
        doctors = fetchedDoctors;
        if (doctors.isNotEmpty) selectedDoctor = doctors[0]['id'] as String;
      });

      if (selectedDoctor != null) fetchTokens(selectedDoctor!);
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
    }
  }

  // Fetch tokens from Firestore for the selected doctor
  Future<void> fetchTokens(String doctorId) async {
    if (clinicId == null) return;

    try {
      final tokenSnapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(clinicId)
          .collection('bookings')
          .where('doctorId', isEqualTo: doctorId)
          .get();

      final fetchedTokens = tokenSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'token': data['token'].toString() ?? 'Unknown',
          'status': data['status'] ?? 'available',
        };
      }).toList();

      setState(() {
        tokens = fetchedTokens;
      });
    } catch (e) {
      debugPrint('Error fetching tokens: $e');
    }
  }

  void assignToken(int index) {
    setState(() => tokens[index]['status'] = 'assigned');
    // Update Firestore if needed
  }

  void unassignToken(int index) {
    setState(() => tokens[index]['status'] = 'available');
    // Update Firestore if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Doctor',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (doctors.isNotEmpty)
                      DropdownButton<String>(
                        value: selectedDoctor,
                        isExpanded: true,
                        items: doctors.map((doc) {
                          return DropdownMenuItem<String>(
                            value: doc['id'] as String,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: _getCategoryColor(doc['category'] as String),
                                  radius: 16,
                                  child: Text(
                                    (doc['doctor'] as String)[0],
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('${doc['doctor']} (${doc['category']})'),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedDoctor = value);
                          if (value != null) fetchTokens(value);
                        },
                      )
                    else
                      const Text('No doctors available.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Available Tokens',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: tokens.isNotEmpty
                    ? GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: tokens.length,
                  itemBuilder: (context, index) {
                    final isAssigned = tokens[index]['status'] == 'assigned';
                    return InkWell(
                      onTap: () => isAssigned
                          ? unassignToken(index)
                          : assignToken(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isAssigned
                              ? const Color(0xFFE74C3C)
                              : const Color(0xFF2ECC71),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (isAssigned ? Colors.red : Colors.green)
                                  .withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                tokens[index]['token'] as String,
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAssigned ? 'Assigned' : 'Available',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
                    : const Center(child: Text('No tokens available.')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Cardiologist':
        return const Color(0xFF3498DB);
      case 'Neurologist':
        return const Color(0xFF9B59B6);
      case 'Dentist':
        return const Color(0xFFE67E22);
      case 'Orthopedic':
        return const Color(0xFF1ABC9C);
      default:
        return const Color(0xFF34495E);
    }
  }
}