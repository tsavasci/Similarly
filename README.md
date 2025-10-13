# Similarly - iOS Benzer Fotoğraf Temizleyici 📸

<div align="center">

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

**Fotoğraf kütüphanenizdeki benzer fotoğrafları bulun ve temizleyin!**

</div>

---

## 📖 Hakkında

Similarly, iPhone'unuzdaki fotoğraf kütüphanesinde bulunan benzer veya tekrarlayan fotoğrafları akıllı algoritmalar kullanarak tespit eden ve silmenize yardımcı olan bir iOS uygulamasıdır.

### ✨ Özellikler

- 🔍 **Akıllı Benzerlik Analizi**: Perceptual Hash (pHash) ve histogram karşılaştırması
- 📊 **Metadata Filtreleme**: Tarih, lokasyon, boyut ve EXIF verilerine göre ön filtreleme
- 🎯 **Seri Çekim Tespiti**: Ard arda çekilen fotoğrafları otomatik gruplandırma
- 🚀 **Yüksek Performans**: Batch processing ile binlerce fotoğrafı hızlıca analiz
- 🎨 **Modern UI**: SwiftUI ile tasarlanmış kullanıcı dostu arayüz
- ⚙️ **Özelleştirilebilir**: Benzerlik eşikleri ve filtreleme ayarları
- 🗑️ **Güvenli Silme**: Fotoğrafları önizleyip onayladıktan sonra silin
- 📱 **iOS Native**: %100 Swift ve Apple framework'leri

---

## 🛠️ Teknolojiler

- **Swift 5.9+**
- **SwiftUI** - Modern UI framework
- **PhotoKit** - Fotoğraf kütüphanesi erişimi
- **CoreImage** - Görüntü işleme ve histogram analizi
- **CoreLocation** - GPS tabanlı lokasyon filtreleme
- **Async/Await** - Modern concurrency

---

## 📋 Gereksinimler

- iOS 17.0 veya üzeri
- Xcode 15.0 veya üzeri
- Swift 5.9 veya üzeri
- iPhone veya iPad

---

## 🚀 Kurulum

### 1. Projeyi Klonlayın

```bash
git clone https://github.com/yourusername/similarly.git
cd similarly/Similarly
```

### 2. Xcode'da Açın

```bash
open Similarly.xcodeproj
```

### 3. Gerekli Ayarları Yapın

**ÖNEMLİ**: `XCODE_SETUP.md` dosyasını okuyun! İçerisinde:
- Info.plist ayarları
- Capability eklemeleri
- Signing ayarları
- Detaylı kurulum adımları

### 4. Build ve Run

1. Bir iOS Simulator seçin (iPhone 15 Pro önerilir)
2. ⌘ + R tuşuna basın
3. İlk açılışta fotoğraf izni verin

---

## 📱 Kullanım

### Adım 1: Fotoğrafları Yükleyin
Ana ekranda **"Fotoğrafları Yükle"** butonuna tıklayın ve fotoğraf kütüphanesine erişim izni verin.

### Adım 2: Analiz Başlatın
Fotoğraflar yüklendikten sonra **"Benzer Fotoğrafları Bul"** butonuna tıklayın.

### Adım 3: Sonuçları İnceleyin
Benzer fotoğraf gruplarını listeden görüntüleyin. Her grup için:
- Benzerlik skoru
- Fotoğraf sayısı
- Tarih ve lokasyon bilgileri

### Adım 4: Fotoğrafları Seçin
Bir gruba tıklayarak detaylara gidin:
- Silmek istediğiniz fotoğrafları seçin
- Veya "En Eskileri" butonuyla otomatik seçim yapın
- Her fotoğrafın ön izlemesini görün

### Adım 5: Temizleyin
**"Seçilenleri Sil"** butonuyla fotoğrafları kalıcı olarak silin.

---

## 🧠 Nasıl Çalışır?

### 1. Fotoğraf Kütüphanesi Erişimi
```swift
PhotoKit framework'ü ile:
- Tüm fotoğraflar fetch edilir
- Metadata (EXIF, tarih, GPS) okunur
- Thumbnail'ler oluşturulur
```

