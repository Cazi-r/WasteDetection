import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/camera_service.dart';
import '../../core/constants/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CameraService _cameraService = CameraService();
  final ImagePicker _picker = ImagePicker();

  bool _isCameraInitialized = false;
  bool _isLiveMode = true; // true: Canlı Kamera, false: Galeri Modu
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _cameraService.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
    // Model yüklendiğinde burada canlı akışı başlatacağız
    // _cameraService.startImageStream(_processCameraImage);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isLiveMode = false;
      });
      // Burada seçilen resmi modele göndereceğiz
    }
  }

  void _switchToLiveMode() {
    setState(() {
      _isLiveMode = true;
      _selectedImage = null;
    });
    // Canlı akışı tekrar başlat
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atık Türü Tanıma'),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          // Katman 1: Görüntü (Kamera veya Galeri Resmi)
          Positioned.fill(
            child: _isLiveMode
                ? (_isCameraInitialized
                      ? CameraPreview(_cameraService.controller!)
                      : const Center(child: CircularProgressIndicator()))
                : (_selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : const Center(child: Text("Resim seçilmedi"))),
          ),

          // Katman 2: Sonuçlar ve Çizimler (Bounding Boxes)
          // Buraya daha sonra DetectionBox widget'ları gelecek

          // Katman 3: Alt Kontrol Paneli
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: "btn1",
                    backgroundColor: _isLiveMode ? Colors.teal : Colors.grey,
                    onPressed: _switchToLiveMode,
                    child: const Icon(Icons.camera_alt),
                  ),
                  FloatingActionButton(
                    heroTag: "btn2",
                    backgroundColor: !_isLiveMode ? Colors.teal : Colors.grey,
                    onPressed: _pickImage,
                    child: const Icon(Icons.photo_library),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
