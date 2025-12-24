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

/// Kamera modları
enum CameraMode {
  /// Canlı tespit - gerçek zamanlı bounding box
  live,

  /// Fotoğraf/Galeri - önce çek veya seç, sonra tespit
  photoGallery,
}

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
  CameraMode _currentMode =
      CameraMode.photoGallery; // Varsayılan: Fotoğraf modu
  File? _selectedImage;
  bool _isPickingImage = false;

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
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraService.controller;

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

    // Moda göre model yükle
    final modelType = _currentMode == CameraMode.live
        ? ModelType.float16
        : ModelType.float32;
    await _tfliteService.loadModel(type: modelType);

    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
        if (_cameraService.controller != null &&
            _cameraService.controller!.value.isInitialized) {
          _previewWidth = _cameraService.controller!.value.previewSize!.height;
          _previewHeight = _cameraService.controller!.value.previewSize!.width;

          // Canlı modda başlat
          if (_currentMode == CameraMode.live) {
            _startLiveDetection();
          }
        }
      });
    }
  }

  int _lastRunTime = 0;

  void _startLiveDetection() {
    if (_cameraService.controller == null ||
        !_cameraService.controller!.value.isInitialized ||
        _isDetecting) {
      return;
    }

    _cameraService.startImageStream((CameraImage image) async {
      if (_isDetecting || _currentMode != CameraMode.live) return;

      int currentTime = DateTime.now().millisecondsSinceEpoch;
      if (currentTime - _lastRunTime < 100) return;

      _lastRunTime = currentTime;
      _isDetecting = true;
      try {
        final recognitions = await _tfliteService.runModelOnFrame(image);
        if (mounted && _currentMode == CameraMode.live) {
          setState(() {
            _recognitions = recognitions;
          });
        }
      } catch (e) {
        print("Error processing frame: $e");
      } finally {
        _isDetecting = false;
      }
    });
  }

  /// Modu değiştir
  void _switchMode(CameraMode mode) async {
    if (_currentMode == mode) return;

    // Önceki modun temizliği
    if (_currentMode == CameraMode.live) {
      await _cameraService.stopImageStream();
    }

    setState(() {
      _currentMode = mode;
      _selectedImage = null;
      _recognitions = [];
    });

    // Moda göre model değiştir
    final modelType = mode == CameraMode.live
        ? ModelType.float16
        : ModelType.float32;
    await _tfliteService.switchModel(modelType);

    // Yeni mod başlatma
    if (mode == CameraMode.live && _isCameraInitialized) {
      _startLiveDetection();
    }
  }

  /// Fotoğraf çek
  Future<void> _takePhoto() async {
    if (!_isCameraInitialized || _cameraService.controller == null) return;

    try {
      setState(() {
        _isDetecting = true;
      });

      final XFile photo = await _cameraService.controller!.takePicture();

      setState(() {
        _selectedImage = File(photo.path);
      });

      // Fotoğraf üzerinde tespit yap
      await _detectOnImage();
    } catch (e) {
      print("Fotoğraf çekme hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fotoğraf çekme hatası: $e')));
        setState(() {
          _isDetecting = false;
        });
      }
    }
  }

  /// Galeriden resim seç
  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    _isPickingImage = true;

    try {
      if (_isCameraInitialized && _currentMode == CameraMode.live) {
        await _cameraService.stopImageStream();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        await _detectOnImage();
      }
    } finally {
      _isPickingImage = false;
    }
  }

  /// Seçili resim üzerinde tespit yap
  Future<void> _detectOnImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isDetecting = true;
      _recognitions = [];
    });

    try {
      final recognitions = await _tfliteService.runModelOnImage(
        _selectedImage!,
      );

      if (mounted) {
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

  /// Kamerayı değiştir
  Future<void> _switchCamera() async {
    setState(() {
      _isDetecting = true;
    });

    await _cameraService.switchCamera();

    if (mounted) {
      setState(() {
        if (_cameraService.controller != null &&
            _cameraService.controller!.value.isInitialized) {
          _previewWidth = _cameraService.controller!.value.previewSize!.height;
          _previewHeight = _cameraService.controller!.value.previewSize!.width;
        }
        _isDetecting = false;
      });

      if (_currentMode == CameraMode.live) {
        _startLiveDetection();
      }
    }
  }

  /// Kameraya geri dön (fotoğraf çekildikten sonra)
  void _backToCamera() {
    setState(() {
      _selectedImage = null;
      _recognitions = [];
    });
  }

  /// Tespiti kaydet
  Future<void> _saveDetection() async {
    if (_recognitions.isEmpty) return;

    final topResult = _recognitions.first;

    final item = HistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      wasteType: topResult.label,
      imagePath: _selectedImage?.path ?? '',
      confidence: topResult.confidence,
      timestamp: DateTime.now(),
      category: topResult.label,
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
          // Ana içerik
          Positioned.fill(child: _buildMainContent()),

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

          // Üst bilgi kartı
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

          // Kamera değiştirme butonu
          if (_currentMode == CameraMode.live ||
              (_currentMode == CameraMode.photoGallery &&
                  _selectedImage == null))
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                  onPressed: _switchCamera,
                ),
              ),
            ),

          // Alt kontroller
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
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

  Widget _buildMainContent() {
    // Eğer fotoğraf seçilmişse göster
    if (_selectedImage != null) {
      return Image.file(_selectedImage!, fit: BoxFit.contain);
    }

    // Kamera önizlemesi
    if (_isCameraInitialized && _cameraService.controller != null) {
      return CameraPreview(_cameraService.controller!);
    }

    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }

  Widget _buildBottomControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fotoğraf modunda ve fotoğraf seçilmemişse: çek/galeri butonları
            if (_currentMode == CameraMode.photoGallery &&
                _selectedImage == null)
              _buildPhotoModeActions(),

            // Fotoğraf seçildikten sonra: geri butonu
            if (_selectedImage != null) _buildImageSelectedActions(),

            const SizedBox(height: 16),

            // Mod seçim butonları
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildModeButton(
                  icon: Icons.camera_alt,
                  label: 'Fotoğraf',
                  isActive: _currentMode == CameraMode.photoGallery,
                  onTap: () => _switchMode(CameraMode.photoGallery),
                ),
                _buildModeButton(
                  icon: Icons.videocam,
                  label: 'Canlı',
                  isActive: _currentMode == CameraMode.live,
                  onTap: () => _switchMode(CameraMode.live),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoModeActions() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Galeri butonu
          FloatingActionButton(
            heroTag: 'gallery',
            onPressed: _pickImage,
            backgroundColor: Colors.white24,
            child: const Icon(Icons.photo_library, color: Colors.white),
          ),
          // Fotoğraf çek butonu (büyük)
          FloatingActionButton.large(
            heroTag: 'capture',
            onPressed: _takePhoto,
            backgroundColor: Colors.white,
            child: const Icon(Icons.camera, color: Colors.black, size: 36),
          ),
          // Boşluk için placeholder
          const SizedBox(width: 56),
        ],
      ),
    );
  }

  Widget _buildImageSelectedActions() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton.icon(
        onPressed: _backToCamera,
        icon: const Icon(Icons.refresh),
        label: const Text('Yeni Fotoğraf'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
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
