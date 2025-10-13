# Xcode Proje Ayarları

## 📱 Similarly iOS Uygulaması - Xcode Kurulum Rehberi

Bu dosya, Similarly projesini Xcode'da çalıştırmak için yapmanız gereken ayarları içerir.

---

## 🔧 1. Capability Eklemeleri

### Photo Library Erişimi

1. Xcode'da projeyi açın
2. Sol panelden **Similarly** projesini seçin
3. **TARGETS** altında **Similarly**'yi seçin
4. Üst menüden **Signing & Capabilities** sekmesine gidin
5. **+ Capability** butonuna tıklayın
6. Arama kutusuna **"Photo"** yazın
7. **"Photos"** capability'sini ekleyin *(normalde otomatik eklenir, info.plist yeterli)*

---

## 📄 2. Info.plist Ayarları

Info.plist dosyasına aşağıdaki izin açıklamalarını eklemeniz GEREKİR:

### Yöntem 1: Xcode ile ekleme (Önerilen)

1. **Similarly** klasöründe `Info.plist` dosyasını bulun (yoksa oluşturun)
2. Sağ tıklayıp **Open As > Source Code** seçin
3. `<dict>` tagı içine aşağıdaki satırları ekleyin:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Similarly, benzer fotoğrafları bulmak için fotoğraf kütüphanenize erişmek istiyor.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>Similarly, fotoğrafları kaydetmek için kütüphanenize erişmek istiyor.</string>
```

### Yöntem 2: Property List Editor ile

1. Info.plist'i çift tıklayarak açın
2. Sağ tıklayın ve **Add Row** seçin
3. Şu key'leri ekleyin:
   - `Privacy - Photo Library Usage Description`
   - Değer: `Similarly, benzer fotoğrafları bulmak için fotoğraf kütüphanenize erişmek istiyor.`

---

## 🎯 3. Deployment Target

1. **TARGETS > Similarly** seçin
2. **General** sekmesinde
3. **Deployment Info** bölümünde **iOS 17.0** veya üzeri olduğundan emin olun

---

## 📦 4. Dosyaları Projeye Ekleme

Oluşturduğum tüm dosyaların Xcode projesine eklendiğinden emin olun:

### Models
- ✅ `Models/PhotoItem.swift`

### Managers
- ✅ `Managers/PhotoLibraryManager.swift`
- ✅ `Managers/SimilarityManager.swift`

### Views
- ✅ `Views/MainView.swift`
- ✅ `Views/SimilarPhotosListView.swift`
- ✅ `Views/SettingsView.swift`

### Dosyaları Ekleme:
1. Xcode'da **File > Add Files to "Similarly"**
2. Yukarıdaki klasörleri seçin
3. **"Copy items if needed"** işaretli olsun
4. **"Create groups"** seçili olsun
5. **Add to targets:** "Similarly" işaretli olsun

---

## ⚙️ 5. Build Settings Kontrolleri

### Swift Language Version
1. **Build Settings** sekmesine gidin
2. **Swift Language Version** araması yapın
3. **Swift 5** veya üzeri olmalı

### Architectures
1. **Build Settings > Architectures**
2. Standard architectures (arm64) seçili olmalı

---

## 🔑 6. Signing (İmzalama)

1. **Signing & Capabilities** sekmesinde
2. **Automatically manage signing** işaretleyin
3. **Team** dropdown'dan Apple Developer hesabınızı seçin
4. **Bundle Identifier** benzersiz olmalı (örn: `com.yourname.similarly`)

---

## ✅ 7. Derleme ve Çalıştırma

### Simulator'da Test
1. Üst menüden bir iOS Simulator seçin (iPhone 15 Pro önerilir)
2. **⌘ + R** tuşuna basın veya **Product > Run**
3. İlk açılışta fotoğraf izni isteyecek

### Gerçek Cihazda Test
⚠️ **ÖNEMLİ**: Gerçek cihazda test etmek için:
1. iPhone'unuzun USB ile bağlı olması gerekir
2. iPhone'da **Settings > Privacy > Developer Mode** aktif olmalı
3. Xcode'da cihazı seçin ve çalıştırın

---

## 🐛 8. Olası Hatalar ve Çözümleri

### Hata: "No such module PhotoKit"
- **Çözüm**: Clean Build Folder (⌘ + Shift + K) yapın, sonra tekrar build edin

### Hata: "Photo library access denied"
- **Çözüm**: 
  1. Info.plist'de privacy key'lerin doğru olduğundan emin olun
  2. Simulator'ı sıfırlayın: Device > Erase All Content and Settings
  3. Uygulamayı tekrar çalıştırın

### Hata: "Cannot find 'PhotoItem' in scope"
- **Çözüm**: Tüm dosyaların Target Membership'inin "Similarly" olduğundan emin olun
  1. Dosyayı seçin
  2. Sağ panelde **File Inspector** (⌘ + Option + 1)
  3. **Target Membership** altında "Similarly" işaretli olmalı

### Hata: Build fails - "Multiple commands produce..."
- **Çözüm**: 
  1. **Build Phases** sekmesine gidin
  2. **Copy Bundle Resources** altında duplicate dosyalar varsa silin
  3. Clean build folder ve tekrar build edin

---

## 📱 9. İlk Çalıştırma

Uygulama ilk çalıştığında:

1. ✅ **Ana ekran** görünecek
2. 📸 **"Fotoğrafları Yükle"** butonuna tıklayın
3. 🔐 **İzin penceresi** çıkacak - "Allow Full Access" seçin
4. ⏳ Fotoğraflar yüklenip işlenecek (progress bar gösterilir)
5. ✨ **"Benzer Fotoğrafları Bul"** butonu aktif olacak
6. 🔍 Analiz başlayacak
7. 📊 Sonuçlar listelenecek

---

## 🎨 10. Simulator'da Test Fotoğrafları

Simulator'da test etmek için fotoğraf ekleyin:

1. Safari'de bir resim açın
2. Resme uzun basın > "Add to Photos"
3. Veya: **Drag & Drop** yaparak simulator'a resim atın
4. Birkaç benzer resim ekleyin (aynı resmin kopyaları)

---

## 📞 Yardım

Herhangi bir sorunla karşılaşırsanız:
- Xcode Console'u kontrol edin (⌘ + Shift + Y)
- Print log'larına bakın (🔍, 📸, ✅ emojileriyle başlar)
- Clean Build Folder yapın (⌘ + Shift + K)
- Derived Data'yı silin: `~/Library/Developer/Xcode/DerivedData`

---

## ✨ Özellikler

Uygulama şu özelliklere sahip:

- ✅ PhotoKit ile fotoğraf kütüphanesi erişimi
- ✅ Perceptual Hash (pHash) ile görsel benzerlik
- ✅ Histogram analizi ile renk karşılaştırma
- ✅ Metadata (tarih, lokasyon, boyut) filtreleme
- ✅ Seri çekim tespiti
- ✅ Batch processing ile performans optimizasyonu
- ✅ SwiftUI ile modern kullanıcı arayüzü
- ✅ Fotoğraf silme işlemleri
- ✅ Grup detayları ve önizleme
- ✅ Ayarlanabilir benzerlik eşikleri

---

**Başarılar! 🚀**