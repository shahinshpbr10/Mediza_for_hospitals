import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AssignShiftPage extends StatefulWidget {
  final String clinicId;

  const AssignShiftPage({Key? key, required this.clinicId}) : super(key: key);

  @override
  _AssignShiftPageState createState() => _AssignShiftPageState();
}

class _AssignShiftPageState extends State<AssignShiftPage> {
  String? selectedNurseId;
  String? selectedDoctorId;
  String selectedShift = "Morning";
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  Future<void> _pickTime(BuildContext context, bool isStartTime) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        if (isStartTime) {
          startTime = time;
        } else {
          endTime = time;
        }
      });
    }
  }

  void _saveAssignment() async {
    if (selectedNurseId == null ||
        selectedDoctorId == null ||
        startTime == null ||
        endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('clinics')
          .doc(widget.clinicId)
          .collection('assignments')
          .add({
        'nurseId': selectedNurseId,
        'doctorId': selectedDoctorId,
        'shift': selectedShift,
        'startTime': '${startTime!.hour}:${startTime!.minute}',
        'endTime': '${endTime!.hour}:${endTime!.minute}',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Shift assigned successfully'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        selectedNurseId = null;
        selectedDoctorId = null;
        selectedShift = "Morning";
        startTime = null;
        endTime = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Assign Shifts", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Assign Shift",
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Allocate shifts for nurses and doctors in the clinic.",
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 24),
            _buildCard(
              title: "Select Nurse",
              child: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('clinics')
                    .doc(widget.clinicId)
                    .collection('nurses')
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                  final nurses = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    decoration: _inputDecoration("Choose a Nurse"),
                    value: selectedNurseId,
                    items: nurses
                        .map((nurse) => DropdownMenuItem<String>(
                      value: nurse['staffId'] as String,
                      child: Text(nurse['name'] as String),
                    ))
                        .toList(),
                    onChanged: (value) => setState(() {
                      selectedNurseId = value;
                    }),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            _buildCard(
              title: "Select Doctor",
              child: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('clinics')
                    .doc(widget.clinicId)
                    .collection('doctors')
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                  final doctors = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    decoration: _inputDecoration("Choose a Doctor"),
                    value: selectedDoctorId,
                    items: doctors
                        .map((doctor) => DropdownMenuItem<String>(
                      value: doctor['staffId'] as String,
                      child: Text(doctor['name'] as String),
                    ))
                        .toList(),
                    onChanged: (value) => setState(() {
                      selectedDoctorId = value;
                    }),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            _buildCard(
              title: "Select Shift",
              child: DropdownButtonFormField<String>(
                decoration: _inputDecoration("Shift Timing"),
                value: selectedShift,
                items: ["Morning", "Afternoon", "Night"]
                    .map((shift) => DropdownMenuItem(
                  value: shift,
                  child: Text(shift),
                ))
                    .toList(),
                onChanged: (value) => setState(() {
                  selectedShift = value!;
                }),
              ),
            ),
            SizedBox(height: 16),
            _buildCard(
              title: "Select Time",
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _timePickerButton(context, isStartTime: true, label: "Start Time"),
                  _timePickerButton(context, isStartTime: false, label: "End Time"),
                ],
              ),
            ),
            SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAssignment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text("Save", style: GoogleFonts.poppins(fontSize: 16)),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        selectedNurseId = null;
                        selectedDoctorId = null;
                        selectedShift = "Morning";
                        startTime = null;
                        endTime = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text("Cancel", style: GoogleFonts.poppins(fontSize: 16, color: Colors.blue)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
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
      fillColor: Colors.grey[200],
    );
  }

  Widget _timePickerButton(BuildContext context, {required bool isStartTime, required String label}) {
    return TextButton.icon(
      onPressed: () => _pickTime(context, isStartTime),
      icon: Icon(Icons.access_time_rounded, color: Colors.blue),
      label: Text(
        isStartTime
            ? (startTime != null ? startTime!.format(context) : label)
            : (endTime != null ? endTime!.format(context) : label),
        style: GoogleFonts.poppins(color: Colors.blue, fontSize: 14),
      ),
    );
  }
}
