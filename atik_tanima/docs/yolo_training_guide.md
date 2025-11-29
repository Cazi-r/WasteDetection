# YOLOv8 Model Eğitimi ve Veri Etiketleme Rehberi

Bu rehber, kendi atık tanıma modelinizi (Object Detection) sıfırdan nasıl oluşturacağınızı adım adım anlatır.

## 1. Adım: Veri Etiketleme (Roboflow)

Elinizdeki resimleri etiketlemek için en iyi ve en kolay araç **Roboflow**'dur.

### 1.1. Hesap Oluşturma ve Proje Açma

1.  [roboflow.com](https://roboflow.com) adresine gidin ve ücretsiz bir hesap oluşturun.
2.  **"Create New Project"** butonuna tıklayın.
3.  **Project Type** olarak **"Object Detection"** seçin (Bu çok önemli!).
4.  Proje ismini (örn: `atik-tanima`) ve nesne türünü (örn: `waste`) girin.

### 1.2. Resimleri Yükleme

1.  Sol menüden **"Upload"** kısmına gelin.
2.  Elinizdeki tüm atık fotoğraflarını sürükleyip bırakın.
3.  **"Save and Continue"** diyerek yüklemeyi tamamlayın.

### 1.3. Etiketleme (Annotation)

Bu aşamada bilgisayara nesnelerin nerede olduğunu öğreteceğiz.

1.  Sol menüden **"Annotate"** kısmına tıklayın.
2.  İlk resme tıklayın.
3.  Resimdeki atığın etrafına farenizle **sıkı bir kutu (bounding box)** çizin.
4.  Açılan kutucuğa nesnenin ismini yazın (örn: `plastik`, `kagit`, `metal`, `cam`, `organik`).
    - **ÖNEMLİ:** Etiket isimlerini Türkçe karakter kullanmadan (kagit, sise, kapak) ve küçük harfle yazmanız işinizi kolaylaştırır.
5.  Eğer resimde birden fazla atık varsa (örn: yan yana şişe ve kağıt), hepsini ayrı ayrı kutu içine alın.
6.  Tüm resimler için bu işlemi yapın.

### 1.4. Dataset Oluşturma (Generate)

1.  Sol menüden **"Generate"** kısmına gelin.
2.  **Preprocessing:** "Auto-Orient" ve "Resize (Stretch to 640x640)" seçili olsun.
3.  **Augmentation:** Veri sayınızı yapay olarak artırmak için burayı kullanabilirsiniz (örn: Flip, Rotation). Başlangıç için boş bırakabilirsiniz veya sadece "Flip: Horizontal" ekleyebilirsiniz.
4.  **"Create"** butonuna basın.

### 1.5. Dışa Aktarma (Export)

1.  Dataset oluştuktan sonra sağ üstteki **"Export Dataset"** butonuna tıklayın.
2.  Format olarak **"YOLOv8"** seçin.
3.  **"Show Download Code"** seçeneğini işaretleyin.
4.  Size verilen kodu bir kenara not edin (Google Colab'da kullanacağız).

---

## 2. Adım: Model Eğitimi (Google Colab)

Bilgisayarınızın gücü yetmeyebilir, bu yüzden Google'ın ücretsiz sunduğu **Colab** servisini kullanacağız.

1.  [Google Colab](https://colab.research.google.com/) adresine gidin.
2.  **"Yeni Not Defteri"** (New Notebook) oluşturun.
3.  Menüden **Çalışma Zamanı > Çalışma Zamanı Türünü Değiştir** (Runtime > Change runtime type) diyip **T4 GPU**'yu seçin.

### 2.1. Kurulum Kodları

Aşağıdaki kodları sırasıyla hücrelere yapıştırıp çalıştırın (Play butonu):

```python
# 1. Ultralytics (YOLO) kütüphanesini yükle
!pip install ultralytics
```

```python
# 2. Roboflow'dan veriyi çek (BURAYA KENDİ KODUNUZU YAPIŞTIRIN)
# Roboflow'da "Export" kısmında size verilen !pip install roboflow ile başlayan blok
from roboflow import Roboflow
rf = Roboflow(api_key="SIZIN_API_KEYINIZ")
project = rf.workspace("...").project("...")
dataset = project.version(1).download("yolov8")
```

```python
# 3. Eğitimi Başlat
from ultralytics import YOLO

# Modeli yükle (yolov8n.pt en hızlı olanıdır, mobil için ideal)
model = YOLO('yolov8n.pt')

# Eğitimi başlat (data.yaml dosyasının yolu indirdiğiniz klasörde olacak)
# epochs=50 veya 100 yapabilirsiniz. imgsz=640 standarttır.
model.train(data='/content/atik-tanima-1/data.yaml', epochs=50, imgsz=640)
```

### 2.2. Modeli İndirme ve Dönüştürme

Eğitim bittikten sonra `runs/detect/train/weights/best.pt` dosyasını TFLite formatına çevirmemiz lazım.

```python
# Modeli TFLite formatına çevir
model.export(format='tflite')
```

Bu işlem sonucunda `best_saved_model/best_float32.tflite` gibi bir dosya oluşacak. Bu dosyayı indirip bana getireceksiniz!

## 3. Adım: Uygulamaya Entegrasyon

1.  İndirdiğiniz `.tflite` dosyasını projenin `assets/models/` klasörüne atın.
2.  `labels.txt` dosyasını Roboflow'daki etiket sırasına göre güncelleyin.
3.  Gerisini bana bırakın! 🚀
