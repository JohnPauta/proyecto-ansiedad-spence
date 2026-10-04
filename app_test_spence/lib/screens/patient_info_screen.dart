import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/patient_service.dart';

class PatientInfoScreen extends StatefulWidget {
  const PatientInfoScreen({super.key});

  @override
  State<PatientInfoScreen> createState() => _PatientInfoScreenState();
}

class _PatientInfoScreenState extends State<PatientInfoScreen> {
  final _codeController = TextEditingController();
  bool _isValidating = false;
  String? _errorMessage;
  Map<String, dynamic>? _patientData;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validateCode() async {
    final code = _codeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() => _errorMessage = 'Por favor, escribe tu código 💜');
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final patient = await PatientService.validateInvitationCode(code);

      if (patient == null) {
        setState(() {
          _errorMessage = 'Código no encontrado. Verifica con tu médico 🩺';
          _isValidating = false;
        });
        return;
      }

      setState(() {
        _patientData = patient;
        _isValidating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al validar: $e';
        _isValidating = false;
      });
    }
  }

  void _startTest() {
    if (_patientData == null) return;

    final name = _patientData!['full_name'] as String;
    final birthDate = _patientData!['birth_date'] as String?;
    final doctorId = _patientData!['created_by'] as String?;
    final patientId = _patientData!['id'] as String;

    int age = 10;
    if (birthDate != null) {
      final birth = DateTime.parse(birthDate);
      final now = DateTime.now();
      age = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
    }

    context.push(
      '/test?name=${Uri.encodeComponent(name)}'
      '&age=$age'
      '&patientId=$patientId'
      '&doctorId=${doctorId ?? ''}'
      '&code=${_codeController.text.trim().toUpperCase()}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🐰', style: TextStyle(fontSize: 60)),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '¡Hola! Soy Lunny',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Escribe el código que te dio tu médico para empezar 💜',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.deepPurple,
                ),
                enabled: _patientData == null,
                decoration: InputDecoration(
                  labelText: 'Código de invitación',
                  hintText: 'Ej: MG-4821',
                  prefixIcon: const Icon(
                    Icons.qr_code,
                    color: Colors.deepPurple,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onSubmitted: (_) => _validateCode(),
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              if (_patientData == null)
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isValidating ? null : _validateCode,
                    icon: _isValidating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      _isValidating ? 'Validando...' : 'Validar código',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

              if (_patientData != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '¡Código válido!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _patientData!['full_name'] ?? 'Paciente',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _startTest,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      'Comenzar el cuestionario',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
