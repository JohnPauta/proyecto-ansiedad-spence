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
    final number = random.nextInt(9000) + 1000;
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
    String patientName,
  ) async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('spence_tests')
        .select('*')
        .eq('patient_name', patientName)
        .eq('status', 'completed')
        .order('completed_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Obtiene estadísticas del paciente (total tests, riesgo actual, tendencia)
  static Future<Map<String, dynamic>> getPatientStats(
    String patientName,
  ) async {
    final supabase = Supabase.instance.client;

    final tests = await supabase
        .from('spence_tests')
        .select('*')
        .eq('patient_name', patientName)
        .eq('status', 'completed')
        .order('completed_at', ascending: false);

    if (tests.isEmpty) {
      return {
        'total_tests': 0,
        'last_test_date': null,
        'current_risk': null,
        'trend': 'sin_datos',
        'avg_score': 0.0,
      };
    }

    final firstScore = (tests.last['total_score'] as num?)?.toDouble() ?? 0.0;
    final lastScore = (tests.first['total_score'] as num?)?.toDouble() ?? 0.0;
    final diff = lastScore - firstScore;

    String trend;
    if (tests.length < 2) {
      trend = 'sin_datos';
    } else if (diff < -5) {
      trend = 'mejorando';
    } else if (diff > 5) {
      trend = 'empeorando';
    } else {
      trend = 'estable';
    }

    double avgScore = 0.0;
    for (final t in tests) {
      avgScore += (t['total_score'] as num?)?.toDouble() ?? 0.0;
    }
    avgScore = avgScore / tests.length;

    return {
      'total_tests': tests.length,
      'last_test_date': tests.first['completed_at'],
      'current_risk': tests.first['risk_level'],
      'trend': trend,
      'avg_score': avgScore,
    };
  }

  /// Obtiene las notas clínicas de todos los tests del paciente
  static Future<List<Map<String, dynamic>>> getPatientNotes(
    String patientName,
  ) async {
    final supabase = Supabase.instance.client;

    // Primero obtenemos los IDs de los tests del paciente
    final tests = await supabase
        .from('spence_tests')
        .select('id')
        .eq('patient_name', patientName);

    if (tests.isEmpty) return [];

    final testIds = tests.map((t) => t['id']).toList();

    final notes = await supabase
        .from('clinical_notes')
        .select('*')
        .inFilter('test_id', testIds)
        .order('created_at', ascending: false)
        .limit(20);

    return List<Map<String, dynamic>>.from(notes);
  }

  /// Valida un código de invitación y devuelve el paciente asociado
  static Future<Map<String, dynamic>?> validateInvitationCode(
    String code,
  ) async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('profiles')
        .select('id, full_name, birth_date, guardian_name, created_by')
        .eq('invitation_code', code.toUpperCase().trim())
        .eq('role', 'patient')
        .maybeSingle();

    return response;
  }
}
