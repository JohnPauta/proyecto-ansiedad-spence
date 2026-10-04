import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/patient_service.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  Map<String, dynamic>? _patient;
  List<Map<String, dynamic>> _tests = [];
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;

      // 1. Cargar el perfil del paciente
      final patient = await PatientService.getPatient(widget.patientId);
      if (patient == null) throw Exception('Paciente no encontrado');
      setState(() => _patient = patient);

      final patientName = patient['full_name'] as String;

      // 2. Cargar tests, stats y notas en paralelo
      final results = await Future.wait([
        PatientService.getPatientTests(patientName),
        PatientService.getPatientStats(patientName),
        PatientService.getPatientNotes(patientName),
      ]);

      setState(() {
        _tests = results[0] as List<Map<String, dynamic>>;
        _stats = results[1] as Map<String, dynamic>;
        _notes = results[2] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
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

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  String _calculateAge(String? birthDate) {
    if (birthDate == null) return '?';
    try {
      final birth = DateTime.parse(birthDate);
      final now = DateTime.now();
      int age = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return '$age';
    } catch (e) {
      return '?';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Detalle del Paciente'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_patient != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edición próximamente')),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error ?? 'Error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPatientData,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final patient = _patient!;
    final name = patient['full_name'] ?? 'Sin nombre';
    final age = _calculateAge(patient['birth_date']);
    final guardian = patient['guardian_name'] ?? 'Sin tutor';
    final phone = patient['guardian_phone'] ?? 'Sin teléfono';
    final code = patient['invitation_code'] ?? '---';

    return RefreshIndicator(
      onRefresh: _loadPatientData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Encabezado del paciente ---
          _buildPatientHeader(name, age, guardian, phone, code),
          const SizedBox(height: 16),

          // --- Estadísticas rápidas ---
          if (_stats != null) _buildStatsRow(),
          const SizedBox(height: 16),

          // --- Gráfica de evolución (si hay 2+ tests) ---
          if (_tests.length >= 2) ...[
            _buildEvolutionChart(),
            const SizedBox(height: 16),
          ],

          // --- Botones de acción ---
          _buildActionButtons(name),
          const SizedBox(height: 24),

          // --- Timeline de tests ---
          _buildTestsSection(),
          const SizedBox(height: 24),

          // --- Notas clínicas ---
          if (_notes.isNotEmpty) _buildNotesSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPatientHeader(
    String name,
    String age,
    String guardian,
    String phone,
    String code,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white,
                child: Text(
                  _initials(name),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$age años',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          _buildHeaderRow(Icons.family_restroom, 'Tutor', guardian),
          const SizedBox(height: 8),
          _buildHeaderRow(Icons.phone_outlined, 'Teléfono', phone),
          const SizedBox(height: 8),
          _buildHeaderRow(Icons.qr_code, 'Código de invitación', code),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final stats = _stats!;
    final total = stats['total_tests'] ?? 0;
    final risk = stats['current_risk'] as String? ?? 'Sin datos';
    final trend = stats['trend'] as String? ?? 'sin_datos';

    final trendIcon = switch (trend) {
      'mejorando' => Icons.trending_down,
      'empeorando' => Icons.trending_up,
      'estable' => Icons.trending_flat,
      _ => Icons.remove,
    };

    final trendText = switch (trend) {
      'mejorando' => 'Mejorando',
      'empeorando' => 'Empeorando',
      'estable' => 'Estable',
      _ => 'Sin datos',
    };

    final trendColor = switch (trend) {
      'mejorando' => Colors.green,
      'empeorando' => Colors.red,
      'estable' => Colors.amber,
      _ => Colors.grey,
    };

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.assignment,
            label: 'Tests',
            value: '$total',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.warning_amber,
            label: 'Riesgo',
            value: risk,
            color: _riskColor(risk),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: trendIcon,
            label: 'Tendencia',
            value: trendText,
            color: trendColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionChart() {
    // Ordenamos de más antiguo a más reciente para la gráfica
    final sortedTests = _tests.reversed.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: Colors.deepPurple),
              const SizedBox(width: 8),
              const Text(
                'Evolución',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  final encodedName = Uri.encodeComponent(
                    _patient!['full_name'],
                  );
                  context.push('/patient-history/$encodedName');
                },
                child: const Text('Ver más'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 114,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 38,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sortedTests.length) {
                          return const SizedBox.shrink();
                        }
                        final date = DateTime.parse(
                          sortedTests[index]['completed_at'],
                        ).toLocal();
                        return Text(
                          '${date.day}/${date.month}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(sortedTests.length, (i) {
                      return FlSpot(
                        i.toDouble(),
                        (sortedTests[i]['total_score'] as num?)?.toDouble() ??
                            0,
                      );
                    }),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: Colors.deepPurple,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: _riskColor(sortedTests[index]['risk_level']),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.deepPurple.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String patientName) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              context.push('/patient-info');
            },
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Nuevo test'),
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
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.deepPurple),
            tooltip: 'Compartir código',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Compartir código de $patientName')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historial de Tests',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        if (_tests.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.assignment_outlined, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Este paciente aún no tiene tests',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ..._tests.map((test) => _buildTestTile(test)),
      ],
    );
  }

  Widget _buildTestTile(Map<String, dynamic> test) {
    final risk = test['risk_level'] as String? ?? 'Sin evaluar';
    final score = test['total_score'] ?? 0;
    final date = test['completed_at'] != null
        ? DateTime.parse(test['completed_at']).toLocal()
        : null;
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}'
        : 'Fecha desconocida';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _riskColor(risk).withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _riskColor(risk).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _riskColor(risk),
              ),
            ),
          ),
        ),
        title: Text(
          dateStr,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'Puntaje: $score/114 • Riesgo: $risk',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey,
        ),
        onTap: () {
          context.push('/test-detail/${test['id']}');
        },
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.edit_note, color: Colors.deepPurple),
            const SizedBox(width: 8),
            const Text(
              'Notas Recientes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._notes.take(5).map((note) {
          final noteDate = DateTime.parse(note['created_at']).toLocal();
          final dateStr =
              '${noteDate.day}/${noteDate.month}/${noteDate.year} - ${noteDate.hour}:${noteDate.minute.toString().padLeft(2, '0')}';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
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
                      dateStr,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  note['note_text'] ?? '',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
