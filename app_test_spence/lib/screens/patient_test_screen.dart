import '../services/spence_scoring.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../data/spence_questions.dart';
import '../models/spence_question.dart';

class PatientTestScreen extends StatefulWidget {
  final String patientName;
  final int patientAge;
  final String? patientId;
  final String? doctorId;
  final String? invitationCode;

  const PatientTestScreen({
    super.key,
    required this.patientName,
    required this.patientAge,
    this.patientId,
    this.doctorId,
    this.invitationCode,
  });

  @override
  State<PatientTestScreen> createState() => _PatientTestScreenState();
}

class _PatientTestScreenState extends State<PatientTestScreen> {
  int _currentIndex = 0;
  final Map<int, int> _answers = {}; // {número_pregunta: valor}
  bool _isSaving = false;

  SpenceQuestion get _currentQuestion => spenceQuestions[_currentIndex];
  double get _progress => (_currentIndex + 1) / spenceQuestions.length;

  void _selectAnswer(int value) {
    setState(() {
      _answers[_currentQuestion.number] = value;
    });
  }

  void _nextQuestion() {
    if (_answers[_currentQuestion.number] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, elige una respuesta 💜')),
      );
      return;
    }

    if (_currentIndex < spenceQuestions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _finishTest();
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  Future<void> _finishTest() async {
    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      // Calcular resultados
      final total = SpenceScoring.calculateTotal(_answers);
      final subscaleResults = SpenceScoring.calculate(_answers);

      // Crear el test con el nombre y edad del paciente
      final testResponse = await supabase
          .from('spence_tests')
          .insert({
            'patient_id': widget.patientId,
            'patient_name': widget.patientName,
            'patient_age': widget.patientAge,
            'doctor_id': widget.doctorId,
            'invitation_code_used': widget.invitationCode,
            'status': 'completed',
            'completed_at': DateTime.now().toUtc().toIso8601String(),
            'total_score': total['total'],
            'total_t_score': null,
            'total_percentile': total['percentage'],
            'risk_level': total['riskLevel'],
          })
          .select()
          .single();

      final testId = testResponse['id'];

      // Guardar las respuestas
      final answerRecords = _answers.entries.map((entry) {
        return {
          'test_id': testId,
          'question_number': entry.key,
          'score': entry.value,
        };
      }).toList();
      await supabase.from('spence_answers').insert(answerRecords);

      // Guardar subescalas
      final subscaleRecords = subscaleResults.map((r) {
        return {
          'test_id': testId,
          'subscale_code': r.code,
          'score': r.score,
          't_score': null,
          'percentile': r.percentage,
          'risk_level': r.riskLevel,
        };
      }).toList();
      await supabase.from('spence_subscales').insert(subscaleRecords);

      if (mounted) _showCompletionDialog(total['riskLevel'] as String);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showCompletionDialog(String riskLevel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¡Genial! 🎉', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😊', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'Has terminado el cuestionario. Tu médico podrá revisar tus respuestas y ayudarte mejor.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Volver al inicio'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // --- Encabezado con barra de progreso ---
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.pause_circle_outline),
                    onPressed: () => context.go('/'),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 10,
                        backgroundColor: Colors.deepPurple.shade100,
                        valueColor: const AlwaysStoppedAnimation(
                          Colors.deepPurple,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_currentIndex + 1}/${spenceQuestions.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- Indicador de pregunta ---
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pregunta ${_currentIndex + 1} de ${spenceQuestions.length}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),

              // --- Mascota / Indicador ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Text(
                      _currentQuestion.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '¡Lo estás haciendo genial! Sigue así, este es tu espacio seguro. 💜',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Pregunta principal ---
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentQuestion.text,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No hay respuestas correctas ni incorrectas: solo lo que sientes en tu corazón.',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 24),

                      // --- Opciones de respuesta ---
                      ...answerOptions.map((option) {
                        final isSelected =
                            _answers[_currentQuestion.number] == option.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _selectAnswer(option.value),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.deepPurple.shade50
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.deepPurple
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    option.emoji,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option.label,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          option.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.deepPurple,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // --- Botones de navegación ---
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_currentIndex > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _previousQuestion,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Anterior'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  if (_currentIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _nextQuestion,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _currentIndex == spenceQuestions.length - 1
                                  ? Icons.check
                                  : Icons.arrow_forward,
                            ),
                      label: Text(
                        _currentIndex == spenceQuestions.length - 1
                            ? 'Terminar'
                            : 'Siguiente',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
