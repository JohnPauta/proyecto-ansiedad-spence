class SpenceQuestion {
  final int number;         // Número de la pregunta (1-38)
  final String text;        // Texto de la pregunta
  final String subscale;    // Subescala a la que pertenece (SAD, SoP, etc.)
  final String emoji;       // Emoji para hacerlo más amigable

  SpenceQuestion({
    required this.number,
    required this.text,
    required this.subscale,
    required this.emoji,
  });
}

// Modelo para las opciones de respuesta
class AnswerOption {
  final String label;
  final int value;    // 0=Nunca, 1=A veces, 2=Muchas veces, 3=Siempre
  final String emoji;
  final String description;

  AnswerOption({
    required this.label,
    required this.value,
    required this.emoji,
    required this.description,
  });
}