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
    if (selectedNurseId == null || selectedDoctorId == null || startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
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
        SnackBar(content: Text('Shift assigned successfully')),
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
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Assign Shifts", style: GoogleFonts.poppins()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Assign Shift to Nurse",
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('clinics')
                  .doc(widget.clinicId)
                  .collection('nurses')
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                final nurses = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Select Nurse",
                    border: OutlineInputBorder(),
                  ),
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

            SizedBox(height: 16),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('clinics')
                  .doc(widget.clinicId)
                  .collection('doctors')
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                final doctors = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Select Doctor",
                    border: OutlineInputBorder(),
                  ),
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

            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Select Shift",
                border: OutlineInputBorder(),
              ),
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
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _pickTime(context, true),
                    child: Text(
                      startTime != null
                          ? "Start Time: ${startTime!.format(context)}"
                          : "Pick Start Time",
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => _pickTime(context, false),
                    child: Text(
                      endTime != null
                          ? "End Time: ${endTime!.format(context)}"
                          : "Pick End Time",
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAssignment,
                    child: Text("Save"),
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
                    child: Text("Cancel"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
