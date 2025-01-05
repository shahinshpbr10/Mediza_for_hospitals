import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';

import '../main.dart';
import 'emerg_page.dart';

class TokenManagement extends StatefulWidget {
  final String email;

  const TokenManagement({required this.email, super.key});

  @override
  _TokenManagementState createState() => _TokenManagementState();
}

class _TokenManagementState extends State<TokenManagement>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> doctors = [];
  String? selectedDoctor;
  String? clinicId;
  int selectedTokenCount = 10;
  List<Map<String, dynamic>> tokens = [];
  late TabController _tabController;
  String? selectedToken;
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
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    findClinicByEmail();
    _generateTokens(selectedTokenCount);
  }

  Future<void> findClinicByEmail() async {
    try {
      final clinicsSnapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .where('staffs', arrayContains: widget.email)
          .get();

      if (clinicsSnapshot.docs.isNotEmpty) {
        clinicId = clinicsSnapshot.docs.first.id;
        await fetchDoctors();
      }
    } catch (e) {
      debugPrint('Error finding clinic: $e');
    }
  }

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
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
    }
  }

  void _generateTokens(int count) {
    setState(() {
      tokens = List.generate(count, (index) {
        return {'token': (index + 1).toString(), 'status': 'available'};
      });
    });
  }

  Future<void> updateLiveToken(String tokenNumber) async {
    if (selectedDoctor == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('liveToken')
          .doc(selectedDoctor)
          .set({
        'token': tokenNumber,
        'doctorId': selectedDoctor,
        'doctorName': doctors.firstWhere((doctor) => doctor['id'] == selectedDoctor)['doctor'],
        'clinicName': clinicId,
      }, SetOptions(merge: true));
      debugPrint('Live token updated: $tokenNumber');
    } catch (e) {
      debugPrint('Error updating live token: $e');
    }
  }

  Widget _buildTokenCountInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Number of Tokens',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  selectedTokenCount = int.tryParse(value) ?? 10;
                  _generateTokens(selectedTokenCount);
                });
              },
              controller: TextEditingController(text: selectedTokenCount.toString()),
            ),
          ),
          const SizedBox(width: 16),
          if (selectedToken != null)
            Text(
              'Selected: $selectedToken',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Widget _buildDoctorDropdown() {
    return DropdownButton<String>(
      value: selectedDoctor,
      isExpanded: true,
      items: doctors.map((doc) {
        return DropdownMenuItem<String>(
          value: doc['id'] as String,
          child: Text('${doc['doctor']} (${doc['category']})'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => selectedDoctor = value);
      },
    );
  }

  Widget _buildTokenGrid() {
    return Expanded(
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: tokens.length,
        itemBuilder: (context, index) {
          final isAssigned = tokens[index]['status'] == 'assigned';

          Color backgroundColor = isAssigned
              ? Colors.green
              : (index % 2 == 0
              ? Colors.red.withOpacity(0.7)
              : Colors.red.withOpacity(0.5));

          return InkWell(
            onTap: () {
              setState(() {
                tokens[index]['status'] = isAssigned ? 'available' : 'assigned';
                selectedToken = tokens[index]['token'] as String;
              });
              updateLiveToken(tokens[index]['token'] as String);
            },
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  tokens[index]['token'] as String,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        title: const Text('Token Management'),
        actions: [ElevatedButton(onPressed: _logout, child: Icon(Iconsax.logout))],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tokens'),
            Tab(text: 'Emergency'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDoctorDropdown(),
                _buildTokenCountInput(),
                _buildTokenGrid(),
              ],
            ),
          ),
          EmergencyPage(doctorName: doctors.firstWhere((doctor) => doctor['id'] == selectedDoctor)['doctor'],),
        ],
      ),
    );
  }
}
