import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({Key? key}) : super(key: key);

  final List<WasteCategory> categories = const [
    WasteCategory(
      name: 'Plastik',
      icon: Icons.local_drink,
      color: Colors.blue,
      examples: ['Pet şişeler', 'Plastik kaplar', 'Poşetler', 'Ambalajlar'],
      binColor: 'Mavi Kutu',
      tips: 'Plastikleri yıkayıp kapaksız atın. Kapakları ayrı toplayın.',
      benefits:
          'Bir ton geri dönüştürülen plastik 5774 kWh enerji tasarrufu sağlar.',
    ),
    WasteCategory(
      name: 'Kağıt',
      icon: Icons.description,
      color: Colors.brown,
      examples: ['Gazeteler', 'Kartonlar', 'Dergiler', 'Kitaplar'],
      binColor: 'Kahverengi Kutu',
      tips: 'Islak veya yağlı kağıtları atmayın. Temiz ve kuru olmalı.',
      benefits:
          'Geri dönüştürülen her 1 ton kağıt 17 ağacın kesilmesini önler.',
    ),
    WasteCategory(
      name: 'Metal',
      icon: Icons.view_in_ar,
      color: Colors.grey,
      examples: ['Konserve kutuları', 'Alüminyum folyo', 'Metal kapaklar'],
      binColor: 'Gri Kutu',
      tips: 'Metal atıkları yıkayıp temiz bir şekilde atın.',
      benefits: 'Metal %100 geri dönüştürülebilir ve özellikleri kaybolmaz.',
    ),
    WasteCategory(
      name: 'Cam',
      icon: Icons.wine_bar,
      color: Colors.green,
      examples: ['Cam şişeler', 'Cam kavanozlar'],
      binColor: 'Yeşil Kutu',
      tips: 'Camları kapaksız ve temiz atın. Kırık camlar gazeteye sarılmalı.',
      benefits: 'Cam sınırsız kez geri dönüştürülebilir.',
    ),
    WasteCategory(
      name: 'Organik',
      icon: Icons.grass,
      color: Colors.orange,
      examples: ['Sebze-meyve artıkları', 'Yumurta kabukları', 'Kahve telvesi'],
      binColor: 'Turuncu Kutu',
      tips: 'Organik atıkları evde kompost yapabilirsiniz.',
      benefits: 'Organik atıklar doğal gübre olarak kullanılabilir.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geri Dönüşüm Rehberi'),
        backgroundColor: Colors.teal,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return _buildCategoryCard(context, categories[index]);
        },
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, WasteCategory category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(category.icon, color: category.color, size: 28),
          ),
          title: Text(
            category.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            category.binColor,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    'Örnekler',
                    Icons.category,
                    category.examples.join(', '),
                    category.color,
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    'İpuçları',
                    Icons.lightbulb_outline,
                    category.tips,
                    category.color,
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    'Faydaları',
                    Icons.eco,
                    category.benefits,
                    category.color,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    String content,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class WasteCategory {
  final String name;
  final IconData icon;
  final Color color;
  final List<String> examples;
  final String binColor;
  final String tips;
  final String benefits;

  const WasteCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.examples,
    required this.binColor,
    required this.tips,
    required this.benefits,
  });
}
