import 'package:flutter/material.dart';

class AppointmentList extends StatefulWidget {
  const AppointmentList({super.key});

  @override
  State<AppointmentList> createState() => _AppointmentListState();
}

class _AppointmentListState extends State<AppointmentList> {
  final List<Map<String, dynamic>> appointments = [
    {
      'doctor': 'Dr. Smith',
      'category': 'Cardiology',
      'patient': 'John Doe',
      'token': null,
      'times': ['10:00 AM', '2:00 PM', '5:00 PM']
    },
    // ... other appointments
  ];

  final Set<int> assignedTokens = {};
  String selectedCategory = 'All';
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredAppointments = appointments.where((appointment) {
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
          Container(
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
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredAppointments.length,
              itemBuilder: (context, index) {
                final appointment = filteredAppointments[index];
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
                        appointment['doctor'][3],
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
              },
            ),
          ),
        ],
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Assign Token',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select a token number:',
                style: TextStyle(fontSize: 16, color: Color(0xFF34495E)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    50,
                        (index) {
                      final token = index + 1;
                      final isAssigned = assignedTokens.contains(token);
                      return ChoiceChip(
                        label: Text(
                          '$token',
                          style: TextStyle(
                            color: isAssigned ? Colors.white : const Color(0xFF2C3E50),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: appointment['token'] == token,
                        selectedColor: const Color(0xFF2ECC71),
                        backgroundColor: isAssigned ? Colors.red.shade400 : Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        onSelected: !isAssigned
                            ? (_) {
                          setState(() {
                            if (appointment['token'] != null) {
                              assignedTokens.remove(appointment['token']);
                            }
                            appointment['token'] = token;
                            assignedTokens.add(token);
                          });
                          Navigator.pop(context);
                        }
                            : null,
                      );
                    },
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