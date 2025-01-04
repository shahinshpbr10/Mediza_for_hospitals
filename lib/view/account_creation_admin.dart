import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import '../core/responsive.dart';
import 'get_started.dart';

final pageTitleProvider = Provider<String>((ref) => 'Create Account');

class CreateAccountPage extends ConsumerStatefulWidget {
  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends ConsumerState<CreateAccountPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String phoneNumberWithCountryCode = "";
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final pageTitle = ref.watch(pageTitleProvider);

    return Scaffold(

      body: Stack(
        children: [
          Container(color: Colors.grey.shade100),
          Center(
            child: Responsive(
              mobile: _buildForm(pageTitle),
              tablet: _buildDesktopLayout(pageTitle),
              desktop: _buildDesktopLayout(pageTitle),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black45,
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }



  Widget _buildDesktopLayout(String pageTitle) {
    return Row(
      children: [
        Expanded(
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
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Join Us',
                    style: GoogleFonts.lobster(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                ),
                SizedBox(height: 16),
                Text(
                  'Create your account to get started.',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: _buildForm(pageTitle)),
      ],
    );
  }

  Widget _buildForm(String pageTitle) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(32),
      child: Center(
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.person_add, size: 80, color: Colors.white),
              SizedBox(height: 16),
              Text(
                pageTitle,
                style: GoogleFonts.lobster(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              _buildTextField('Name', Icons.person, nameController),
              SizedBox(height: 16),
              _buildTextField('Email', Icons.email, emailController),
              SizedBox(height: 16),
              _buildPhoneField(),
              SizedBox(height: 16),
              _buildTextField('Password', Icons.lock, passwordController, isPassword: true),
              SizedBox(height: 16),
              _buildTextField('Confirm Password', Icons.lock_outline, confirmPassController, isPassword: true),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : () => _handleSignup(context),
                child: Text('Create Account',),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.white ,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return IntlPhoneField(
      controller: phoneController,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      initialCountryCode: 'IN',
      onChanged: (phone) => phoneNumberWithCountryCode = phone.completeNumber,
    );
  }


Future<void> _handleSignup(BuildContext context) async {
    if (!_validateForm(context)) return;

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneNumberWithCountryCode,
          'created_at': FieldValue.serverTimestamp(),
          'user_id': userCredential.user!.uid,
        });

        await userCredential.user!.sendEmailVerification();
        _showSuccessDialog(context);
      }
    } catch (e) {
      _showSnackbar(context, 'Signup failed: $e', Colors.red);
    }

    setState(() => isLoading = false);
  }

  bool _validateForm(BuildContext context) {
    if (nameController.text.isEmpty) {
      _showSnackbar(context, 'Please enter your name', Colors.orange);
      return false;
    }
    if (!emailController.text.contains('@')) {
      _showSnackbar(context, 'Please enter a valid email', Colors.orange);
      return false;
    }
    if (phoneNumberWithCountryCode.isEmpty) {
      _showSnackbar(context, 'Please enter a valid phone number', Colors.orange);
      return false;
    }
    if (passwordController.text.length < 6) {
      _showSnackbar(context, 'Password must be at least 6 characters', Colors.orange);
      return false;
    }
    if (passwordController.text != confirmPassController.text) {
      _showSnackbar(context, 'Passwords do not match', Colors.orange);
      return false;
    }
    return true;
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Success'),
        content: Text('Account created! Please verify your email.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              CupertinoPageRoute(builder: (context) => GetStartedPage()),
            ),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }
}