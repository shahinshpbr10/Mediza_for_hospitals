import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_nurse_hospital/view/account_creation_admin.dart';
import 'package:dashboard_nurse_hospital/view/account_creation_page.dart';
import 'package:dashboard_nurse_hospital/view/dashboard_page.dart';
import 'package:dashboard_nurse_hospital/view/get_started.dart';
import 'package:dashboard_nurse_hospital/view/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod

import 'firebase_options.dart';

User? user;
String role = "staff";
DocumentSnapshot? userDoc;
DocumentSnapshot? clinicSnapshot;
DocumentReference? clinicDocRef;
DocumentSnapshot? doctorSnapshot;
String doctorId="";

void main() async {
  // Ensure the Flutter engine is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: MedizaDashboard())); // Wrap with ProviderScope
}

class MedizaDashboard extends StatelessWidget {
  const MedizaDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mediza Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GetStartedPage(), // Replace with your main page
    );
  }
}
