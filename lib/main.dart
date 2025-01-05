import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_nurse_hospital/view/account_creation_admin.dart';
import 'package:dashboard_nurse_hospital/view/account_creation_page.dart';
import 'package:dashboard_nurse_hospital/view/appointment_listing.dart';
import 'package:dashboard_nurse_hospital/view/doctor_view.dart';
import 'package:dashboard_nurse_hospital/view/emerg_page.dart';
import 'package:dashboard_nurse_hospital/view/get_started.dart';
import 'package:dashboard_nurse_hospital/view/landing_page.dart';
import 'package:dashboard_nurse_hospital/view/login_page.dart';
import 'package:dashboard_nurse_hospital/view/token_managment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';

// Global variables
User? user;
String role = "staff";
DocumentSnapshot? userDoc;
DocumentSnapshot? clinicSnapshot;
DocumentReference? clinicDocRef;
DocumentSnapshot? doctorSnapshot;
String doctorId = "";

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MedizaDashboard()));
}

class MedizaDashboard extends ConsumerWidget {
  const MedizaDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mediza Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return FutureBuilder<Widget>(
            future: _determineHomeScreen(context, user.email ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text('Error: ${snapshot.error}'),
                  ),
                );
              }

              return snapshot.data ??  GetStartedPage();
            },
          );
        }
        return  GetStartedPage();
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Future<Widget> _determineHomeScreen(BuildContext context, String email) async {
    try {
      // Fetch all roles
      final adminSnapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .where('admins', arrayContains: email)
          .get();

      final doctorSnapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .where('doctors', arrayContains: email)
          .get();

      final staffSnapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .where('staffs', arrayContains: email)
          .get();

      final receptionistSnapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .where('receptionists', arrayContains: email)
          .get();

      // Check for multiple roles
      bool isAdmin = adminSnapshot.docs.isNotEmpty;
      bool isDoctor = doctorSnapshot.docs.isNotEmpty;
      bool isStaff = staffSnapshot.docs.isNotEmpty;
      bool isReceptionist = receptionistSnapshot.docs.isNotEmpty;

      // If user has multiple roles, show role selection dialog
      if ((isAdmin && isDoctor) || (isAdmin && isStaff) || (isDoctor && isStaff)) {
        final selectedRole = await _showRoleSelectionDialog(
          context,
          isAdmin,
          isDoctor,
          isStaff,
          isReceptionist,
        );

        if (selectedRole == null) {
          await FirebaseAuth.instance.signOut();
          return  GetStartedPage();
        }

        // Handle clinic selection for the chosen role
        return await _handleRoleNavigation(
          context,
          selectedRole,
          email,
          adminSnapshot.docs,
          doctorSnapshot.docs,
          staffSnapshot.docs,
          receptionistSnapshot.docs,
        );
      }

      // Single role handling
      if (isAdmin) {
        return LandingPage(email: email);
      } else if (isDoctor) {
        if (doctorSnapshot.docs.length > 1) {
          // Show clinic selection for doctors with multiple clinics
          final selectedClinic = await _showClinicSelectionDialog(
            context,
            doctorSnapshot.docs,
          );
          if (selectedClinic != null) {
            return DoctorDashboard(email: email);
          }
        } else {
          return DoctorDashboard(email: email);
        }
      } else if (isStaff) {
        return TokenManagement(email: email);
      } else if (isReceptionist) {
        return AppointmentList(email: email);
      }

      // No role found
      await FirebaseAuth.instance.signOut();
      return  GetStartedPage();
    } catch (e) {
      debugPrint('Error determining role: $e');
      await FirebaseAuth.instance.signOut();
      return  GetStartedPage();
    }
  }

  Future<String?> _showRoleSelectionDialog(
      BuildContext context,
      bool isAdmin,
      bool isDoctor,
      bool isStaff,
      bool isReceptionist,
      ) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade300, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "Select Your Role",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isAdmin)
                  _buildRoleOption(
                    context,
                    "Admin",
                    Icons.admin_panel_settings,
                    Colors.green,
                  ),
                if (isDoctor)
                  _buildRoleOption(
                    context,
                    "Doctor",
                    Icons.medical_services,
                    Colors.red,
                  ),
                if (isStaff)
                  _buildRoleOption(
                    context,
                    "Staff",
                    Icons.people,
                    Colors.orange,
                  ),
                if (isReceptionist)
                  _buildRoleOption(
                    context,
                    "Receptionist",
                    Icons.receipt_long,
                    Colors.purple,
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(null);
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleOption(
      BuildContext context,
      String role,
      IconData icon,
      Color iconColor,
      ) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        role,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      onTap: () => Navigator.of(context).pop(role),
    );
  }

  Future<String?> _showClinicSelectionDialog(
      BuildContext context,
      List<QueryDocumentSnapshot> clinics,
      ) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade300, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_hospital, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "Select Clinic",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: ListView.separated(
                    itemCount: clinics.length,
                    separatorBuilder: (context, index) => const Divider(
                      color: Colors.white24,
                      thickness: 1,
                    ),
                    itemBuilder: (context, index) {
                      final clinic = clinics[index];
                      return ListTile(
                        title: Text(
                          clinic['name'] ?? 'Unknown Clinic',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () => Navigator.of(context).pop(clinic.id),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Widget> _handleRoleNavigation(
      BuildContext context,
      String role,
      String email,
      List<QueryDocumentSnapshot> adminClinics,
      List<QueryDocumentSnapshot> doctorClinics,
      List<QueryDocumentSnapshot> staffClinics,
      List<QueryDocumentSnapshot> receptionistClinics,
      ) async {
    switch (role) {
      case 'Admin':
        return LandingPage(email: email);
      case 'Doctor':
        if (doctorClinics.length > 1) {
          final selectedClinicId = await _showClinicSelectionDialog(
            context,
            doctorClinics,
          );
          if (selectedClinicId != null) {
            return DoctorDashboard(email: email);
          }
        }
        return DoctorDashboard(email: email);
      case 'Staff':
        return TokenManagement(email: email);
      case 'Receptionist':
        return AppointmentList(email: email);
      default:
        await FirebaseAuth.instance.signOut();
        return  GetStartedPage();
    }
  }
}