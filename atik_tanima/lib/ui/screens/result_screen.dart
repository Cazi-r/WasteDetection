import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/history_service.dart';
import '../../models/history_item.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Arguments'leri al
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final imagePath = args?['imagePath'] as String? ?? '';
    final wasteType = args?['wasteType'] as String? ?? 'Bilinmeyen';
    final confidence = args?['confidence'] as double? ?? 0.0;
    final category = args?['category'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarama Sonucu'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Resim
            if (imagePath.isNotEmpty)
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(color: Colors.grey.shade200),
                child: Image.file(File(imagePath), fit: BoxFit.contain),
              ),

            // Sonuç kartı
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tespit edilen tür
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tespit Edilen Atık',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      wasteType,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            'Kategori',
                            category,
                            _getCategoryColor(category),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Güven Skoru',
                            '${(confidence * 100).toStringAsFixed(1)}%',
                            Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Geri dönüşüm bilgisi
                  Card(
                    elevation: 2,
                    color: _getCategoryColor(category).withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.recycling,
                                color: _getCategoryColor(category),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Geri Dönüşüm Bilgisi',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _getRecyclingInfo(category),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Aksiyon butonları
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            // Geçmişe kaydet
                            final item = HistoryItem(
                              id: DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              wasteType: wasteType,
                              imagePath: imagePath,
                              confidence: confidence,
                              timestamp: DateTime.now(),
                              category: category,
                            );
                            await HistoryService.addHistory(item);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Geçmişe kaydedildi!'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Kaydet'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Yeni Tarama',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'plastik':
        return Colors.blue;
      case 'kağıt':
      case 'kagit':
        return Colors.brown;
      case 'metal':
        return Colors.grey;
      case 'cam':
        return Colors.green;
      case 'organik':
        return Colors.orange;
      default:
        return Colors.teal;
    }
  }

  String _getRecyclingInfo(String category) {
    switch (category.toLowerCase()) {
      case 'plastik':
        return 'Bu atık PLASTİK geri dönüşüm kutusuna atılmalıdır. Plastik atıklar geri dönüştürülerek yeni ürünlere dönüştürülebilir.';
      case 'kağıt':
      case 'kagit':
        return 'Bu atık KAĞIT geri dönüşüm kutusuna atılmalıdır. Kağıt atıkların geri dönüşümü ile ağaçlar korunur.';
      case 'metal':
        return 'Bu atık METAL geri dönüşüm kutusuna atılmalıdır. Metal atıklar %100 geri dönüştürülebilir.';
      case 'cam':
        return 'Bu atık CAM geri dönüşüm kutusuna atılmalıdır. Cam sınırsız kez geri dönüştürülebilir.';
      case 'organik':
        return 'Bu atık ORGANİK atık kutusuna atılmalıdır. Organik atıklar kompost yapılabilir.';
      default:
        return 'Lütfen bu atığı uygun geri dönüşüm kutusuna atın.';
    }
  }
}
