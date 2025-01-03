import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';



class AuthController {


  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;


  final GoogleSignIn googleSignIn = GoogleSignIn(
    clientId: '853054702494-nfiesb64gs1iu44rrpmv678ba6cq7kau.apps.googleusercontent.com',
  );

  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      print('Attempting Google sign-in');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {

        _showSnackbar(context, 'Google sign-in was cancelled');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      _showSnackbar(context, 'Google sign-in successful: ${userCredential.user?.displayName}');
      return userCredential;
    } catch (e) {
      print("Error during Google Sign-In: $e");
      _showSnackbar(context, 'Failed to sign in with Google: $e');
      return null;
    }
  }


  Future<void> signOut(BuildContext context) async {
    try {
      await googleSignIn.signOut();
      await _auth.signOut();
      _showSnackbar(context, 'Successfully signed out');
    } catch (e) {
      _showSnackbar(context, 'Failed to sign out: $e');
    }
  }


  // Future<void> login(BuildContext context, String email, String password) async {
  //   try {
  //
  //     if (email.isEmpty || password.isEmpty) {
  //       _showCustomSnackBar(context, 'Email and password cannot be empty.');
  //       return;
  //     }
  //
  //
  //     UserCredential userCredential = await _auth.signInWithEmailAndPassword(
  //       email: email,
  //       password: password,
  //     );
  //     User? user = userCredential.user;
  //
  //     if (user != null) {
  //
  //       QuerySnapshot doctorQuery = await FirebaseFirestore.instance
  //           .collectionGroup('doctors')
  //           .where('email', isEqualTo: email)
  //           .get();
  //
  //       if (doctorQuery.docs.isNotEmpty) {
  //         String role = doctorQuery.docs.first.get('role');
  //         if (role == 'doctor') {
  //
  //           Navigator.pushReplacement(
  //             context,
  //             MaterialPageRoute(builder: (context) => DoctorDashboard()),
  //           );
  //           _showCustomSnackBar(context, 'Logged in as Doctor', isError: false);
  //           return;
  //         }
  //       }
  //
  //       // If not a doctor, check the 'clinics' collection and verify the role
  //       DocumentSnapshot clinicDoc = await FirebaseFirestore.instance.collection('clinics').doc(user.uid).get();
  //
  //       if (clinicDoc.exists) {
  //         String clinicId = clinicDoc['clinicId'];
  //         String role = clinicDoc.get('role');
  //
  //         if (role == 'superAdmin') {
  //           if (_isProfileComplete(clinicDoc)) {
  //
  //             Navigator.pushReplacement(
  //               context,
  //               MaterialPageRoute(builder: (context) => ClinicHomePage()),
  //             );
  //             _showCustomSnackBar(context, 'Logged in as Clinic User', isError: false);
  //           } else {
  //
  //             Navigator.pushReplacement(
  //               context,
  //               MaterialPageRoute(builder: (context) => SettingsPage(clinicId: clinicId)),
  //             );
  //             _showCustomSnackBar(context, 'Please complete your profile setup.', isError: false);
  //           }
  //           return;
  //         }
  //       }
  //
  //
  //       _showCustomSnackBar(context, 'No matching user data found.');
  //     }
  //   } on FirebaseAuthException catch (e) {
  //
  //     _showCustomSnackBar(context, _getFirebaseErrorMessage(e.code));
  //   } catch (e) {
  //     print(e);
  //
  //    // _showCustomSnackBar(context, 'An unexpected error occurred. Please try again.');
  //   }
  // }

  bool _isProfileComplete(DocumentSnapshot userDoc) {
    return userDoc['phone'] != null && userDoc['address'] != null;
  }

// Display a custom SnackBar
  void _showCustomSnackBar(BuildContext context, String message, {bool isError = true}) {
    final snackBar = SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? Colors.redAccent : Colors.greenAccent,
      duration: Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
    if(context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }


  String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already in use. Try logging in or using a different email.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please contact support.';
      default:
        return 'An unknown error occurred. Check your credentials and please try again.';
    }
  }

}


bool _isProfileComplete(DocumentSnapshot userDoc) {
  return userDoc['phone'] != null && userDoc['address'] != null;
}

void _showSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.blueAccent,
      duration: Duration(seconds: 3),
    ),
  );
}

