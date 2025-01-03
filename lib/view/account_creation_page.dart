import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AccountCreationPage extends StatefulWidget {
  @override
  _AccountCreationPageState createState() => _AccountCreationPageState();
}

class _AccountCreationPageState extends State<AccountCreationPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? selectedRole;
  final List<String> roles = ['Nurse', 'Receptionist', 'Doctor', 'Admin'];
  bool isAdminCreation = false;

  @override
  void initState() {
    super.initState();
    _checkIfAdminExists();
  }

  Future<void> _checkIfAdminExists() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('dashboard_users')
          .where('role', isEqualTo: 'Admin')
          .limit(1)
          .get();

      setState(() {
        isAdminCreation = snapshot.docs.isEmpty;
        if (isAdminCreation) {
          selectedRole = 'Admin';
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking admin status: $e')),
      );
    }
  }

  Future<void> createAccount() async {
    try {
      String email = emailController.text;
      String password = passwordController.text;
      String name = nameController.text;

      if (!isAdminCreation && selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a role.')),
        );
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance
          .collection('dashboard_users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'name': name,
        'role': isAdminCreation ? 'Admin' : selectedRole,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account created successfully!')),
      );

      if (!isAdminCreation) {
        emailController.clear();
        nameController.clear();
        passwordController.clear();
        setState(() {
          selectedRole = null;
        });
      }
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
        title: Text(isAdminCreation ? 'Create Admin Account' : 'Create Account'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAdminCreation
                  ? 'Create the Admin Account'
                  : 'Create a New Account',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),
            if (!isAdminCreation)
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: roles.where((role) => role != 'Admin').map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRole = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
              ),
            SizedBox(height: 15),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: createAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  isAdminCreation ? 'Create Admin Account' : 'Create Account',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
