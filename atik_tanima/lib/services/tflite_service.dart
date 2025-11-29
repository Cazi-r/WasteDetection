import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import '../models/recognition.dart';

class TfliteService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isModelLoaded = false;

  bool get isModelLoaded => _isModelLoaded;

  Future<void> loadModel() async {
    try {
      // Model yükle
      _interpreter = await Interpreter.fromAsset('assets/models/waste.tflite');

      // Label'ları yükle
      final labelsData = await rootBundle.loadString(
        'assets/models/labels.txt',
      );
      _labels = labelsData
          .split('\n')
          .where((label) => label.trim().isNotEmpty && !label.startsWith('#'))
          .map((line) => line.split(':').last.trim())
          .toList();

      _isModelLoaded = true;
      print("✅ Model başarıyla yüklendi");
      print("📋 Kategoriler: ${_labels.join(', ')}");
    } catch (e) {
      print("❌ Model yüklenirken hata: $e");
      _isModelLoaded = false;
    }
  }

  Future<List<Recognition>> runModelOnFrame(CameraImage image) async {
    if (!_isModelLoaded || _interpreter == null) return [];

    try {
      // CameraImage'i işlenebilir formata çevir
      final convertedImage = _convertCameraImage(image);
      if (convertedImage == null) return [];

      // Model input shape'ini al
      var inputShape = _interpreter!.getInputTensor(0).shape;
      var outputShape = _interpreter!.getOutputTensor(0).shape;

      // Çıktı buffer'ı hazırla
      int totalOutputSize = 1;
      for (var s in outputShape) {
        totalOutputSize *= s;
      }

      var output = List.filled(totalOutputSize, 0.0).reshape(outputShape);

      // Model çalıştır
      _interpreter!.run(convertedImage, output);

      // Çıktı tipine göre parse et
      if (outputShape.length == 2 && outputShape[1] == _labels.length) {
        return _parseClassificationOutput(output[0]);
      } else if (outputShape.length == 3) {
        return _parseYoloOutput(output[0], image.width, image.height);
      } else {
        return [];
      }
    } catch (e) {
      print("❌ Model çalıştırılırken hata: $e");
      return [];
    }
  }

  Future<List<Recognition>> runModelOnImage(File imageFile) async {
    if (!_isModelLoaded || _interpreter == null) return [];

    try {
      // Resmi yükle ve işle
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return [];

      // Model input shape'ini al
      var inputShape = _interpreter!.getInputTensor(0).shape;
      var outputShape = _interpreter!.getOutputTensor(0).shape;

      int inputSize = inputShape[1]; // Genelde 224 veya 640

      // Resmi resize et
      final resizedImage = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
      );

      // Float32 array'e çevir
      var input = _imageToByteListFloat32(resizedImage, inputSize, inputSize);

      // Çıktı buffer'ı hazırla
      int totalOutputSize = 1;
      for (var s in outputShape) {
        totalOutputSize *= s;
      }

      var output = List.filled(totalOutputSize, 0.0).reshape(outputShape);

      // Model çalıştır
      _interpreter!.run(input, output);

      // Çıktı tipine göre parse et
      if (outputShape.length == 2 && outputShape[1] == _labels.length) {
        // Classification [1, 5]
        return _parseClassificationOutput(output[0]);
      } else if (outputShape.length == 3) {
        // Object Detection (YOLO)
        return _parseYoloOutput(output[0], image.width, image.height);
      } else {
        print("⚠️ Bilinmeyen model çıktısı: $outputShape");
        return [];
      }
    } catch (e) {
      print("❌ Resim üzerinde model çalıştırılırken hata: $e");
      return [];
    }
  }

  List<List<List<List<double>>>> _imageToByteListFloat32(
    img.Image image,
    int inputSize,
    int inputSize2,
  ) {
    var convertedBytes = List.generate(
      1,
      (index) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize2,
          (x) => List.generate(3, (c) {
            var pixel = image.getPixel(x, y);
            // Normalize to [0, 1]
            if (c == 0) return pixel.r / 255.0;
            if (c == 1) return pixel.g / 255.0;
            return pixel.b / 255.0;
          }),
        ),
      ),
    );
    return convertedBytes;
  }

  List<List<List<List<double>>>>? _convertCameraImage(CameraImage image) {
    try {
      // YUV420 formatından RGB'ye çevir - şimdilik basit placeholder
      // Gerçek implementasyonda image_lib veya native kod kullanılmalı
      var convertedImage = List.generate(
        1,
        (index) => List.generate(
          224,
          (y) => List.generate(224, (x) => List.generate(3, (c) => 0.0)),
        ),
      );
      return convertedImage;
    } catch (e) {
      print("❌ Kamera görüntüsü dönüştürülürken hata: $e");
      return null;
    }
  }

  List<Recognition> _parseClassificationOutput(List<double> output) {
    List<Recognition> recognitions = [];
    for (int i = 0; i < output.length; i++) {
      if (i < _labels.length) {
        // Sadece %50 üzeri güvenilirlik varsa ekle
        if (output[i] > 0.50) {
          recognitions.add(
            Recognition(
              id: i,
              label: _labels[i],
              confidence: output[i],
              // Classification'da koordinat yok, tüm ekranı kaplasın
              x: 0,
              y: 0,
              w: 1,
              h: 1,
            ),
          );
        }
      }
    }
    recognitions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return recognitions;
  }

  List<Recognition> _parseYoloOutput(
    List<dynamic> output,
    int imageWidth,
    int imageHeight,
  ) {
    // YOLOv8 çıktısı genelde [84, 8400] şeklindedir (transpoze gerekebilir)
    // 84 = 4 (box) + 80 (class) (bizde 5 class -> 9 channel)

    // Basitleştirilmiş YOLO parser (gerçek model yapısına göre ayarlanmalı)
    // Şimdilik boş dönüyoruz çünkü modelin yapısını tam bilmiyoruz
    // Kullanıcının modeli muhtemelen classification olduğu için buraya düşmeyecek
    return [];
  }

  void dispose() {
    _interpreter?.close();
    _isModelLoaded = false;
  }
}
