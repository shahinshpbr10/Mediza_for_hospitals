// import 'package:dashboard_nurse_hospital/view/account_creation_admin.dart';
// import 'package:dashboard_nurse_hospital/view/account_creation_page.dart';
// import 'package:dashboard_nurse_hospital/view/admin_dashboard_page.dart';
// import 'package:dashboard_nurse_hospital/view/dashboard_page.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
//
// import 'forget_pass_page.dart';
//
//
// class CommonLoginPage extends StatefulWidget {
//   @override
//   _CommonLoginPageState createState() => _CommonLoginPageState();
// }
//
// class _CommonLoginPageState extends State<CommonLoginPage> {
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//
//   Future<void> login() async {
//     try {
//       String email = emailController.text.trim();
//       String password = passwordController.text.trim();
//
//       UserCredential userCredential = await FirebaseAuth.instance
//           .signInWithEmailAndPassword(email: email, password: password);
//
//       // Check email verification
//       if (!userCredential.user!.emailVerified) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Please verify your email.')),
//         );
//         return;
//       }
//
//       // Check user type and approval status
//       DocumentSnapshot doc = await FirebaseFirestore.instance
//           .collection('dashboard_users')
//           .doc(userCredential.user!.uid)
//           .get();
//
//       if (doc.exists) {
//         String userType = doc['role'];
//         String approvalStatus = doc['approval_status'];
//
//         if (approvalStatus == 'approved') {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Login successful.')),
//           );
//
//           // Navigate to the respective page based on user type
//           if (userType == 'Admin') {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (context) => AdminDashboardPage()),
//             );
//           } else {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (context) => Dashboard()),
//             );
//           }
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Your account is not yet approved.')),
//           );
//         }
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('No user found with this email.')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
//         centerTitle: true,
//         backgroundColor: Colors.blueAccent,
//         elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Center(
//                 child: CircleAvatar(
//                   radius: 50,
//                   backgroundColor: Colors.blue.shade100,
//                   child: Icon(
//                     Icons.person,
//                     size: 60,
//                     color: Colors.blueAccent,
//                   ),
//                 ),
//               ),
//               SizedBox(height: 20),
//               Text(
//                 'Welcome Back!',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blueAccent,
//                 ),
//               ),
//               SizedBox(height: 10),
//               Text(
//                 'Please log in to your account',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 16, color: Colors.grey),
//               ),
//               SizedBox(height: 30),
//               TextField(
//                 controller: emailController,
//                 decoration: InputDecoration(
//                   labelText: 'Email',
//                   prefixIcon: Icon(Icons.email, color: Colors.blueAccent),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 keyboardType: TextInputType.emailAddress,
//               ),
//               SizedBox(height: 20),
//               TextField(
//                 controller: passwordController,
//                 decoration: InputDecoration(
//                   labelText: 'Password',
//                   prefixIcon: Icon(Icons.lock, color: Colors.blueAccent),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 obscureText: true,
//               ),
//               SizedBox(height: 20),
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: TextButton(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => ForgetPasswordPage()),
//                     );
//                   },
//                   child: Text(
//                     'Forgot Password?',
//                     style: TextStyle(color: Colors.blueAccent),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: login,
//                 style: ElevatedButton.styleFrom(
//                   padding: EdgeInsets.symmetric(vertical: 15),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   backgroundColor: Colors.blueAccent,
//                 ),
//                 child: Text(
//                   'Login',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ),
//               SizedBox(height: 20),
//               Center(
//                 child: Text.rich(
//                   TextSpan(
//                     text: "Don't have an account? ",
//                     style: TextStyle(color: Colors.grey),
//                     children: [
//                       TextSpan(
//                         text: 'Sign Up',
//                         style: TextStyle(
//                           color: Colors.blueAccent,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         recognizer: TapGestureRecognizer()
//                           ..onTap = () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) =>
//                               ),
//                             );
//                           },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
