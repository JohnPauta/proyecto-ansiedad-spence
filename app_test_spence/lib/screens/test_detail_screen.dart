import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/spence_question.dart';
import '../data/spence_questions.dart';
import '../services/pdf_generator.dart';

class TestDetailScreen extends StatefulWidget {
  final String testId;
  const TestDetailScreen({super.key, required this.testId});

  @override
  State<TestDetailScreen> createState() => _TestDetailScreenState();
}

class _TestDetailScreenState extends State<TestDetailScreen> {
  Map<String, dynamic>? _test;
  List<Map<String, dynamic>> _subscales = [];
  List<Map<String, dynamic>> _answers = [];
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;
  String? _error;

  final _noteController = TextEditingController();
  bool _isSavingNote = false;

  @override
  void initState() {
    super.initState();
    _loadTestDetail();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadTestDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;

      // 1. Cargar el test
      final testResponse = await supabase
          .from('spence_tests')
          .select('*')
          .eq('id', widget.testId)
          .maybeSingle();

      if (testResponse == null) throw Exception('Test no encontrado');
      setState(() => _test = testResponse);

      // 2. Cargar subescalas
      final subscalesResponse = await supabase
          .from('spence_subscales')
          .select('*')
          .eq('test_id', widget.testId)
          .order('subscale_code');
      setState(
        () => _subscales = List<Map<String, dynamic>>.from(subscalesResponse),
      );

      // 3. Cargar notas
      final notesResponse = await supabase
          .from('clinical_notes')
          .select('*')
          .eq('test_id', widget.testId)
          .order('created_at', ascending: false);
      setState(() => _notes = List<Map<String, dynamic>>.from(notesResponse));

      // 4. Cargar respuestas del test
      final answersResponse = await supabase
          .from('spence_answers')
          .select('*')
          .eq('test_id', widget.testId)
          .order('question_number', ascending: true);
      setState(
        () => _answers = List<Map<String, dynamic>>.from(answersResponse),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe algo antes de guardar 📝')),
      );
      return;
    }

