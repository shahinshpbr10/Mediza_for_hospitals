import 'package:flutter/material.dart';

import 'add_users_page.dart';

class AdminDashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Dashboard')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => StaffCreation(clinicId: '')),
            );
          },
          child: Text('Add User'),
        ),
      ),
    );
  }
}
