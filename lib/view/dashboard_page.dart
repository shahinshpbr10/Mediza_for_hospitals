import 'package:dashboard_nurse_hospital/view/token_managment.dart';
import 'package:flutter/material.dart';
import 'appointment_listing.dart';
import 'emerg_page.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF2C3E50),
          title: const Text(
            'Mediza Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: const Color(0xFF34495E),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(
                icon: Icon(Icons.calendar_today),
                text: 'Appointments',
              ),
              Tab(
                icon: Icon(Icons.token),
                text: 'Tokens',
              ),
              Tab(
                icon: Icon(Icons.warning),
                text: 'Emergencies',
              ),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
            ),
          ),
          child: const TabBarView(
            children: [
              AppointmentList(),
              TokenManagement(),
              EmergencyPage(),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          backgroundColor: const Color(0xFF2ECC71),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}