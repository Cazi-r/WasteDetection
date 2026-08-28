class Recognition {
  final int id;
  final String label;
  final double confidence;
  final double? x;
  final double? y;
  final double? w;
  final double? h;

  Recognition({
    required this.id,
    required this.label,
    required this.confidence,
    this.x,
    this.y,
    this.w,
    this.h,
  });

  factory Recognition.fromJson(Map<dynamic, dynamic> json) {
    return Recognition(
      id: json['id'] ?? 0,
      label: json['detectedClass'] ?? 'unknown',
      confidence: json['confidenceInClass'] ?? 0.0,
      x: json['rect']?['x'],
      y: json['rect']?['y'],
      w: json['rect']?['w'],
      h: json['rect']?['h'],
    );
  }
}
