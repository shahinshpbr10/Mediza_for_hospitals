import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgetPasswordPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();

  Future<void> resetPassword(BuildContext context) async {
    try {
      String email = emailController.text.trim();

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent.')),
      );
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
        title: Text('Reset Password', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(
                    Icons.lock_reset,
                    size: 60,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Forgot Your Password?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Enter your email below to receive a password reset link.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 30),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: Icon(Icons.email, color: Colors.blueAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => resetPassword(context),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.blueAccent,
                ),
                child: Text(
                  'Send Reset Link',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: Colors.blueAccent),
                label: Text(
                  'Back to Login',
                  style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                ),
                style: TextButton.styleFrom(alignment: Alignment.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
