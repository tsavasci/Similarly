# 🚀 Similarly - Hızlı Başlangıç Rehberi

## 5 Dakikada Çalıştırın! ⚡

---

## 📋 Ön Gereksinimler

- ✅ macOS 14.0 veya üzeri
- ✅ Xcode 15.0 veya üzeri
- ✅ iOS 17.0+ simülatör veya gerçek cihaz

---

## 🎯 Adım 1: Projeyi Açın

```bash
cd Similarly
open Similarly.xcodeproj
```

---

## 📁 Adım 2: Dosyaları Projeye Ekleyin

**ÖNEMLİ:** Oluşturulan dosyalar henüz Xcode projesine eklenmemiş olabilir.

### Yöntem A: Drag & Drop (En Kolay)

1. Finder'da `Similarly/Similarly` klasörünü açın
2. Xcode'da sol panelde **"Similarly"** projesini genişletin
3. Şu klasörleri Finder'dan Xcode'a sürükleyin:
   - `Models/`
   - `Managers/`
   - `Views/`
   - `Utilities/`

4. Açılan pencerede:
   - ☑️ **Copy items if needed** işaretleyin
   - ☑️ **Create groups** seçin
   - ☑️ **Add to targets: "Similarly"** işaretli olsun
   - **"Finish"** butonuna tıklayın

### Yöntem B: File Menu

1. **File > Add Files to "Similarly"**
2. Yukarıdaki klasörleri sırayla seçip ekleyin
3. Aynı ayarları uygulayın

### Kontrol

Sol panelde şu yapıyı görmeli siniz:

```
Similarly/
├── Models/
│   └── PhotoItem.swift
├── Managers/
│   ├── PhotoLibraryManager.swift
│   └── SimilarityManager.swift
├── Views/
│   ├── MainView.swift
│   ├── SimilarPhotosListView.swift
│   ├── SettingsView.swift
│   └── OnboardingView.swift
├── Utilities/
│   └── UIImage+Extensions.swift
├── Assets.xcassets/
├── Info.plist
└── SimilarlyApp.swift
```

---

## 🔐 Adım 3: Info.plist Kontrol

1. Sol panelde **Info.plist** dosyasını seçin
2. Şu key'lerin var olduğunu kontrol edin:
   - ✅ `NSPhotoLibraryUsageDescription`
   - ✅ `NSPhotoLibraryAddUsageDescription`

**Yoksa ekleyin:**

Sağ tıklayın > **Open As > Source Code**

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Similarly, benzer fotoğrafları bulmak için fotoğraf kütüphanenize erişmek istiyor.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>Similarly, fotoğrafları kaydetmek için kütüphanenize erişmek istiyor.</string>
```

---

## ⚙️ Adım 4: Signing Ayarları

1. Sol panelde **Similarly** projesini seçin (en üstteki mavi ikon)
2. **TARGETS** altında **Similarly**'yi seçin
3. **Signing & Capabilities** tab'ine tıklayın
4. **Automatically manage signing** kutusunu işaretleyin
5. **Team** dropdown'dan Apple ID'nizi seçin
   - *Yoksa: Xcode > Settings > Accounts > + butonuyla ekleyin*
6. **Bundle Identifier** benzersiz olmalı
   - Örnek: `com.yourname.similarly`
   - Hata alırsanız sonuna `-test` ekleyin

---

## 🔨 Adım 5: Build

```bash
# Xcode'da:
⌘ + Shift + K  (Clean Build Folder)
⌘ + B          (Build)
```

**Beklenen çıktı:**
```
✅ Build Succeeded
```

**Hata alırsanız:**
- Tüm dosyaların **Target Membership**'i "Similarly" olmalı
- Dosyayı seçin > Sağ panel > File Inspector > Target Membership kontrol edin

---

## ▶️ Adım 6: Run!

1. Üst menüden bir **simülatör** seçin
   - Önerilen: **iPhone 15 Pro**
2. **⌘ + R** tuşuna basın veya **Play** butonuna tıklayın
3. Simülatör açılacak ve uygulama başlayacak

---

## 📸 Adım 7: Test Fotoğrafları Ekleyin

Simülatörde test için fotoğraf eklemeniz gerekiyor:

### Yöntem 1: Safari'den

1. Simülatörde Safari'yi açın
2. Google Images'da bir resim bulun
3. Resme uzun basın
4. **"Add to Photos"** seçin
5. Aynı resmi 3-4 kez kaydedin (benzer fotoğraf testi için)

### Yöntem 2: Drag & Drop

1. Mac'inizde bir resim bulun
2. Resmi simülatör penceresine sürükleyin
3. Photos app'e otomatik eklenecek

### Yöntem 3: Terminal (Batch)

```bash
# Simülatör ID'sini bulun
xcrun simctl list devices | grep Booted

