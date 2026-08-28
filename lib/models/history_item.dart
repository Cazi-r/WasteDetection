class HistoryItem {
  final String id;
  final String wasteType;
  final String imagePath;
  final double confidence;
  final DateTime timestamp;
  final String? category; // Kağıt, Metal, Plastik, Cam, Organik

  HistoryItem({
    required this.id,
    required this.wasteType,
    required this.imagePath,
    required this.confidence,
    required this.timestamp,
    this.category,
  });

  // JSON serialization için
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wasteType': wasteType,
      'imagePath': imagePath,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'category': category,
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'],
      wasteType: json['wasteType'],
      imagePath: json['imagePath'],
      confidence: json['confidence'],
      timestamp: DateTime.parse(json['timestamp']),
      category: json['category'],
    );
  }
}
