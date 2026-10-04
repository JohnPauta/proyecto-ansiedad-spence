import 'package:go_router/go_router.dart';

import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/doctor_dashboard_screen.dart';
import 'screens/patient_info_screen.dart';
import 'screens/patient_test_screen.dart';
import 'screens/test_detail_screen.dart';
import 'screens/patient_history_screen.dart';
import 'screens/patients_list_screen.dart';
import 'screens/new_patient_screen.dart';
import 'screens/patient_detail_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // --- Pantalla de bienvenida ---
    GoRoute(
      path: '/',
      name: 'welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),

    // --- Login del médico ---
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),

    // --- Dashboard del médico ---
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const DoctorDashboardScreen(),
    ),

    // --- Datos previos al test (Lunny pide nombre y edad) ---
    GoRoute(
      path: '/patient-info',
      name: 'patient-info',
      builder: (context, state) => const PatientInfoScreen(),
    ),

    // --- Test de Spence (recibe nombre y edad por query params) ---
    GoRoute(
      path: '/test',
      name: 'test',
      builder: (context, state) {
        final name = state.uri.queryParameters['name'] ?? 'Paciente';
        final age = int.tryParse(state.uri.queryParameters['age'] ?? '0') ?? 0;
        final patientId = state.uri.queryParameters['patientId'];
        final doctorId = state.uri.queryParameters['doctorId'];
        final code = state.uri.queryParameters['code'];

        return PatientTestScreen(
          patientName: name,
          patientAge: age,
          patientId: patientId,
          doctorId: doctorId,
          invitationCode: code,
        );
      },
    ),

    // --- Detalle del informe de un test específico ---
    GoRoute(
      path: '/test-detail/:id',
      name: 'test-detail',
      builder: (context, state) {
        final testId = state.pathParameters['id']!;
        return TestDetailScreen(testId: testId);
      },
    ),

    // --- Evolución histórica del paciente ---
    GoRoute(
      path: '/patient-history/:name',
      name: 'patient-history',
      builder: (context, state) {
        final name = Uri.decodeComponent(state.pathParameters['name']!);
        return PatientHistoryScreen(patientName: name);
      },
    ),
    // --- Lista de pacientes ---
    GoRoute(
      path: '/patients',
      name: 'patients',
      builder: (context, state) => const PatientsListScreen(),
    ),
    GoRoute(
      path: '/patients/new',
      name: 'new-patient',
      builder: (context, state) => const NewPatientScreen(),
    ),
    GoRoute(
      path: '/patients/:id',
      name: 'patient-detail',
      builder: (context, state) {
        final patientId = state.pathParameters['id']!;
        return PatientDetailScreen(patientId: patientId);
      },
    ),
  ],
);
