import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  CameraController? get controller => _controller;

  Future<void> initialize() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.medium, // High yerine medium - emülatörde daha stabil
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420, // Buffer yönetimi için
      );
      await _controller!.initialize();
    }
  }

  Future<void> startImageStream(Function(CameraImage) onLatestImage) async {
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.startImageStream((image) {
        onLatestImage(image);
      });
    }
  }

  Future<void> stopImageStream() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      await _controller!.stopImageStream();
    }
  }

  Future<void> dispose() async {
    await stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }
}
