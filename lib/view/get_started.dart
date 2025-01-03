
import 'package:dashboard_nurse_hospital/view/landing_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
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
          Container(
            color: Colors.white,
          ),
          Responsive(
            mobile: _buildLoginForm(pageTitle , subtitle),
            tablet: _buildLoginForm(pageTitle , subtitle),
            desktop: _buildLoginForm(pageTitle, subtitle),
          ),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          'Please use desktop version for access',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLoginForm(String pageTitle, String subtitle) {
    return Center(
      child: Container(
        width: 400,
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              pageTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(subtitle),
            SizedBox(height: 24),
            _buildTextField(
              controller: emailController,
              label: 'Email',
              icon: Icons.email,
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: passwordController,
              label: 'Password',
              icon: Icons.lock,
              isPassword: true,
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _forgotPassword(context),
                child: Text('Forgot Password?'),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loginUser(context),
              child: Text('Login'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
            SizedBox(height: 16),
            RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.black),
                children: [
                  TextSpan(text: "New user? "),
                  TextSpan(
                    text: "Create account",
                    style: TextStyle(color: Colors.blue),
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
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(),
      ),
    );
  }

  // Keeping all the original backend functions unchanged
  void _forgotPassword(BuildContext context) async {
    String email = emailController.text.trim();

    if (email.isEmpty) {
      showCustomSnackbarl(
          context, 'Please enter your email address.', Icons.error, Colors.red);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      showCustomSnackbarl(
          context,
          'Password reset email sent. Check your inbox.',
          Icons.check,
          Colors.green);
    } catch (e) {
      showCustomSnackbarl(
          context,
          'Error occurred while sending password reset email.',
          Icons.error,
          Colors.red);
    }
  }

  void _loginUser(BuildContext context) async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showCustomSnackbarl(context, 'Please fill in all required fields.', Icons.error, Colors.red);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      user = userCredential.user;

      if (user != null) {
        if (!user!.emailVerified) {
          await user!.sendEmailVerification();
          await Future.delayed(Duration(seconds: 3));
          await FirebaseAuth.instance.signOut();

          showCustomSnackbarl(
            context,
            'Email not verified. Please check your email.',
            Icons.error,
            Colors.red,
          );
        } else {
          // Check if the email exists in doctors or nurses sub-collection
          QuerySnapshot doctorSnapshot = await FirebaseFirestore.instance
              .collectionGroup('doctors')
              .where('email', isEqualTo: email)
              .get();

          QuerySnapshot nurseSnapshot = await FirebaseFirestore.instance
              .collectionGroup('nurses')
              .where('email', isEqualTo: email)
              .get();

          DocumentSnapshot adminDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();

          final isDoctor = doctorSnapshot.docs.isNotEmpty;
          final isNurse = nurseSnapshot.docs.isNotEmpty;
          final isAdmin = adminDoc.exists;

          if (isDoctor && isAdmin) {
            // Show dialog to select role
            _showRoleSelectionDialog(context);
            return;
          } else if (isDoctor) {
            // Redirect to Doctor Dashboard
            Navigator.pushReplacement(
              context,
              CupertinoPageRoute(builder: (context) => Scaffold(body: Text("Doctor")),
            ));
            return;
          } else if (isNurse) {
            // Redirect to Nurse Dashboard
            Navigator.pushReplacement(
              context,
              CupertinoPageRoute(builder: (context) => Scaffold(body: Text("Nurse")),
            ));
            return;
          } else if (isAdmin) {
            // Redirect to Admin Dashboard
            Navigator.pushReplacement(
              context,
              CupertinoPageRoute(builder: (context) => LandingPage()),
            );
            return;
          } else {
            showCustomSnackbarl(
              context,
              'No user found with this email.',
              Icons.error,
              Colors.red,
            );
          }
        }
      }
    } catch (e) {
      showCustomSnackbarl(context, e.toString(), Icons.error, Colors.red);
      print(e);
    }

    setState(() {
      isLoading = false;
    });
  }

  void _showRoleSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Role"),
          content: Text("You have multiple roles. Please select the role you want to navigate to."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  CupertinoPageRoute(builder: (context) => Scaffold(body: Text("Doctor"),)),
                );
              },
              child: Text("Doctor"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  CupertinoPageRoute(builder: (context) => LandingPage()),
                );
              },
              child: Text("Admin"),
            ),
          ],
        );
      },
    );
  }

}

void showCustomSnackbarl(
    BuildContext context, String message, IconData icon, Color backgroundColor,
    [Duration duration = const Duration(seconds: 4)]) {
  final snackBar = SnackBar(
    duration: duration,
    content: Row(
      children: [
        Icon(icon, color: Colors.white),
        SizedBox(width: 10),
        Expanded(child: Text(message)),
      ],
    ),
    backgroundColor: backgroundColor,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}