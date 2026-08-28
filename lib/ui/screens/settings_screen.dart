import 'package:flutter/material.dart';
import '../../services/preferences_service.dart';
import '../../services/history_service.dart';
import '../../core/routes/app_routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        children: [
          _buildSection('Genel'),
          _buildTile(
            icon: Icons.play_circle_outline,
            title: 'Tanıtımı Tekrar Göster',
            subtitle: 'Onboarding ekranlarını tekrar görüntüle',
            onTap: () async {
              await PreferencesService.resetOnboarding();
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Uygulamayı yeniden başlattığınızda tanıtım gösterilecek',
                  ),
                ),
              );
            },
          ),
          _buildTile(
            icon: Icons.delete_outline,
            title: 'Geçmişi Temizle',
            subtitle: 'Tüm tarama geçmişini sil',
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Geçmişi Temizle'),
                  content: const Text(
                    'Tüm tarama geçmişini silmek istediğinizden emin misiniz?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Sil'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await HistoryService.clearHistory();
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Geçmiş temizlendi')),
                );
              }
            },
          ),

          const Divider(height: 32),

          _buildSection('Hakkında'),
          _buildTile(
            icon: Icons.info_outline,
            title: 'Versiyon',
            subtitle: '1.0.0',
            trailing: const SizedBox.shrink(),
          ),
          _buildTile(
            icon: Icons.code,
            title: 'Geliştirici',
            subtitle: 'Flutter & TensorFlow Lite',
            trailing: const SizedBox.shrink(),
          ),
          _buildTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Gizlilik Politikası',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yakında eklenecek')),
              );
            },
          ),

          const SizedBox(height: 32),

          // Logo ve açıklama
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.recycling, size: 64, color: Colors.teal.shade300),
                const SizedBox(height: 12),
                Text(
                  'Atık Tanıma',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Yapay zeka destekli atık sınıflandırma uygulaması',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
