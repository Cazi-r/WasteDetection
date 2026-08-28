<div align="center">

# WasteDetection

**On-device waste sorting for Flutter: a YOLOv8 model converted to TFLite that identifies glass, paper, metal, batteries and plastic from the live camera or a photo — no server, no network.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg)](https://flutter.dev/)
[![TensorFlow Lite](https://img.shields.io/badge/TensorFlow-Lite-FF6F00.svg)](https://www.tensorflow.org/lite)
[![YOLOv8](https://img.shields.io/badge/YOLOv8-object%20detection-00FFFF.svg)](https://docs.ultralytics.com/)

[English](README.md) · [Türkçe](README.tr.md)

</div>

---

## Overview

Point the camera at a piece of waste and the app draws a bounding box around it and names the
material. Everything runs locally through `tflite_flutter` — inference never leaves the device,
so the app works offline and sends no images anywhere.

Detected classes:

| | | | | |
|---|---|---|---|---|
| ♻️ `cam` (glass) | 📄 `kagit` (paper) | 🥫 `metal` | 🔋 `pil` (battery) | 🧴 `plastik` (plastic) |

## Two models, two jobs

The app ships **two** exports of the same YOLOv8 network and switches between them at runtime:

| Model | Size | Used for | Trade-off |
|---|---:|---|---|
| `assets/models/small/best_float32.tflite` | 12 MB | Live camera stream | Fast enough for per-frame inference |
| `assets/models/big/best_float32.tflite` | 97 MB | Gallery photos and stills | Slower, noticeably more accurate |

Both take 640×640 input, matching YOLOv8's default training resolution.

> [!WARNING]
> The large model is a 97 MB file in this repository, so a full clone pulls well over 200 MB.
> If you only want to read the code, use `git clone --filter=blob:none`.

## Features

- 📷 Live detection from the camera stream with bounding boxes drawn over the preview
- 🖼️ Detection on photos picked from the gallery
- 🔀 Automatic model switching — small for live, big for stills
- 🕘 Scan history stored on device, with per-item delete and bulk clear
- 👋 Onboarding flow, replayable from settings
- ℹ️ Info screen explaining the waste categories
- 📴 Fully offline — no backend, no account, no network permission needed for inference

## Screens

| Route | Screen | Purpose |
|---|---|---|
| `/` | `splash_screen.dart` | Launch, model loading |
| `/onboarding` | `onboarding_screen.dart` | First-run walkthrough |
| `/home` | `new_home_screen.dart` | Entry point — live camera or gallery |
| `/camera` | `camera_screen.dart` | Live stream with bounding-box overlay |
| `/result` | `result_screen.dart` | Detection result for a still image |
| `/history` | `history_screen.dart` | Past scans, delete individually |
| `/info` | `info_screen.dart` | What goes in which bin |
| `/settings` | `settings_screen.dart` | Replay onboarding, clear history, version |

## Architecture

| Service | Responsibility |
|---|---|
| `tflite_service.dart` | Model loading, model switching, inference on frames and files |
| `camera_service.dart` | Camera lifecycle and frame streaming |
| `history_service.dart` | Scan history via SharedPreferences |
| `preferences_service.dart` | App preferences (onboarding seen, etc.) |

`ui/widgets/bounding_box_painter.dart` is a `CustomPainter` that maps model coordinates onto the
preview and draws the boxes.

## Getting Started

**Prerequisites:** Flutter SDK and a physical device — the camera path does not work in emulators.

```bash
git clone https://github.com/Cazi-r/WasteDetection.git
cd WasteDetection
flutter pub get
flutter run
```

Grant camera permission on first launch (handled by `permission_handler`).

## Training Your Own Model

[`docs/yolo_training_guide.md`](docs/yolo_training_guide.md) is a
step-by-step guide (in Turkish) covering the whole pipeline:

1. **Label** — annotate images in Roboflow as an Object Detection project, 640×640
2. **Train** — YOLOv8 in Google Colab
3. **Export** — convert the `.pt` weights to TFLite
4. **Drop in** — replace the files under `assets/models/` and update `labels.txt`

Class names in `labels.txt` must stay in the same order the model was trained with.

## Tech Stack

| Layer | Technology |
|---|---|
| App | Flutter, Dart |
| Inference | `tflite_flutter` (TensorFlow Lite) |
| Model | YOLOv8, exported to TFLite float32 |
| Camera | `camera`, `permission_handler` |
| Images | `image_picker`, `image`, `path_provider` |
| Storage | `shared_preferences` |
| UI | `smooth_page_indicator`, `intl` |

## Project Structure

```
.
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── constants/app_colors.dart
│   │   └── routes/app_routes.dart
│   ├── models/
│   │   ├── recognition.dart          One detection: box, label, score
│   │   └── history_item.dart
│   ├── services/
│   │   ├── tflite_service.dart
│   │   ├── camera_service.dart
│   │   ├── history_service.dart
│   │   └── preferences_service.dart
│   └── ui/
│       ├── screens/                  splash, onboarding, camera, result, history, info, settings
│       └── widgets/bounding_box_painter.dart
├── assets/models/
│   ├── big/best_float32.tflite       97 MB — stills
│   ├── small/best_float32.tflite     12 MB — live camera
│   └── labels.txt                    5 classes
├── docs/yolo_training_guide.md
└── pubspec.yaml
```

## Limitations

- Trained on a small custom dataset — accuracy drops on cluttered scenes and unusual lighting.
- Five classes only; anything outside them gets forced into the nearest one.
- Not a substitute for local recycling rules, which vary by municipality.

## Course

Computer Vision (Makine Görmesi) term project.

## License

Released under the [MIT License](LICENSE).
