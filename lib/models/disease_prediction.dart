class DiseasePrediction {
  final String rawPrediction;
  final double? confidence;
  final int? classId;
  final bool success;
  final String? error;

  DiseasePrediction({
    required this.rawPrediction,
    this.confidence,
    this.classId,
    required this.success,
    this.error,
  });

  factory DiseasePrediction.fromJson(Map<String, dynamic> json) {
    double? parsedConfidence;
    if (json['confidence'] != null) {
      if (json['confidence'] is num) {
        parsedConfidence = (json['confidence'] as num).toDouble();
      } else if (json['confidence'] is String) {
        parsedConfidence = double.tryParse(json['confidence']);
      }
    }

    int? parsedClassId;
    if (json['class_id'] != null && json['class_id'] is num) {
      parsedClassId = (json['class_id'] as num).toInt();
    }

    return DiseasePrediction(
      rawPrediction: json['prediction']?.toString() ?? '',
      confidence: parsedConfidence,
      classId: parsedClassId,
      success: json['success'] == true,
      error: json['error']?.toString(),
    );
  }

  /// Maps model outputs to human-friendly disease names.
  String get displayName {
    final normalized = rawPrediction
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    switch (normalized) {
      case 'bacterial_leaf_blight':
        return 'Bacterial Leaf Blight';
      case 'bacterial_leaf_streak':
        return 'Bacterial Leaf Streak';
      case 'bacterial_panicle_blight':
        return 'Bacterial Panicle Blight';
      case 'blast':
        return 'Blast';
      case 'brown_spot':
        return 'Brown Spot';
      case 'dead_heart':
        return 'Dead Heart';
      case 'downy_mildew':
        return 'Downy Mildew';
      case 'hispa':
        return 'Hispa';
      case 'normal':
      case 'healthy':
      case 'normal_healthy':
        return 'Normal / Healthy';
      case 'tungro':
        return 'Tungro';
      default:
        if (rawPrediction.trim().isEmpty) return 'Unknown Disease';
        // Fallback title-casing for unexpected outputs
        return rawPrediction
            .replaceAll('_', ' ')
            .split(' ')
            .where((word) => word.isNotEmpty)
            .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join(' ');
    }
  }

  /// Returns confidence formatted as a percentage (e.g. "98.5%"),
  /// or null if confidence was not returned by the API.
  String? get formattedConfidence {
    if (confidence == null) return null;
    final val = confidence!;
    final percentage = val <= 1.0 ? val * 100.0 : val;
    return '${percentage.toStringAsFixed(1)}%';
  }
}