### 2. Metadata Ön Filtreleme
```
Aday gruplar oluşturulur:
✓ Tarih yakınlığı (±5 saniye) - Seri çekimler
✓ GPS yakınlığı (±100 metre) - Aynı lokasyon
✓ Boyut benzerliği (±%10) - Aynı kamera/ayarlar
```

### 3. Görüntü Bazlı Benzerlik
```
Her fotoğraf için:
1. Perceptual Hash (pHash) hesaplanır
   - 8x8 grayscale thumbnail
   - 64-bit hash değeri
   - Hamming distance ile karşılaştırma

2. Histogram analizi yapılır
   - 64-bin renk histogramı
   - RGB kanal bazlı
   - Bhattacharyya coefficient ile benzerlik skoru
```

### 4. Skorlama ve Gruplama
```
Benzerlik skoru hesaplama:
- pHash benzerliği (ağırlık: 2x)
- Histogram benzerliği (ağırlık: 1x)
- Metadata bonusu (seri çekim: +0.3)

Eşik: %70 ve üzeri benzerlik
```

---

## 🏗️ Proje Yapısı

```
Similarly/
├── Models/
│   └── PhotoItem.swift              # Fotoğraf ve grup modelleri
├── Managers/
│   ├── PhotoLibraryManager.swift    # PhotoKit yönetimi
│   └── SimilarityManager.swift      # Benzerlik analizi
├── Views/
│   ├── MainView.swift               # Ana ekran
│   ├── SimilarPhotosListView.swift  # Sonuç listesi
│   └── SettingsView.swift           # Ayarlar
├── Utilities/
│   └── (Yardımcı fonksiyonlar)
├── Assets.xcassets/
├── Info.plist
└── SimilarlyApp.swift              # Uygulama giriş noktası
```

---

## ⚙️ Ayarlar

Uygulama içi ayarlar:

| Ayar | Varsayılan | Açıklama |
|------|-----------|----------|
| Benzerlik Eşiği | %85 | Minimum benzerlik skoru |
| Tarih Yakınlığı | 5 saniye | Seri çekim toleransı |
| Lokasyon Yakınlığı | 100 metre | GPS filtreleme mesafesi |
| Otomatik Seçim | Açık | En eski fotoğrafları otomatik işaretle |

---

## 🔐 Gizlilik

- Tüm işlemler cihazda yapılır
- Hiçbir veri sunucuya gönderilmez
- Sadece PhotoKit framework'ü kullanılır
- Kullanıcı izni gerektirir (iOS zorunluluğu)
- Fotoğraflar sadece izinle silinir

---

## 🎯 Roadmap

- [x] Temel fotoğraf yükleme ve gösterme
- [x] pHash ve histogram analizi
- [x] Metadata filtreleme
- [x] SwiftUI arayüz
- [x] Fotoğraf silme işlemleri
- [ ] ML-based similarity (CoreML)
- [ ] iCloud Photos desteği
- [ ] Face recognition ile kişi bazlı gruplama
- [ ] Video benzerlik analizi
- [ ] Export/Import ayarları
- [ ] Widget desteği

---

## 🐛 Bilinen Sorunlar

- [ ] Çok büyük kütüphanelerde (50K+ fotoğraf) memory kullanımı yüksek olabilir
- [ ] HEIC formatındaki bazı fotoğraflarda thumbnail yavaş yüklenebilir
- [ ] Simulator'da GPS verileri olmadığı için lokasyon filtreleme test edilemez

---

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz! Lütfen:

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'feat: Add amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

---

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için `LICENSE` dosyasına bakın.

---

## 👨‍💻 Geliştirici

**Tamer Savaşcı**

- GitHub: [@tamersavasci](https://github.com/tamersavasci)
- Email: your.email@example.com

---

## 🙏 Teşekkürler

Bu proje şunları kullanıyor:
- Apple'ın PhotoKit framework'ü
- CoreImage ve Vision framework'leri
- SwiftUI ve modern Swift concurrency

---

## 📞 Destek

Sorunuz veya öneriniz mi var?
- Issue açın: [GitHub Issues](https://github.com/yourusername/similarly/issues)
- Tartışma başlatın: [GitHub Discussions](https://github.com/yourusername/similarly/discussions)

---

<div align="center">

**Fotoğraf kütüphanenizi temiz tutun! 🎉**

⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!

</div>