    setState(() => _isSavingNote = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      await supabase.from('clinical_notes').insert({
        'test_id': widget.testId,
        'patient_id': _test?['patient_id'],
        'doctor_id': userId,
        'note_text': text,
      });

      _noteController.clear();

      final notesResponse = await supabase
          .from('clinical_notes')
          .select('*')
          .eq('test_id', widget.testId)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() => _notes = List<Map<String, dynamic>>.from(notesResponse));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Nota guardada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      if (mounted) setState(() => _isSavingNote = false);
    }
  }

  Color _riskColor(String? risk) {
    switch (risk) {
      case 'Bajo':
        return Colors.green;
      case 'Moderado':
        return Colors.amber.shade700;
      case 'Alto':
        return Colors.orange;
      case 'Muy Alto':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _subscaleFullName(String code) {
    const names = {
      'SAD': '1. Ansiedad por Separación (SAD)',
      'SoP': '2. Fobia Social (SoP)',
      'OCD': '3. Trastorno Obsesivo Compulsivo (OCD)',
      'PD_AG': '4. Pánico y Agorafobia (PD/AG)',
      'OAD': '5. Ansiedad Generalizada (OAD)',
      'Phobia': '6. Miedo al Daño Físico (Phobia)',
    };
    return names[code] ?? code;
  }

  String _subscaleObservation(String code) {
    const observations = {
      'SAD': 'Temores persistentes al alejamiento de figuras parentales; somatización matutina antes del colegio.',
      'SoP': 'Inhibición extrema ante pares y exposiciones en clase; miedo agudo al escrutinio o ridículo.',
      'OCD': 'Puntuación dentro de la norma esperada; sin reportes de rituales o rumiación intrusiva de significancia clínica.',
      'PD_AG': 'Síntomas aislados de taquicardia situacional en recintos concurridos; monitoreo recomendado.',
      'OAD': 'Preocupaciones desproporcionadas sobre el rendimiento y eventos cotidianos; tensión neuromuscular recurrente.',
      'Phobia': 'Reactividad normal a estímulos físicos convencionales (oscuridad, insectos o alturas).',
    };
    return observations[code] ?? '';
  }

  int _maxForSubscale(String code) {
    const maxScores = {
      'SAD': 21,
      'SoP': 18,
      'OCD': 12,
      'PD_AG': 21,
      'OAD': 21,
      'Phobia': 21,
    };
    return maxScores[code] ?? 21;
  }

  String _monthName(int month) {
    const months = [
      '',
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _test == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Informe SCAS')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${_error ?? "Test no encontrado"}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final test = _test!;
    final riskLevel = test['risk_level'] as String? ?? 'Sin evaluar';
    final totalScore = test['total_score'] ?? 0;
    final percentile = (test['total_percentile'] as num?)?.toDouble() ?? 0;
    final patientName = test['patient_name'] ?? 'Paciente sin nombre';
    final patientAge = test['patient_age'] ?? '?';
    final date = test['completed_at'] != null
        ? DateTime.parse(test['completed_at']).toLocal()
        : null;
    final dateStr = date != null
        ? '${date.day} ${_monthName(date.month)} ${date.year}, ${date.hour}:${date.minute.toString().padLeft(2, '0')} hrs'
        : 'Fecha desconocida';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Informe SCAS'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: () async {
              try {
                await PdfGenerator.generateAndShareTestReport(
                  test: test,
                  subscales: _subscales,
                  answers: _answers,
                  notes: _notes,
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al generar PDF: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Encabezado del paciente ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.deepPurple.shade100,
                  child: Text(
                    _initials(patientName),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$patientAge años',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Evaluado el $dateStr',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Puntuación Global ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Puntuación Global Total',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'SCAS Core',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$totalScore',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const Text(
                      ' / 114 puntos',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: totalScore / 114,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(_riskColor(riskLevel)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStat(
                        'Percentil',
                        '${percentile.toStringAsFixed(0)}%',
                        Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMiniStat(
                        'Riesgo',
                        riskLevel,
                        Icons.warning_amber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Alerta de riesgo ---
          if (riskLevel == 'Alto' || riskLevel == 'Muy Alto')
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'ALERTA DE RIESGO PSICOMÉTRICO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Se recomienda intervención terapéutica. El perfil psicométrico global supera el umbral clínico.',
                    style: TextStyle(fontSize: 13, color: Colors.red.shade900),
                  ),
                ],
              ),
            ),

          // --- Desglose de Subescalas ---
          const Text(
            'Desglose Oficial de Subescalas (SCAS)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Análisis dimensional por dominios específicos de sintomatología ansiosa.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          ..._subscales.map((sub) {
            final code = sub['subscale_code'] as String;
            final score = sub['score'] ?? 0;
            final maxScore = _maxForSubscale(code);
            final subRisk = sub['risk_level'] as String? ?? 'Bajo';
            final subPercentile = (sub['percentile'] as num?)?.toDouble() ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _subscaleFullName(code),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _riskColor(subRisk).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          subRisk,
                          style: TextStyle(
                            color: _riskColor(subRisk),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _riskColor(subRisk),
                        ),
                      ),
                      Text(
                        ' / $maxScore',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${subPercentile.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _riskColor(subRisk),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: maxScore > 0 ? score / maxScore : 0,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(_riskColor(subRisk)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _subscaleObservation(code),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          // --- Respuestas Detalladas ---
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 8),
                  title: Row(
                    children: [
                      const Icon(Icons.list_alt, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Text(
                        'Respuestas Detalladas (${_answers.length}/38)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  children: [
                    const SizedBox(height: 8),
                    ..._answers.map((answer) {
                      final qNum = answer['question_number'] as int;
                      final score = (answer['score'] as num?)?.toInt() ?? 0;
                      final question = spenceQuestions.firstWhere(
                        (q) => q.number == qNum,
                        orElse: () => SpenceQuestion(
                          number: qNum,
                          text: 'Pregunta $qNum',
                          subscale: 'N/A',
                          emoji: '❓',
                        ),
                      );

                      const labels = [
                        'Nunca',
                        'A veces',
                        'Muchas veces',
                        'Siempre',
                      ];
                      const colors = [
                        Colors.green,
                        Colors.amber,
                        Colors.orange,
                        Colors.red,
                      ];
                      final color = colors[score.clamp(0, 3)];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  question.emoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '$qNum. ${question.text}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    labels[score.clamp(0, 3)],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '($score pts) • ${question.subscale}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          // --- Notas de Evolución ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.edit_note, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text(
                      'Notas de Evolución Terapéutica',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Escribe aquí tus observaciones clínicas...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSavingNote ? null : _saveNote,
                    icon: _isSavingNote
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _isSavingNote ? 'Guardando...' : 'Guardar Nota',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (_notes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Notas anteriores',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._notes.map((note) {
                    final noteDate = note['created_at'] != null
                        ? DateTime.parse(note['created_at']).toLocal()
                        : null;
                    final noteDateStr = noteDate != null
                        ? '${noteDate.day}/${noteDate.month}/${noteDate.year} - ${noteDate.hour}:${noteDate.minute.toString().padLeft(2, '0')}'
                        : '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.deepPurple.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                noteDateStr,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            note['note_text'] ?? '',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.deepPurple),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
