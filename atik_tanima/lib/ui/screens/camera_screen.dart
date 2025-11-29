import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/camera_service.dart';
import '../../services/history_service.dart';
import '../../services/tflite_service.dart';
import '../../models/history_item.dart';
import '../../models/recognition.dart';
import '../widgets/bounding_box_painter.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final ImagePicker _picker = ImagePicker();
  final TfliteService _tfliteService = TfliteService();

  bool _isCameraInitialized = false;
  bool _isLiveMode = true;
  File? _selectedImage;

  // Tespit sonuçları
  List<Recognition> _recognitions = [];
  bool _isDetecting = false;

  // Ekran boyutları (oranlama için)
  double _previewWidth = 0;
  double _previewHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _startContinuousDetection();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraService.controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraService.dispose();
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    await _cameraService.initialize();
    // ML modelini yükle
    await _tfliteService.loadModel();
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
        // Kamera önizleme boyutlarını al
        if (_cameraService.controller != null &&
            _cameraService.controller!.value.isInitialized) {
          _previewWidth = _cameraService
              .controller!
              .value
              .previewSize!
              .height; // Dikey modda ters
          _previewHeight = _cameraService.controller!.value.previewSize!.width;
        }
      });
    }
  }

  // Sürekli tespit simülasyonu (ML model entegre olunca gerçek olacak)
  void _startContinuousDetection() {
    if (!_isLiveMode) return;

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isLiveMode) {
        // Mock detection - ML model buraya entegre edilecek
        _simulateDetection();
        _startContinuousDetection(); // Döngü
      }
    });
  }

  void _simulateDetection() {
    // Mock data - gerçek ML model sonuçları buraya gelecek
    final mockResults = [
      {'type': 'Plastik Şişe', 'confidence': 0.92, 'category': 'Plastik'},
      {'type': 'Kağıt Kutu', 'confidence': 0.87, 'category': 'Kağıt'},
      {'type': 'Cam Şişe', 'confidence': 0.95, 'category': 'Cam'},
      null, // Tespit yok
    ];

    final result = (mockResults..shuffle()).first;

    if (mounted) {
      setState(() {
        if (result != null) {
          _recognitions = [
            Recognition(
              id: 0,
              label: result['type'] as String,
              confidence: result['confidence'] as double,
              x: 0.2,
              y: 0.3,
              w: 0.4,
              h: 0.4, // Mock box
            ),
          ];
        } else {
          _recognitions = [];
        }
      });
    }
  }

  Future<void> _pickImage() async {
    // Kamera stream'ini durdur ve biraz bekle
    if (_isCameraInitialized) {
      await _cameraService.stopImageStream();
      await Future.delayed(
        const Duration(milliseconds: 200),
      ); // Buffer temizlenmesi için bekle
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isLiveMode = false;
      });
      // Galeri resminde de tespit yap
      _detectOnImage();
    } else {
      // Resim seçilmediyse kamerayı tekrar başlat
      if (_isCameraInitialized) {
        await _cameraService.startImageStream((image) {});
      }
    }
  }

  Future<void> _detectOnImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isDetecting = true;
      // Tespit başlarken önceki sonuçları temizle
      _recognitions = [];
    });

    try {
      // Gerçek ML model ile tespit yap
      final recognitions = await _tfliteService.runModelOnImage(
        _selectedImage!,
      );

      if (mounted) {
        // Resim boyutlarını al (oranlama için)
        final decodedImage = await decodeImageFromList(
          _selectedImage!.readAsBytesSync(),
        );

        setState(() {
          _recognitions = recognitions;
          _isDetecting = false;
          _previewWidth = decodedImage.width.toDouble();
          _previewHeight = decodedImage.height.toDouble();
        });
      }
    } catch (e) {
      print('❌ Tespit hatası: $e');
      if (mounted) {
        setState(() {
          _isDetecting = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Tespit hatası: $e')));
      }
    }
  }

  void _switchToLiveMode() {
    setState(() {
      _isLiveMode = true;
      _selectedImage = null;
      // Mod değiştiğinde tespiti sıfırla
      _recognitions = [];
    });
    // Kamera stream'ini tekrar başlat
    if (_isCameraInitialized) {
      _cameraService.startImageStream((image) {});
    }
    _startContinuousDetection();
  }

  Future<void> _saveDetection() async {
    if (_recognitions.isEmpty) return;

    // En yüksek güvenilirlikli olanı kaydet (veya hepsi için döngü yapılabilir)
    final topResult = _recognitions.first;

    final item = HistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      wasteType: topResult.label,
      imagePath: _selectedImage?.path ?? '',
      confidence: topResult.confidence,
      timestamp: DateTime.now(),
      category:
          topResult.label, // Kategori ile label aynı varsayıyoruz şimdilik
    );

    await HistoryService.addHistory(item);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tespit geçmişe kaydedildi!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    _tfliteService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Kamera görüntüsü (tam ekran)
          Positioned.fill(
            child: _isLiveMode
                ? (_isCameraInitialized
                      ? CameraPreview(_cameraService.controller!)
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ))
                : (_selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.contain)
                      : const Center(
                          child: Text(
                            "Resim seçilmedi",
                            style: TextStyle(color: Colors.white),
                          ),
                        )),
          ),

          // Bounding Box Çizimi
          if (_recognitions.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: BoundingBoxPainter(
                  recognitions: _recognitions,
                  previewSize: Size(_previewWidth, _previewHeight),
                  screenSize: MediaQuery.of(context).size,
                ),
              ),
            ),

          // Üst kısım - Tespit bilgisi kartı (Sadece en iyi sonuç için veya özet)
          if (_recognitions.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_recognitions.length} Nesne Tespit Edildi",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _saveDetection,
                        icon: const Icon(Icons.save, size: 16),
                        label: const Text('Kaydet'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Geri butonu
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Alt kısım - Mod değiştirme
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildModeButton(
                      icon: Icons.camera_alt,
                      label: 'Kamera',
                      isActive: _isLiveMode,
                      onTap: _switchToLiveMode,
                    ),
                    _buildModeButton(
                      icon: Icons.photo_library,
                      label: 'Galeri',
                      isActive: !_isLiveMode,
                      onTap: _pickImage,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Yükleniyor göstergesi
          if (_isDetecting)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Material(
          color: isActive ? Colors.teal : Colors.white24,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
