class SubscaleResult {
  final String code;      // SAD, SoP, OCD, PD_AG, OAD, Phobia
  final String name;      // Nombre legible
  final int score;        // Puntaje crudo obtenido
  final int maxScore;     // Puntaje máximo posible
  final double percentage;
  final String riskLevel; // Bajo, Moderado, Alto, Muy Alto

  SubscaleResult({
    required this.code,
    required this.name,
    required this.score,
    required this.maxScore,
    required this.percentage,
    required this.riskLevel,
  });
}

class SpenceScoring {
  // Mapeo de cada subescala con sus preguntas
  static const Map<String, List<int>> subscaleQuestions = {
    'SAD': [2, 8, 22, 24, 26, 33, 38],       // Ansiedad por Separación
    'SoP': [6, 10, 15, 21, 25, 32],          // Fobia Social
    'OCD': [7, 13, 23, 36],                  // Obsesivo-Compulsivo
    'PD_AG': [14, 17, 18, 28, 31, 35, 37],   // Pánico/Agorafobia
    'OAD': [1, 3, 9, 12, 19, 29, 30],        // Ansiedad Generalizada
    'Phobia': [4, 5, 11, 16, 20, 27, 34],    // Miedos Específicos
  };

  static const Map<String, String> subscaleNames = {
    'SAD': 'Ansiedad por Separación (SAD)',
    'SoP': 'Fobia Social (SoP)',
    'OCD': 'Trastorno Obsesivo Compulsivo (OCD)',
    'PD_AG': 'Pánico y Agorafobia (PD/AG)',
    'OAD': 'Ansiedad Generalizada (OAD)',
    'Phobia': 'Miedo al Daño Físico (Phobia)',
  };

  /// Calcula los resultados por subescala a partir de las respuestas
  static List<SubscaleResult> calculate(Map<int, int> answers) {
    final results = <SubscaleResult>[];

    subscaleQuestions.forEach((code, questionNumbers) {
      int score = 0;
      for (final q in questionNumbers) {
        score += answers[q] ?? 0;
      }
      // Cada pregunta puede valer 0-3
      final maxScore = questionNumbers.length * 3;
      final percentage = (score / maxScore) * 100;

      results.add(SubscaleResult(
        code: code,
        name: subscaleNames[code] ?? code,
        score: score,
        maxScore: maxScore,
        percentage: percentage,
        riskLevel: _classifyRisk(percentage),
      ));
    });

    return results;
  }

  /// Clasifica el nivel de riesgo según el porcentaje
  static String _classifyRisk(double percentage) {
    if (percentage < 25) return 'Bajo';
    if (percentage < 50) return 'Moderado';
    if (percentage < 75) return 'Alto';
    return 'Muy Alto';
  }

  /// Calcula el puntaje total (0-114) y devuelve el riesgo general
  static Map<String, dynamic> calculateTotal(Map<int, int> answers) {
    int total = 0;
    answers.forEach((_, value) => total += value);

    final percentage = (total / 114) * 100; // 38 * 3 = 114
    return {
      'total': total,
      'percentage': percentage,
      'riskLevel': _classifyRisk(percentage),
    };
  }
}