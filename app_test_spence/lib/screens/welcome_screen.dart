import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC), // Color de fondo claro
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono o logo
              const Icon(
                Icons.psychology_alt_outlined,
                size: 80,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 16),
              // Título
              const Text(
                'Bienvenido a Spence\nMentalHealth',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 12),
              // Subtítulo
              const Text(
                'Cuidamos tu bienestar emocional. Un espacio seguro, acompañado y adaptado a ti.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 48),
              // Botón para el rol de Paciente
              _buildRoleButton(
                context,
                icon: Icons.child_care,
                title: 'Paciente / Niño o Joven',
                subtitle: 'Realiza tu evaluación de forma tranquila',
                color: Colors.teal.shade50,
                onTap: () {
                  context.push('/patient-info');
                  print('Navegando a test de paciente...');
                },
              ),
              const SizedBox(height: 16),
              // Botón para el rol de Médico
              _buildRoleButton(
                context,
                icon: Icons.medical_services_outlined,
                title: 'Soy Médico / Profesional',
                subtitle: 'Accede al panel de seguimiento clínico',
                color: Colors.blue.shade50,
                onTap: () {
                  // TODO: Navegar a la pantalla de login del médico
                  context.push('/login');
                  print('Navegando a login de médico...');
                },
              ),
              const SizedBox(height: 32),
              // Texto de emergencia
              const Text(
                'Si necesitas ayuda urgente, contacta a emergencias.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget reutilizable para los botones de rol
  Widget _buildRoleButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 36, color: Colors.deepPurple),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
