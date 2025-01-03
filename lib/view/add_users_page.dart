
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../main.dart';

class StaffCreation extends ConsumerStatefulWidget {
  final String clinicId;
  final Map<String, dynamic>? doctorData; // Add optional doctor data


  const StaffCreation({required this.clinicId,this.doctorData, super.key});

  @override
  _AccountCreationState createState() => _AccountCreationState();
}

class _AccountCreationState extends ConsumerState<StaffCreation> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchSpecializations();

    print('Doctor Data: ${widget.doctorData}');

    // Pre-fill the form if doctor data is provided
    if (widget.doctorData != null) {
      print('Pre-filling form with doctor data...');

      _nameController.text = widget.doctorData!['name'] ?? '';
      _emailController.text = widget.doctorData!['email'] ?? '';
      _phoneController.text = widget.doctorData!['phone'] ?? '';
      _specializationController.text = widget.doctorData!['specialization'] ?? '';
      _experienceController.text = widget.doctorData!['experience'] ?? '';
      _licenseNumberController.text = widget.doctorData!['licenseNumber'] ?? '';
      _aboutController.text = widget.doctorData!['about'] ?? '';
      _consultationFeesController.text =
          widget.doctorData!['consultationFees']?.toString() ?? '';

      // Print to confirm fields are being set
      print('Name: ${_nameController.text}');
      print('Email: ${_emailController.text}');
      print('Phone: ${_phoneController.text}');

      // Pre-fill consultation times
      if (widget.doctorData!.containsKey('consultationTimes')) {
        final consultationTimes = widget.doctorData!['consultationTimes'] as Map<String, dynamic>;
        consultationTimes.forEach((day, sessions) {
          if (sessions != null) {
            final daySessions = List<Map<String, dynamic>>.from(sessions.values);
            _daySessions[day] = daySessions.map((session) {
              return {
                'from': TimeOfDay(
                    hour: (session['from'] as double).floor(),
                    minute: ((session['from'] as double) * 60 % 60).round()),
                'to': TimeOfDay(
                    hour: (session['to'] as double).floor(),
                    minute: ((session['to'] as double) * 60 % 60).round()),
                'tokenLimit': session['tokenLimit'],
              };
            }).toList();
          }
        });
      }

      // Pre-fill available days
      if (widget.doctorData!.containsKey('availableDays')) {
        // Handle array of days directly without splitting
        _selectedDays = Set<String>.from(widget.doctorData!['availableDays'] as List<dynamic>);
      }
    } else {
      print('No doctor data provided.');
    }

  }

  String _selectedRole = 'doctor';
  List<String> _specializations = [];
  final List<String> _roles = ['doctor', 'nurse', 'admin'];

  final Map<String, String> _roleImages = {
    'doctor': 'assets/lotties/doctor_explaining.json',
    'nurse': 'assets/lotties/assisment.json',
    'admin': 'assets/lotties/doctor_explaining.json',
  };

  Future<void> _fetchSpecializations() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('settings')
          .doc('specializations')
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data.containsKey('specializations')) {
          final specializationsArray = data['specializations'] as List;

          // Extracting 'name' field from each map in the array
          final names = specializationsArray
              .map((item) => item['name'] as String)
              .toList();

          setState(() {
            _specializations = names; // Assigning the names to the state variable
          });
        }
      }
    } catch (e) {
      print('Error fetching specializations: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching specializations from Firestore')),
      );
    }
  }


  Map<String, List<Map<String, dynamic>>> _daySessions = {
    'Monday': [{'from': null, 'to': null, 'tokenLimit': null}],
    'Tuesday': [{'from': null, 'to': null, 'tokenLimit': null}],
    'Wednesday': [{'from': null, 'to': null, 'tokenLimit': null}],
    'Thursday': [{'from': null, 'to': null, 'tokenLimit': null}],
    'Friday': [{'from': null, 'to': null, 'tokenLimit': null}],
    'Saturday': [{'from': null, 'to': null, 'tokenLimit': null}],
    'Sunday': [{'from': null, 'to': null, 'tokenLimit': null}],
  };

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  Set<String> _selectedDays = {};

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(); // New password controller
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _doctorEmailController = TextEditingController();
  final _consultationFeesController = TextEditingController();
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _aboutController = TextEditingController();

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      IconData icon, {
        bool obscureText = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[200],
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
        ),
        obscureText: obscureText,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
  Widget _buildSessionRow(String day, int sessionIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: () => _selectTime(context, day, sessionIndex, 'from'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          child: Text(
            _daySessions[day]![sessionIndex]['from'] == null
                ? 'From'
                : _daySessions[day]![sessionIndex]['from']!.format(context),
          ),
        ),
        ElevatedButton(
          onPressed: () => _selectTime(context, day, sessionIndex, 'to'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          child: Text(
            _daySessions[day]![sessionIndex]['to'] == null
                ? 'To'
                : _daySessions[day]![sessionIndex]['to']!.format(context),
          ),
        ),
        Expanded(
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'Token Limit',
              prefixIcon: Icon(Icons.token, color: Colors.blueAccent),
            ),
            initialValue: _daySessions[day]![sessionIndex]['tokenLimit']?.toString(),
            onChanged: (value) {
              setState(() {
                // Parse the input to an integer, or set to null if it's invalid
                _daySessions[day]![sessionIndex]['tokenLimit'] = int.tryParse(value) ?? 0;
              });
            },
            keyboardType: TextInputType.number,
          ),
        ),
        IconButton(
          icon: Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () {
            setState(() {
              // Remove the session from _daySessions
              _daySessions[day]!.removeAt(sessionIndex);
            });
          },
        ),
      ],
    );
  }

  List<Widget> _buildDaysCheckboxes() {
    return _daysOfWeek.map((day) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            title: Text(day),
            value: _selectedDays.contains(day),
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _selectedDays.add(day);
                } else {
                  _selectedDays.remove(day);
                  _daySessions[day] = []; // Clear sessions for that day if unchecked
                }
              });
            },
          ),
          if (_selectedDays.contains(day)) ...[
            ...List.generate(
              _daySessions[day]!.length,
                  (sessionIndex) => Column(
                children: [
                  _buildSessionRow(day, sessionIndex), // Show from/to picker for each session
                  const SizedBox(height: 10),
                ],
              ),
            ),
            _buildAddSessionButton(day), // Add more sessions
          ],
          const Divider(),
        ],
      );
    }).toList();
  }

  Widget _buildAddSessionButton(String day) {
    return TextButton(
      onPressed: () {
        setState(() {
          _daySessions[day]!.add({'from': null, 'to': null, 'tokenLimit': null});
        });
      },
      child: Text('Add Session'),
    );
  }

  Future<void> _selectTime(
      BuildContext context, String day, int sessionIndex, String timeType) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _daySessions[day]![sessionIndex][timeType] ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _daySessions[day]![sessionIndex][timeType] = picked;
      });
    }
  }

  List<Widget> _getRoleSpecificFields(String role) {
    switch (role) {
      case 'doctor':
        return [
          _buildTextField('Doctor Name', _nameController, Icons.person),
          _buildTextField('Doctor Email', _emailController, Icons.email),
          _buildTextField('Phone Number', _phoneController, Icons.phone_iphone_outlined),
          _buildSpecializationDropdown(),
          _buildTextField('Experience', _experienceController, Icons.timeline),
          _buildTextField('License Number', _licenseNumberController, Icons.card_membership),
          _buildTextField('Consultation Fees', _consultationFeesController, Icons.money),
          _buildTextField('Description', _aboutController, Icons.description),
          const SizedBox(height: 10),
          _buildSectionTitle('Consultation Times'),
          ..._buildDaysCheckboxes(),
        ];
      case 'nurse':
        return [
          _buildTextField('Nurse Name', _nameController, Icons.person),
          _buildTextField('Email', _emailController, Icons.email),
          _buildTextField('Phone', _phoneController, Icons.phone),

        ];
      case 'admin':
        return [
          _buildTextField('Admin Name', _nameController, Icons.person),
          _buildTextField('Email', _emailController, Icons.email),
        ];
      default:
        return [];
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }


  Widget _buildSpecializationDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.local_hospital, color: Colors.blueAccent),
          labelText: 'Specialization',
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[200],
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
        ),
        value: _specializationController.text.isNotEmpty
            ? _specializationController.text
            : null,
        items: _specializations.map((String specialization) {
          return DropdownMenuItem<String>(
            value: specialization,
            child: Text(specialization),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _specializationController.text = value!;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a specialization';
          }
          return null;
        },
      ),
    );
  }

  void _clearFormFields() {
    _emailController.clear();
    _passwordController.clear(); // Clear password field
    _phoneController.clear();
    _nameController.clear();
    _doctorEmailController.clear();
    _consultationFeesController.clear();
    _specializationController.clear();
    _experienceController.clear();
    _licenseNumberController.clear();
    _aboutController.clear();
    _daySessions.forEach((key, value) {
      value.clear();
    });
    _selectedDays.clear();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user is currently signed in.')),
      );
      return;
    }

    try {
      final clinicDocRef =
      FirebaseFirestore.instance.collection('clinics').doc(widget.clinicId);
      final clinicSnapshot = await clinicDocRef.get();

      if (!clinicSnapshot.exists) {
        throw Exception('Clinic not found');
      }

      final clinicData = clinicSnapshot.data() as Map<String, dynamic>;

      QuerySnapshot existingStaffSnapshot = await clinicDocRef
          .collection(_selectedRole + "s")
          .where('email', isEqualTo: _emailController.text.trim())
          .get();

      String staffId;

      if (existingStaffSnapshot.docs.isNotEmpty) {
        staffId = existingStaffSnapshot.docs.first.id;
        print('Updating existing staff with ID: $staffId');
      } else {
        staffId = clinicDocRef.collection('staff').doc().id;
        print('Creating new staff with ID: $staffId');
      }

      Map<String, Map<String, dynamic>?> consultationTimes =
      _prepareConsultationTimes();

      final Map<String, dynamic> staffDetails = {
        'staffId': staffId,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'name': _nameController.text.trim(),
        'clinicName': clinicData['name'],
        'clinicId': widget.clinicId,
        'role': _selectedRole,
      };

      if (_selectedRole == 'doctor') {
        staffDetails.addAll({
          'specialization': _specializationController.text.trim(),
          'experience': _experienceController.text.trim(),
          'phone': _phoneController.text.trim(),
          'licenseNumber': _licenseNumberController.text.trim(),
          'availableDays':_convertAvailableDaysToArray(),
          'about': _aboutController.text.trim(),
          'consultationFees': _consultationFeesController.text.trim(),
          'consultations': 0,
          'consultationTimes': consultationTimes,
          'profilePhoto': "",
        });
      }

      if (_selectedRole == 'nurse') {
        staffDetails.addAll({
          'availableDays':_convertAvailableDaysToArray(),
          
        });
      }

      if (_selectedRole == 'admin') {
        staffDetails.addAll({
        });
      }

      // Update or create a new document based on whether staff exists
      await clinicDocRef.collection(_selectedRole + "s").doc(staffId).set(staffDetails);

      // Update the staff reference in the clinic document
      await clinicDocRef.update({
        _selectedRole == 'admin'
            ? 'admins'
            : _selectedRole == 'doctor'
            ? "doctors"
            : "staffs": FieldValue.arrayUnion([_emailController.text.trim()])
      });

      _showSuccessDialog();
      _clearFormFields();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }


  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(
              'The ${_selectedRole[0].toUpperCase() + _selectedRole.substring(1)} was created successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  double _timeOfDayToDouble(TimeOfDay time) {
    int hours = time.hour;
    int minutes = time.minute;

    // Convert minutes to a 2-digit format representing a percentage of an hour
    String minuteString = ((minutes * 100) / 60).round().toString().padLeft(2, '0');

    // Combine hours and formatted minutes as a string, then parse it back to double
    return double.parse('$hours.$minuteString');
  }



  Map<String, Map<String, dynamic>?> _prepareConsultationTimes() {
    Map<String, Map<String, dynamic>?> consultationTimes = {};
    _daySessions.forEach((day, sessions) {
      bool hasValidSessions = false;
      Map<String, dynamic> dayData = {};

      for (int i = 0; i < sessions.length; i++) {
        if (sessions[i]['from'] != null && sessions[i]['to'] != null) {
          hasValidSessions = true;
          dayData['session_$i'] = {
            'from': _timeOfDayToDouble(sessions[i]['from']),
            'to': _timeOfDayToDouble(sessions[i]['to']),
            'tokenLimit': sessions[i]['tokenLimit'],
          };
        }
      }

      // Only include the day if there are valid sessions, otherwise set it to null
      consultationTimes[day] = hasValidSessions ? dayData : null;
    });

    return consultationTimes;
  }

  List<String> _convertAvailableDaysToArray() {
    // Convert the Set to a sorted List based on the _daysOfWeek order
    return _daysOfWeek
        .where((day) => _selectedDays.contains(day))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Role',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey, width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                    items: _roles.map((role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(
                          role[0].toUpperCase() + role.substring(1),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _getRoleSpecificFields(_selectedRole),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Lottie.asset(
                            _roleImages[_selectedRole]!,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}