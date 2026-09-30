import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class PatientService {
  /// Genera un código único tipo "MG-4821"
  static String generateInvitationCode(String fullName) {
    final initials = fullName
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    final random = Random();
    final number = random.nextInt(9000) + 1000; // 1000-9999
    return '${initials.isEmpty ? 'PA' : initials}-$number';
  }

  /// Crea un nuevo paciente y lo asigna al médico actual
  static Future<Map<String, dynamic>> createPatient({
    required String fullName,
    required int age,
    required String guardianName,
    required String guardianPhone,
    String? notes,
  }) async {
    final supabase = Supabase.instance.client;
    final doctorId = supabase.auth.currentUser?.id;

    if (doctorId == null) throw Exception('No hay sesión activa');

    // Generar código único
    String code = generateInvitationCode(fullName);
    bool codeExists = true;
    int attempts = 0;

    // Asegurar que el código sea único
    while (codeExists && attempts < 10) {
      final existing = await supabase
          .from('profiles')
          .select('id')
          .eq('invitation_code', code)
          .maybeSingle();

      if (existing == null) {
        codeExists = false;
      } else {
        code = generateInvitationCode(fullName);
        attempts++;
      }
    }

    // Calcular fecha de nacimiento aproximada
    final birthDate = DateTime.now().subtract(Duration(days: age * 365));

    // Crear el perfil del paciente
    final patientResponse = await supabase
        .from('profiles')
        .insert({
          'role': 'patient',
          'full_name': fullName,
          'email': 'paciente_${code.toLowerCase()}@spence.local',
          'birth_date': birthDate.toIso8601String().split('T').first,
          'guardian_name': guardianName,
          'guardian_phone': guardianPhone,
          'invitation_code': code,
          'created_by': doctorId,
        })
        .select()
        .single();

    final patientId = patientResponse['id'];

    // Asignar al médico
    await supabase.from('doctor_patient').insert({
      'doctor_id': doctorId,
      'patient_id': patientId,
      'status': 'active',
    });

    return patientResponse;
  }

  /// Obtiene un paciente por su ID
  static Future<Map<String, dynamic>?> getPatient(String patientId) async {
    final supabase = Supabase.instance.client;
    return await supabase
        .from('profiles')
        .select('*')
        .eq('id', patientId)
        .maybeSingle();
  }

  /// Obtiene todos los tests de un paciente
  static Future<List<Map<String, dynamic>>> getPatientTests(
      String patientName) async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('spence_tests')
        .select('*')
        .eq('patient_name', patientName)
        .eq('status', 'completed')
        .order('completed_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}