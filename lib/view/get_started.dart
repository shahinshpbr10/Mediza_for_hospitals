import 'package:dashboard_nurse_hospital/view/doctor_view.dart';
import 'package:dashboard_nurse_hospital/view/landing_page.dart';
import 'package:dashboard_nurse_hospital/view/token_managment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../main.dart';
import 'account_creation_admin.dart';
import '../../../core/responsive.dart';

final pageTitleProvider = Provider<String>((ref) => 'Mediza');
final pagesubtitleProvider = Provider<String>((ref) => 'Login to continue');

class GetStartedPage extends ConsumerStatefulWidget {
  @override
  _GetStartedPageState createState() => _GetStartedPageState();
}

class _GetStartedPageState extends ConsumerState<GetStartedPage> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final pageTitle = ref.watch(pageTitleProvider);
    final subtitle = ref.watch(pagesubtitleProvider);

    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.grey.shade100),
          Responsive(
            mobile: _buildLoginForm(pageTitle, subtitle),
            tablet: _buildLoginForm(pageTitle, subtitle),
            desktop: _buildLoginForm(pageTitle, subtitle),
          ),
          if (isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.blue)),
        ],
      ),
    );
  }

  Widget _buildLoginForm(String pageTitle, String subtitle) {
    return Center(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade300, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              pageTitle,
              style: GoogleFonts.lobster(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: emailController,
              label: 'Email',
              icon: Icons.email,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: passwordController,
              label: 'Password',
              icon: Icons.lock,
              isPassword: true,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _forgotPassword(context),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loginUser(context),
              child: const Text(
                'Login',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.blue.shade700, backgroundColor: Colors.white,
                elevation: 5,
                shadowColor: Colors.blue.shade100,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white),
                children: [
                  const TextSpan(text: "New user? "),
                  TextSpan(
                    text: "Create account",
                    style: const TextStyle(color: Colors.yellowAccent),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => CreateAccountPage(),
                          ),
                        );
                      },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white),
        filled: true,
        fillColor: Colors.white24,
        labelStyle: const TextStyle(color: Colors.white),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }
  Future<void> _forgotPassword(BuildContext context) async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showCustomSnackbar(
        context,
        'Please enter your email address.',
        Icons.error,
        Colors.red,
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      showCustomSnackbar(
        context,
        'Password reset email sent. Check your inbox.',
        Icons.check,
        Colors.green,
      );
    } catch (e) {
      showCustomSnackbar(
        context,
        'Error occurred while sending password reset email.',
        Icons.error,
        Colors.red,
      );
    }
  }
  Future<void> _loginUser(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showCustomSnackbar(
        context,
        'Please fill in all required fields.',
        Icons.error,
        Colors.red,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Authenticate User
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user != null) {
        if (!user.emailVerified) {
          await user.sendEmailVerification();
          await FirebaseAuth.instance.signOut();
          showCustomSnackbar(
            context,
            'Email not verified. Please check your email.',
            Icons.error,
            Colors.red,
          );
          return;
        }

        // Fetch Clinics containing the user's email
        final clinicSnapshot = await FirebaseFirestore.instance
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

        final adminClinics = clinicSnapshot.docs;
        final doctorClinics = doctorSnapshot.docs;
        final staffClinics = staffSnapshot.docs;

        // Determine Role(s) and Navigate
        if (adminClinics.isNotEmpty && doctorClinics.isNotEmpty) {
          _showRoleSelectionDialog(context, email, adminClinics, doctorClinics);
        } else if (adminClinics.isNotEmpty) {
          _navigateToClinic(context, email, adminClinics, 'Admin');
        } else if (doctorClinics.isNotEmpty) {
          if (doctorClinics.length > 1) {
            _showClinicSelectionDialog(context, doctorClinics, email, 'Doctor');
          } else {
            _navigateToClinic(context, email, doctorClinics, 'Doctor');
          }
        } else if (staffClinics.isNotEmpty) {
          _navigateToClinic(context, email, staffClinics, 'Staff');
        } else {
          showCustomSnackbar(
            context,
            'No roles or clinics found for this email.',
            Icons.error,
            Colors.red,
          );
        }
      }
    } catch (e) {
      showCustomSnackbar(
        context,
        'Login failed: ${e.toString()}',
        Icons.error,
        Colors.red,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showRoleSelectionDialog(
      BuildContext context,
      String email,
      List<QueryDocumentSnapshot> adminClinics,
      List<QueryDocumentSnapshot> doctorClinics,
      ) {
    showDialog(
      context: context,
      builder: (context) {
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue[900]),
                      SizedBox(width: 8),
                      Text(
                        "Select Role",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    "You have multiple roles in one or more clinics. Please select your role to continue:",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.admin_panel_settings, color: Colors.green),
                    title: Text(
                      "Admin",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToClinic(context, email, adminClinics, 'Admin');
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.medical_services, color: Colors.red),
                    title: Text(
                      "Doctor",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (doctorClinics.length > 1) {
                        _showClinicSelectionDialog(context, doctorClinics, email, 'Doctor');
                      } else {
                        _navigateToClinic(context, email, doctorClinics, 'Doctor');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  void _showClinicSelectionDialog(
      BuildContext context,
      List<QueryDocumentSnapshot> clinics,
      String email,
      String role,
      ) {
    showDialog(barrierDismissible: false,
      context: context,
      builder: (context) {
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
              boxShadow: [
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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
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
                ),
                SizedBox(
                  height: 250, // Increased height for better scrolling
                  child: clinics.isNotEmpty
                      ? ListView.separated(
                    itemCount: clinics.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.grey.shade300,
                      thickness: 1,
                    ),
                    itemBuilder: (context, index) {
                      final clinicName =
                          clinics[index]['name'] ?? 'Unknown Clinic';
                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToClinic(context, email,
                              [clinics[index]], role);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade100,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.medical_services,
                                color: Colors.blueAccent,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  clinicName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                      : Center(
                    child: Text(
                      "No clinics available.",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
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




  void _navigateToClinic(
      BuildContext context,
      String email,
      List<QueryDocumentSnapshot> clinics,
      String role,
      ) {
    final clinic = clinics.first; // For single-clinic navigation
    switch (role) {
      case 'Admin':
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (context) => LandingPage(email:email)),
        );
        break;
      case 'Doctor':
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (context) => DoctorDashboard(email: email),
          ),
        );
        break;
      case 'Staff':
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (context) => const TokenManagement(),
          ),
        );
        break;
      default:
        showCustomSnackbar(
          context,
          'Invalid role selected.',
          Icons.error,
          Colors.red,
        );
    }
  }







  void showCustomSnackbar(
      BuildContext context,
      String message,
      IconData icon,
      Color color,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
