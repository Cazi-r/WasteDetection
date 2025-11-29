import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;
import '../models/recognition.dart';

class TfliteService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isModelLoaded = false;

  bool get isModelLoaded => _isModelLoaded;

  Future<void> loadModel() async {
    try {
      // Model yükle
      _interpreter = await Interpreter.fromAsset(
        'assets/models/best_float32.tflite',
      );

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
      final int width = image.width;
      final int height = image.height;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel!;

      // Basit YUV -> RGB dönüşümü ve Resize (224x224 veya 640x640)
      // Performans için sadece merkezi alıp küçülteceğiz (basitleştirilmiş)
      // Gerçek uygulamada image_lib veya native kod daha hızlıdır.

      int inputSize = 640; // YOLO için 640
      var convertedBytes = List.generate(
        1,
        (index) => List.generate(
          inputSize,
          (y) => List.generate(inputSize, (x) => List.generate(3, (c) => 0.0)),
        ),
      );

      // Basit nearest neighbor resize
      double scaleX = width / inputSize;
      double scaleY = height / inputSize;

      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          int srcX = (x * scaleX).toInt();
          int srcY = (y * scaleY).toInt();

          // YUV indexleri
          final int uvIndex =
              uvPixelStride * (srcX ~/ 2) + uvRowStride * (srcY ~/ 2);
          final int index = srcY * width + srcX;

          final yp = image.planes[0].bytes[index];
          final up = image.planes[1].bytes[uvIndex];
          final vp = image.planes[2].bytes[uvIndex];

          // YUV to RGB conversion
          int r = (yp + (1.370705 * (vp - 128))).toInt();
          int g = (yp - (0.337633 * (up - 128)) - (0.698001 * (vp - 128)))
              .toInt();
          int b = (yp + (1.732446 * (up - 128))).toInt();

          // Clamp
          r = r.clamp(0, 255);
          g = g.clamp(0, 255);
          b = b.clamp(0, 255);

          // Normalize [0, 1]
          convertedBytes[0][y][x][0] = r / 255.0;
          convertedBytes[0][y][x][1] = g / 255.0;
          convertedBytes[0][y][x][2] = b / 255.0;
        }
      }

      return convertedBytes;
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
    List<Recognition> recognitions = [];

    // YOLOv8 Output Shape: [channels, anchors] -> [9, 8400]
    // 0: x, 1: y, 2: w, 3: h, 4..8: class scores

    int channels = output.length; // 9
    int anchors = output[0].length; // 8400

    print("🔍 YOLO Output Shape: [${output.length}, ${output[0].length}]");

    for (int i = 0; i < anchors; i++) {
      // En yüksek sınıf skorunu bul
      double maxScore = 0;
      int classIndex = -1;

      for (int c = 4; c < channels; c++) {
        double score = output[c][i];
        if (score > maxScore) {
          maxScore = score;
          classIndex = c - 4;
        }
      }

      // Threshold filtresi (%40)
      if (maxScore > 0.40) {
        double x = output[0][i];
        double y = output[1][i];
        double w = output[2][i];
        double h = output[3][i];

        if (i == 0 || i % 1000 == 0) {
          print(
            "📦 Detection [$i]: Score=$maxScore, Class=$classIndex, Box=($x, $y, $w, $h)",
          );
        }

        // YOLOv8 Çıktı Kontrolü:
        if (x > 1.0 || y > 1.0 || w > 1.0 || h > 1.0) {
          x /= 640;
          y /= 640;
          w /= 640;
          h /= 640;
        }

        // Merkez (cx, cy) koordinatlarını sol-üst (x1, y1) köşeye çevir
        double x1 = x - w / 2;
        double y1 = y - h / 2;

        // Sınırları 0..1 arasına klipsle
        x1 = x1.clamp(0.0, 1.0);
        y1 = y1.clamp(0.0, 1.0);
        w = w.clamp(0.0, 1.0);
        h = h.clamp(0.0, 1.0);

        recognitions.add(
          Recognition(
            id: classIndex,
            label: classIndex < _labels.length
                ? _labels[classIndex]
                : 'Unknown',
            confidence: maxScore,
            x: x1,
            y: y1,
            w: w,
            h: h,
          ),
        );
      }
    }

    return _nms(recognitions);
  }

  // Non-Maximum Suppression (Çakışan kutuları temizle)
  List<Recognition> _nms(List<Recognition> list) {
    List<Recognition> result = [];
    // Güvenilirliğe göre sırala (büyükten küçüğe)
    list.sort((a, b) => b.confidence.compareTo(a.confidence));

    while (list.isNotEmpty) {
      Recognition current = list.first;
      result.add(current);
      list.removeAt(0);

      // Çakışanları listeden sil
      list.removeWhere((other) {
        double iou = _calculateIoU(current, other);
        return iou > 0.45; // %45'ten fazla çakışıyorsa sil
      });
    }
    return result;
  }

  // Intersection over Union (IoU) hesapla
  double _calculateIoU(Recognition a, Recognition b) {
    double x1 = math.max(a.x ?? 0.0, b.x ?? 0.0);
    double y1 = math.max(a.y ?? 0.0, b.y ?? 0.0);
    double x2 = math.min(
      (a.x ?? 0.0) + (a.w ?? 0.0),
      (b.x ?? 0.0) + (b.w ?? 0.0),
    );
    double y2 = math.min(
      (a.y ?? 0.0) + (a.h ?? 0.0),
      (b.y ?? 0.0) + (b.h ?? 0.0),
    );

    if (x2 < x1 || y2 < y1) return 0.0;

    double intersection = (x2 - x1) * (y2 - y1);
    double areaA = (a.w ?? 0.0) * (a.h ?? 0.0);
    double areaB = (b.w ?? 0.0) * (b.h ?? 0.0);

    return intersection / (areaA + areaB - intersection);
  }

  void dispose() {
    _interpreter?.close();
    _isModelLoaded = false;
  }
}
