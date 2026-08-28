<div align="center">

# WasteDetection

**Flutter için cihaz üstünde atık ayrıştırma: TFLite'a dönüştürülmüş bir YOLOv8 modeli, canlı kameradan veya fotoğraftan cam, kâğıt, metal, pil ve plastiği tanır — sunucu yok, internet yok.**

[![Lisans: MIT](https://img.shields.io/badge/Lisans-MIT-yellow.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg)](https://flutter.dev/)
[![TensorFlow Lite](https://img.shields.io/badge/TensorFlow-Lite-FF6F00.svg)](https://www.tensorflow.org/lite)
[![YOLOv8](https://img.shields.io/badge/YOLOv8-nesne%20tespiti-00FFFF.svg)](https://docs.ultralytics.com/)

[English](README.md) · [Türkçe](README.tr.md)

</div>

---

## Genel Bakış

Kamerayı bir atığa doğrultun; uygulama etrafına sınırlayıcı kutu çizip malzemesini söyler. Her
şey `tflite_flutter` üzerinden yerelde çalışır — çıkarım cihazdan hiç çıkmaz, dolayısıyla
uygulama çevrimdışı çalışır ve hiçbir görüntüyü hiçbir yere göndermez.

Tanınan sınıflar:

| | | | | |
|---|---|---|---|---|
| ♻️ `cam` | 📄 `kagit` | 🥫 `metal` | 🔋 `pil` | 🧴 `plastik` |

## İki model, iki görev

Uygulama aynı YOLOv8 ağının **iki** farklı dışa aktarımını içerir ve çalışma anında aralarında geçiş yapar:

| Model | Boyut | Kullanım | Ödünleşim |
|---|---:|---|---|
| `assets/models/small/best_float32.tflite` | 12 MB | Canlı kamera akışı | Kare başına çıkarım için yeterince hızlı |
| `assets/models/big/best_float32.tflite` | 97 MB | Galeri fotoğrafları ve durağan görüntüler | Daha yavaş, belirgin şekilde daha isabetli |

İkisi de YOLOv8'in varsayılan eğitim çözünürlüğüyle uyumlu olarak 640×640 girdi alır.

> [!WARNING]
> Büyük model bu repoda 97 MB'lık tek bir dosyadır; tam klonlama 200 MB'ın epey üzerinde veri
> indirir. Yalnızca kodu okumak istiyorsanız `git clone --filter=blob:none` kullanın.

## Özellikler

- 📷 Kamera akışından canlı tespit, önizleme üzerine çizilen sınırlayıcı kutular
- 🖼️ Galeriden seçilen fotoğraflarda tespit
- 🔀 Otomatik model geçişi — canlıda küçük, durağan görüntüde büyük model
- 🕘 Cihazda saklanan tarama geçmişi, tek tek silme ve toplu temizleme
- 👋 Tanıtım (onboarding) akışı, ayarlardan tekrar gösterilebilir
- ℹ️ Atık kategorilerini açıklayan bilgi ekranı
- 📴 Tamamen çevrimdışı — arka uç yok, hesap yok, çıkarım için ağ izni gerekmez

## Ekranlar

| Rota | Ekran | Amacı |
|---|---|---|
| `/` | `splash_screen.dart` | Açılış, model yükleme |
| `/onboarding` | `onboarding_screen.dart` | İlk açılış tanıtımı |
| `/home` | `new_home_screen.dart` | Giriş noktası — canlı kamera veya galeri |
| `/camera` | `camera_screen.dart` | Sınırlayıcı kutu bindirmeli canlı akış |
| `/result` | `result_screen.dart` | Durağan görüntü için tespit sonucu |
| `/history` | `history_screen.dart` | Geçmiş taramalar, tek tek silme |
| `/info` | `info_screen.dart` | Hangi atık hangi kutuya |
| `/settings` | `settings_screen.dart` | Tanıtımı tekrar göster, geçmişi temizle, sürüm |

## Mimari

| Servis | Görevi |
|---|---|
| `tflite_service.dart` | Model yükleme, model değiştirme, kare ve dosya üzerinde çıkarım |
| `camera_service.dart` | Kamera yaşam döngüsü ve kare akışı |
| `history_service.dart` | SharedPreferences ile tarama geçmişi |
| `preferences_service.dart` | Uygulama tercihleri (tanıtım görüldü vb.) |

`ui/widgets/bounding_box_painter.dart`, model koordinatlarını önizlemeye eşleyip kutuları çizen
bir `CustomPainter`'dır.

## Kurulum

**Gereksinimler:** Flutter SDK ve fiziksel bir cihaz — kamera akışı emülatörlerde çalışmaz.

```bash
git clone https://github.com/Cazi-r/WasteDetection.git
cd WasteDetection
flutter pub get
flutter run
```

İlk açılışta kamera iznini verin (`permission_handler` tarafından yönetilir).

## Kendi Modelinizi Eğitmek

[`docs/yolo_training_guide.md`](docs/yolo_training_guide.md) tüm süreci adım adım anlatan bir
rehberdir:

1. **Etiketleme** — görüntüleri Roboflow'da Object Detection projesi olarak, 640×640
2. **Eğitim** — Google Colab'da YOLOv8
3. **Dışa aktarma** — `.pt` ağırlıklarını TFLite'a dönüştürme
4. **Yerleştirme** — `assets/models/` altındaki dosyaları değiştirin ve `labels.txt`'i güncelleyin

`labels.txt` içindeki sınıf isimleri, modelin eğitildiği sırayla aynı kalmalıdır.

## Teknoloji Yığını

| Katman | Teknoloji |
|---|---|
| Uygulama | Flutter, Dart |
| Çıkarım | `tflite_flutter` (TensorFlow Lite) |
| Model | YOLOv8, TFLite float32 olarak dışa aktarıldı |
| Kamera | `camera`, `permission_handler` |
| Görüntü | `image_picker`, `image`, `path_provider` |
| Depolama | `shared_preferences` |
| Arayüz | `smooth_page_indicator`, `intl` |

## Proje Yapısı

```
.
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── constants/app_colors.dart
│   │   └── routes/app_routes.dart
│   ├── models/
│   │   ├── recognition.dart          Tek tespit: kutu, etiket, skor
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
│   ├── big/best_float32.tflite       97 MB — durağan görüntü
│   ├── small/best_float32.tflite     12 MB — canlı kamera
│   └── labels.txt                    5 sınıf
├── docs/yolo_training_guide.md
└── pubspec.yaml
```

## Sınırlamalar

- Küçük ve özel bir veri setiyle eğitilmiştir — karmaşık sahnelerde ve alışılmadık ışıkta
  isabet düşer.
- Yalnızca beş sınıf vardır; bunların dışındaki her şey en yakın sınıfa zorlanır.
- Belediyeden belediyeye değişen yerel geri dönüşüm kurallarının yerini tutmaz.

## Ders

Makine Görmesi dönem projesi.

## Lisans

[MIT Lisansı](LICENSE) ile yayımlanmıştır.
