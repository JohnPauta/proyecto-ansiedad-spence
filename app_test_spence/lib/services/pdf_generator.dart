import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../data/spence_questions.dart';
import '../models/spence_question.dart';

class PdfGenerator {
  static Future<void> generateAndShareTestReport({
    required Map<String, dynamic> test,
    required List<Map<String, dynamic>> subscales,
    required List<Map<String, dynamic>> answers,
    required List<Map<String, dynamic>> notes,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final patientName = test['patient_name'] ?? 'Paciente sin nombre';
    final patientAge = test['patient_age'] ?? '?';
    final totalScore = test['total_score'] ?? 0;
    final riskLevel = test['risk_level'] ?? 'Sin evaluar';
    final completedAt = test['completed_at'] != null
        ? DateTime.parse(test['completed_at']).toLocal()
        : DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // --- Encabezado ---
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Informe SCAS - Test de Spence',
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Spence MentalHealth - Informe Clínico',
                    style: const pw.TextStyle(
                        fontSize: 11, color: PdfColors.grey700)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // --- Datos del paciente ---
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Paciente: $patientName',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.SizedBox(height: 4),
                pw.Text('Edad: $patientAge años'),
                pw.Text('Fecha de evaluación: ${dateFormat.format(completedAt)}'),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // --- Puntuación Global ---
          pw.Text('Puntuación Global',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Puntaje Total: $totalScore / 114',
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text('Nivel de Riesgo: $riskLevel',
                    style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: _riskColor(riskLevel))),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // --- Desglose de Subescalas ---
          pw.Text('Desglose por Subescalas',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Subescala', 'Puntaje', 'Porcentaje', 'Riesgo'],
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
            },
            data: subscales.map((s) {
              return [
                _subscaleFullName(s['subscale_code']),
                '${s['score']}',
                '${(s['percentile'] as num?)?.toStringAsFixed(1) ?? '0'}%',
                s['risk_level'] ?? '-',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),

          // --- Respuestas Detalladas ---
          pw.Text('Respuestas Detalladas',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          ...answers.map((answer) {
            final qNum = answer['question_number'] as int;
            final score = answer['score'] as int;
            final question = spenceQuestions.firstWhere(
              (q) => q.number == qNum,
              orElse: () => SpenceQuestion(
                number: qNum,
                text: 'Pregunta $qNum',
                subscale: 'N/A',
                emoji: '',
              ),
            );
            const labels = ['Nunca', 'A veces', 'Muchas veces', 'Siempre'];

            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 24,
                    child: pw.Text('$qNum.',
                        style: const pw.TextStyle(fontSize: 10)),
                  ),
                  pw.Expanded(
                    child: pw.Text(question.text,
                        style: const pw.TextStyle(fontSize: 10)),
                  ),
                  pw.SizedBox(
                    width: 80,
                    child: pw.Text(
                      labels[score.clamp(0, 3)],
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
          pw.SizedBox(height: 20),

          // --- Notas de Evolución ---
          if (notes.isNotEmpty) ...[
            pw.Text('Notas de Evolución',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            ...notes.map((note) {
              final noteDate = DateTime.parse(note['created_at']).toLocal();
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(dateFormat.format(noteDate),
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey700)),
                      pw.SizedBox(height: 4),
                      pw.Text(note['note_text'] ?? '',
                          style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              );
            }),
          ],

          pw.SizedBox(height: 24),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'Este informe es confidencial y está destinado únicamente a uso clínico. '
            'Generado por Spence MentalHealth.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    // Mostrar diálogo de compartir/guardar
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Informe_SCAS_${patientName.replaceAll(' ', '_')}.pdf',
    );
  }

  static PdfColor _riskColor(String risk) {
    switch (risk) {
      case 'Bajo': return PdfColors.green700;
      case 'Moderado': return PdfColors.amber700;
      case 'Alto': return PdfColors.orange700;
      case 'Muy Alto': return PdfColors.red700;
      default: return PdfColors.grey700;
    }
  }

  static String _subscaleFullName(String? code) {
    const names = {
      'SAD': 'Ansiedad por Separación',
      'SoP': 'Fobia Social',
      'OCD': 'Obsesivo Compulsivo',
      'PD_AG': 'Pánico y Agorafobia',
      'OAD': 'Ansiedad Generalizada',
      'Phobia': 'Miedo al Daño Físico',
    };
    return names[code] ?? code ?? '';
  }
}