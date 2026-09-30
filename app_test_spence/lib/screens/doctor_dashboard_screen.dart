import 'package:flutter/material.dart';

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Médico'),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(child: Text('Panel del Médico (en construcción)')),
    );
  }
}