# Fotoğraf ekleyin
xcrun simctl addmedia <SIMULATOR_ID> /path/to/photo.jpg
```

---

## 🎮 Adım 8: Uygulamayı Kullanın

### İlk Açılış

1. **Onboarding** ekranı göreceksiniz (4 sayfa)
   - Kaydırarak geçin veya "Atla" butonuna tıklayın

2. **Ana Ekran** açılacak
   - "Fotoğrafları Yükle" butonuna tıklayın

3. **İzin İsteği** çıkacak
   - **"Allow Access to All Photos"** seçin
   - (veya "Select Photos..." ile sınırlı erişim)

4. **Fotoğraflar İşleniyor** göstergesi
   - Progress bar ile ilerleme görürsünüz
   - 100 fotoğraf ~5-10 saniye sürer

5. **İstatistikler** görünecek
   - Toplam fotoğraf sayısı
   - "Benzer Fotoğrafları Bul" butonu aktif olur

### Benzerlik Analizi

1. **"Benzer Fotoğrafları Bul"** butonuna tıklayın

2. **Analiz başlayacak**
   - Metadata filtreleme
   - pHash hesaplama
   - Histogram karşılaştırması
   - Gruplama

3. **Sonuçlar** listelenecek
   - Her grup için benzerlik skoru
   - Önizleme resimleri
   - Tarih ve konum bilgileri

### Fotoğraf Silme

1. Bir **gruba tıklayın**

2. **Detay ekranında:**
   - Silmek istediğiniz fotoğrafları seçin
   - Veya "En Eskileri" butonuyla otomatik seçim
   - Veya "Tümünü Seç" ile hepsini seç

3. **"Seçilenleri Sil"** butonuna tıklayın

4. **Onay** verin
   - Fotoğraflar Photos app'ten de silinecek
   - Geri alınamaz!

---

## ⚙️ Ayarlar

Sağ üstteki **⚙️** ikonuna tıklayın:

- **Benzerlik Eşiği:** %80 - %100 (varsayılan %85)
- **Tarih Yakınlığı:** 1 - 60 saniye (varsayılan 5)
- **Lokasyon Yakınlığı:** 10 - 1000 metre (varsayılan 100)
- **Otomatik Seçim:** En eski fotoğrafları işaretle

---

## 🐛 Sorun Giderme

### "Photo library access denied"
**Çözüm:**
1. Simülatör > Settings > Similarly > Photos
2. "All Photos" seçin
3. Uygulamayı yeniden başlatın

### Build hatası: "No such module"
**Çözüm:**
```bash
⌘ + Shift + K  (Clean)
⌘ + Option + Shift + K  (Clean Build Folder)
⌘ + B  (Build tekrar)
```

### Fotoğraflar yüklenmiyor
**Çözüm:**
1. Simülatörde Photos app'i açın
2. En az 3-5 fotoğraf olduğunu kontrol edin
3. Similarly'yi yeniden başlatın

### "Cannot find 'PhotoItem' in scope"
**Çözüm:**
1. Models/PhotoItem.swift dosyasını seçin
2. Sağ panel > File Inspector (⌘ + Option + 1)
3. Target Membership > Similarly ✅ işaretli olmalı
4. Tüm .swift dosyaları için tekrarlayın

### Simülatör çok yavaş
**Çözüm:**
- Daha yeni/hızlı bir simülatör seçin (iPhone 15)
- Gerçek cihazda test edin (çok daha hızlı!)

---

## 📱 Gerçek Cihazda Test

1. iPhone'unuzu USB ile bağlayın
2. iPhone > Settings > Privacy & Security > Developer Mode > Açın
3. Xcode'da üst menüden iPhone'unuzu seçin
4. ⌘ + R ile çalıştırın
5. İlk seferde "Untrusted Developer" uyarısı alırsanız:
   - iPhone > Settings > General > VPN & Device Management
   - Developer App > Apple Development > Trust

**Avantajlar:**
- 10x daha hızlı
- Gerçek fotoğraf kütüphanesi
- GPS verileri
- Gerçek kullanım testi

---

## ✅ Başarı Kontrol Listesi

- [ ] Xcode projesi açıldı
- [ ] Tüm klasörler projeye eklendi
- [ ] Info.plist kontrol edildi
- [ ] Signing yapılandırıldı
- [ ] Build başarılı (⌘ + B)
- [ ] Simülatörde çalıştı (⌘ + R)
- [ ] Onboarding görüldü
- [ ] Fotoğraf izni verildi
- [ ] Fotoğraflar yüklendi
- [ ] Benzerlik analizi çalıştı
- [ ] Gruplar listelendi
- [ ] Fotoğraf silme test edildi

---

## 🎉 Tebrikler!

Similarly artık çalışıyor! 

### Sonraki Adımlar:

1. 📖 **README.md** okuyun - detaylı bilgi
2. 🔧 **XCODE_SETUP.md** okuyun - ileri düzey ayarlar
3. 📊 **PROJECT_SUMMARY.md** okuyun - proje detayları
4. 🎨 UI'ı özelleştirin
5. 🚀 Production'a hazırlayın

---

## 📞 Yardım

Takıldınız mı?

1. Console log'larına bakın (⌘ + Shift + Y)
   - 🔍, 📸, ✅ emojileriyle işaretli log'lar var

2. Clean Build Folder yapın (⌘ + Shift + K)

3. Derived Data silin:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

4. Projeyi kapatıp tekrar açın

---

**Başarılar! 🚀**

*Toplam süre: ~5 dakika*