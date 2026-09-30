import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  List<Map<String, dynamic>> _tests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('spence_tests')
          .select('*')
          .eq('status', 'completed')
          .order('completed_at', ascending: false)
          .limit(50);
      setState(() => _tests = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _riskColor(String? risk) {
    switch (risk) {
      case 'Bajo':
        return Colors.green;
      case 'Moderado':
        return Colors.amber;
      case 'Alto':
        return Colors.orange;
      case 'Muy Alto':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _tests.length;
    final alertCount = _tests
        .where((t) =>
            t['risk_level'] == 'Alto' || t['risk_level'] == 'Muy Alto')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Panel Clínico'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTests,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // --- Tarjetas de resumen ---
                  Row(
                    children: [
                      _buildSummaryCard('Pacientes', '$total', Icons.people,
                          Colors.blue),
                      const SizedBox(width: 12),
                      _buildSummaryCard('Alertas', '$alertCount',
                          Icons.warning_amber, Colors.red),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Encabezado de la lista ---
                  const Text(
                    'Tests Recientes',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // --- Lista de tests ---
                  if (_tests.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'Aún no hay tests completados.\nCuando un paciente termine un test, aparecerá aquí.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._tests.map((test) => _buildTestCard(test)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadTests,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.refresh),
        label: const Text('Actualizar'),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                Text(title,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard(Map<String, dynamic> test) {
    final riskLevel = test['risk_level'] as String? ?? 'Sin evaluar';
    final score = test['total_score'] ?? 0;
    final date = test['completed_at'] != null
        ? DateTime.parse(test['completed_at']).toLocal()
        : null;
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}'
        : 'Fecha desconocida';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.deepPurple,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test['patient_name'] ?? 'Paciente sin nombre',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      '${test['patient_age'] ?? '?'} años • $dateStr',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _riskColor(riskLevel).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  riskLevel,
                  style: TextStyle(
                    color: _riskColor(riskLevel),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Puntuación Total',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    '$score / 114',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  // Botón de evolución (solo si hay nombre)
                  if (test['patient_name'] != null)
                    IconButton(
                      icon: const Icon(Icons.show_chart,
                          color: Colors.deepPurple),
                      tooltip: 'Ver evolución',
                      onPressed: () {
                        final name =
                            Uri.encodeComponent(test['patient_name']);
                        context.push('/patient-history/$name');
                      },
                    ),
                  // Botón de informe
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push('/test-detail/${test['id']}');
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Ver informe'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}