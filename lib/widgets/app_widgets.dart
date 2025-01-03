import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';


import '../controller/auth_controller.dart';

// Method to build a text field with a label and icon
Widget buildTextField(BuildContext context, String label, IconData icon, TextEditingController controller) {
  return SizedBox(
    width: 280,
    child: TextFormField(
      controller: controller,
      style: TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black54, size: 16),
        labelText: label,
        labelStyle: TextStyle(color: Colors.black54),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: Colors.black54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: Colors.black54),
        ),
      ),
    ),
  );
}




// Method to build the button with the specified padding and icon
Widget buildButton(BuildContext context, String text, EdgeInsetsGeometry padding, IconData icon, VoidCallback onPressed) {
  return ElevatedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 20),
    label: Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    ),
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.lightBlueAccent,
      elevation: 8,
      padding: padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
    ),
  );
}

// Method to build the divider with text
Widget buildDividerWithText(String text) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 120,
        child: Divider(
          color: Colors.black54,
          thickness: 1,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(
          text,
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
      ),
      Container(
        width: 120,
        child: Divider(
          color: Colors.black54,
          thickness: 1,
        ),
      ),
    ],
  );
}

Widget buildSocialLoginButtons(BuildContext context) {


  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      GestureDetector(
        onTap: () async {
          final AuthController authController = AuthController();
          await authController.signInWithGoogle(context);
        },
        child: Image.asset(
          'assets/google.png',
          width: 20,
          height: 20,
        ),
      ),

    ],
  );
}

// Method to build the footer
Widget buildFooter() {
  return Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        "Powered by",
        style: GoogleFonts.poppins(
          textStyle: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      SizedBox(width: 5),
      Image(
        image: AssetImage('assets/qvtext.png'),
        width: 90,
      ),
    ],
  );
}

// A simple BulletPoint widget
class BulletPoint extends StatelessWidget {
  final String text;
  BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: Colors.white, size: 16),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }
}
