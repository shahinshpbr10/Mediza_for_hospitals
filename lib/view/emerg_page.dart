import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EmergencyPage extends StatefulWidget {
  @override
  _EmergencyPageState createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  String? selectedReason; // Only one toggle at a time
  bool doctorArrived = false; // Doctor arrived is separate
  final String doctorName = "Dr. Shanu"; // Customize doctor name

  final Map<String, String> notificationMessages = {
    'Doctor Late': 'is currently late.',
    'Doctor Emergency': 'is in an emergency visit.',
    'Operation': 'is currently in an operation.',
    'VIP Patient': 'is attending a VIP patient.',
    'Lab Test': 'is waiting for lab test results.',
  };

  final Map<String, IconData> reasonIcons = {
    'Doctor Late': Icons.access_time,
    'Doctor Emergency': Icons.local_hospital,
    'Operation': Icons.health_and_safety,
    'VIP Patient': Icons.star,
    'Lab Test': Icons.biotech,
  };

  final Map<String, TextEditingController> lateTimeControllers = {
    'Doctor Late': TextEditingController(),
    'Doctor Emergency': TextEditingController(),
    'Operation': TextEditingController(),
    'VIP Patient': TextEditingController(),
    'Lab Test': TextEditingController(),
  };


  Future<void> addNotificationToFirestore(String message) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'content': message,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("Notification added successfully!");
    } catch (e) {
      print("Error adding notification: $e");
    }
  }

  void sendNotification() async {
    String message = "";

    if (selectedReason != null) {
      message = "$doctorName ${notificationMessages[selectedReason]!}";
      String lateTime = lateTimeControllers[selectedReason!]!.text;
      if (lateTime.isNotEmpty) {
        message += " Approx. delay: $lateTime minutes.";
      }
    }

    if (doctorArrived) {
      message = "$doctorName has arrived and is available.";
    }

    if (message.isEmpty) {
      _showDialog("No reason selected.");
      return;
    }

    await addNotificationToFirestore(message); //
    _showDialog("Notification sent successfully!");
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notification'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Status'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ...lateTimeControllers.keys.map((reason) {
              bool isSelected = selectedReason == reason;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(reasonIcons[reason], color: Colors.blue.shade800),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(reason, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                    Switch(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          selectedReason = value ? reason : null;
                        });
                      },
                      activeColor: Colors.redAccent,
                    ),
                    if (isSelected)
                      SizedBox(
                        width: 70,
                        child: TextField(
                          controller: lateTimeControllers[reason],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Mins',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),

            Divider(),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade800),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Doctor Arrived', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                  Switch(
                    value: doctorArrived,
                    onChanged: (value) {
                      setState(() {
                        doctorArrived = value;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),

            Spacer(),

            ElevatedButton.icon(
              onPressed: sendNotification,
              icon: Icon(Icons.notifications_active, color: Colors.white),
              label: Text('Send Notification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
