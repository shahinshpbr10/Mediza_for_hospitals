import 'package:flutter/material.dart';

class TokenManagement extends StatefulWidget {
  const TokenManagement({super.key});

  @override
  _TokenManagementState createState() => _TokenManagementState();
}

class _TokenManagementState extends State<TokenManagement> {
  final List<Map<String, String>> doctors = [
    {'id': '1', 'doctor': 'Dr. Smith', 'category': 'Cardiologist'},
    {'id': '2', 'doctor': 'Dr. Smith', 'category': 'Neurologist'},
    {'id': '3', 'doctor': 'Dr. Lee', 'category': 'Dentist'},
    {'id': '4', 'doctor': 'Dr. Johnson', 'category': 'Orthopedic'},
  ];

  String? selectedDoctor;
  final List<Map<String, String>> tokens = List.generate(50, (index) =>
  {'token': '${index + 1}', 'status': 'available'}
  );

  @override
  void initState() {
    super.initState();
    selectedDoctor = doctors[0]['id'];
  }

  void assignToken(int index) => setState(() => tokens[index]['status'] = 'assigned');
  void unassignToken(int index) => setState(() => tokens[index]['status'] = 'available');

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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedDoctor,
                          isExpanded: true,
                          hint: const Text('Select a doctor'),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF2C3E50),
                          ),
                          items: doctors.map((doc) {
                            return DropdownMenuItem<String>(
                              value: doc['id'],
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: _getCategoryColor(doc['category']!),
                                    radius: 16,
                                    child: Text(
                                      doc['doctor']![3],
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text('${doc['doctor']} (${doc['category']})'),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => selectedDoctor = value),
                        ),
                      ),
                    ),
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
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: tokens.length,
                  itemBuilder: (context, index) {
                    final isAssigned = tokens[index]['status'] == 'assigned';
                    return InkWell(
                      onTap: () => isAssigned ? unassignToken(index) : assignToken(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isAssigned ? const Color(0xFFE74C3C) : const Color(0xFF2ECC71),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (isAssigned ? Colors.red : Colors.green).withOpacity(0.2),
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
                                tokens[index]['token']!,
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
                ),
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