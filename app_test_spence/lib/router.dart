import 'package:go_router/go_router.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/doctor_dashboard_screen.dart';
import 'screens/patient_test_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const DoctorDashboardScreen(),
    ),
    GoRoute(
      path: '/test',
      name: 'test',
      builder: (context, state) => const PatientTestScreen(),
    ),
  ],
);