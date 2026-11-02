# Similarly — AI Kodlama Ajanları Kılavuzu (Agents.md)

Bu doküman, **Similarly** kod tabanı üzerinde çalışan tüm yapay zeka kodlama ajanlarının (AI Coding Agents) projeyi hızlıca anlaması, mimari ve güvenlik kurallarını bozmadan geliştirme yapması için hazırlanmış bağlayıcı çalışma kılavuzudur.

---

## 1. Projeyi Anlama Sırası (Önce Bunları Oku)

Bir göreve başlamadan önce bağlamı eksiksiz kurmak için şu referans dosyalarını incele:
1. **[PRD.md](file:///Users/tamersavasci/Documents/Similarly/PRD.md):** Ürünün ne yaptığı, hedef kitlesi, iş kuralları, benzerlik/kopya tespiti ve güvenli silme akışı.
2. **[Architecture.md](file:///Users/tamersavasci/Documents/Similarly/Architecture.md):** Vision ve Accelerate tabanlı analiz motoru (`PhotoAnalyzer`), kayan pencere ve SimHash kümeleme (`SimilarityEngine`), SwiftData önbellek yapısı (`ProcessedPhoto`) ve PhotoKit yaşam döngüsü.
3. **[Design-System.md](file:///Users/tamersavasci/Documents/Similarly/Design-System.md):** Sıcak ve güven verici tasarım sistemi, renk token'ları, tipografi, haptikler ve bileşenler (`StatCard`, `ProcessingOverlay`, `SimilarPhotoCard`).
4. **[Web Sitesi (Similarly/web)](file:///Users/tamersavasci/Documents/Similarly/Similarly/web):** Landing page, responsive arayüz (`index.html`), gizlilik politikası (`privacy.html`), 8 dilde web çevirileri (`translations.js`) ve App Store indirme vitrini.
5. **[ASO_AND_MARKETING_PACK.md](file:///Users/tamersavasci/Documents/Similarly/ASO_AND_MARKETING_PACK.md):** 8 dilde App Store anahtar kelimeleri, açıklama metinleri ve dönüşüm stratejileri.

---

## 2. Teknoloji Yığını ve Derleme Ortamı

- **Dil & Platform:** Swift 6, iOS 18.0+, katı eşzamanlılık (`@MainActor`, `Sendable`, `TaskGroup`).
- **UI Çerçevesi:** SwiftUI + Observation (`@Observable`).
- **Görüntü İşleme & Yapay Zeka:**
  - `Vision`: `VNGenerateImageFeaturePrintRequest` ile görsel öznitelik vektörü üretimi.
  - `Accelerate`: `vDSP` ile vektörel mesafe ve matris hesaplamaları.
  - `CoreImage`: Laplacian filtresiyle keskinlik/bulanıklık varyansı ve parlaklık ölçümü.
- **Yerel Kalıcılık:** SwiftData (`@Model final class ProcessedPhoto`), `UserDefaults` (`AppSettings`).
- **Medya Erişimi:** PhotoKit (`PHPhotoLibrary`, `PHAsset`, `PHCachingImageManager`).
- **Derleme ve Test Komutları:**
  ```bash
  # Simülatör için derleme
  xcodebuild -project Similarly.xcodeproj -scheme Similarly -destination 'platform=iOS Simulator,name=iPhone 16' build

  # Birim testlerini çalıştırma (SimilarlyTests)
  xcodebuild test -project Similarly.xcodeproj -scheme Similarly -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SimilarlyTests
  ```

---

## 3. Kesinlikle Uyulması Gereken Kurallar (Hard Invariants)

### 3.1. Sıfır Bulut / Tam Gizlilik (Zero-Cloud / On-Device Only)
1. **Dışa Veri Çıkışı Kesinlikle Yasaktır:**
   - Hiçbir fotoğraf karesi, piksel dizisi veya öznitelik vektörü harici bir ağ adresine iletilemez. Uygulamada ağ katmanı (`URLSession`) analiz amacıyla kullanılamaz.
2. **Apple Privacy Manifest:**
   - Fotoğraf galerisi erişimi `NSPhotoLibraryUsageDescription` sınırlarında kalmalıdır.

### 3.2. Veri Güvenliği ve Fotoğraf Koruma İlkeleri
1. **Favori Fotoğraflar Asla Otomatik Silinemez:**
   - Kullanıcının favorilediği (`isFavorite == true`) fotoğraflar hiçbir otomatik seçim algoritmasında silinecek olarak işaretlenemez (`isSelectedForDeletion = false`).
2. **Kalıcı Silme Yok (Apple Son Silinenler Entegrasyonu):**
   - Silme işlemleri mutlaka PhotoKit'in standart `PHAssetChangeRequest.deleteAssets` API'si üzerinden yapılmalıdır. Bu sayede silinen görseller doğrudan Apple Fotoğraflar uygulamasının "Son Silinenler" albümüne gider ve kullanıcı dilediğinde 30 gün içinde kurtarabilir.
3. **"En İyi Fotoğraf" Koruması:**
   - Benzer fotoğraf gruplarında keskinlik (Laplacian varyansı) ve parlaklık dengesi en yüksek olan kare `isBest = true` olarak işaretlenir ve silme listesinde varsayılan olarak seçilmeden korunur.

### 3.3. Bellek ve Büyük Veri Ölçeklenebilirliği (20.000+ Fotoğraf)
1. **Tam Boyutlu Resimleri Belleğe Yüklememe:**
   - Liste ve ızgara görünümlerinde orijinal `UIImage` nesneleri kesinlikle bellekte tutulamaz. Her zaman [AssetImageLoader.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Managers/AssetImageLoader.swift) ve paylaşımlı `PHCachingImageManager` üzerinden optimize edilmiş küçük boyutlu küçük resimler (thumbnail) yüklenmelidir.
2. **NSCache Bellek Limiti:**
   - Görsel önbelleği 100 MB üst sınırına tabidir. Sistem bellek uyarısı (`didReceiveMemoryWarningNotification`) verdiğinde önbellek derhal boşaltılmalıdır.
3. **SwiftData Önbellekleme:**
   - Her analizi sıfırdan yapmak yerine, önceden işlenmiş fotoğraflar `ProcessedPhoto` tablosunda saklanır (`analysisVersion` takibi ile). Kütüphane değişikliklerinde yalnızca yeni/düzenlenmiş fotoğraflar taranır.

---

## 4. UI / Tasarım Sistemi ve Yerelleştirme Kuralları

### 4.1. Tasarım Sistemi Kullanımı
- Yeni bir ekran veya kart eklerken [Design-System.md](file:///Users/tamersavasci/Documents/Similarly/Design-System.md) içindeki token'ları ve `DesignSystem.swift` sabitlerini (`Colors`, `Typography`, `Spacing`, `CornerRadius`) kullan.
- Fotoğraf kartlarında seçili durumlar için `DesignSystem.Colors.accent` (Amber) ve onay durumları için `DesignSystem.Colors.success` (Zümrüt Yeşil) tonlarını koru.
- Dinamik ada, çentik ve alt sekme çubuğu boşlukları için `safeAreaInsets` değerlerine dikkat et.

### 4.2. 8 Dilde Yerelleştirme Zorunluluğu (Localization)
- Kullanıcıya gösterilen metinler [L10n.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Utilities/L10n.swift) üzerinden sağlanmalıdır.
- Desteklenen 8 dilin tamamı (`en`, `tr`, `de`, `fr`, `es`, `ja`, `zh-Hans`, `ar`) desteklenmeli, Arapça için RTL düzen uyumu bozulmamalıdır.

---

## 5. Görev Sonrası Kontrol Listesi (Definition of Done)

Bir kod değişikliğini tamamlamadan önce şu maddeleri kontrol et:
- [ ] Yeni özellik favori fotoğrafların (`isFavorite`) güvenliğini koruyor mu?
- [ ] Silme işlemi PhotoKit "Son Silinenler" standardına uygun mu?
- [ ] 20.000+ fotoğraflık bir galeride bellek sızıntısı veya aşırı bellek tüketimi riski var mı?
- [ ] Yeni UI metinleri 8 dilde `L10n.swift` içine eklendi mi?
- [ ] `SimilarlyTests` altındaki testler başarıyla geçiyor mu?

---

## 6. Sanal Ofis (`Ajan Ofisi`) Kadrosu ve Commit Kuralları (Zorunlu)

### 6.1. Sanal Ofis Kadrosu (8 Ajan)
- **Boss Atlas (office-manager):** Yönetici Masası
- **Arch Swift (ios-architect-dev):** Masa 1 — iOS Baş Mimarı
- **Bug Hunter (ios-debugger):** Masa 2 — Debug ve Performans Uzmanı
- **Test Guard (ios-qa-tester):** Masa 3 — QA ve Test Otomasyon Uzmanı
- **Growth Maven (aso-pr-specialist):** Masa 4 — ASO ve PR Uzmanı
- **Care Hero (customer-support-lead):** Masa 5 — Müşteri Destek ve UX Lideri
- **Shield Ops (security-privacy-auditor):** Masa 6 — Güvenlik ve Gizlilik Denetçisi
- **Pixel Craft (web-designer):** Masa 7 — Web Tasarımcısı ve Frontend Geliştiricisi (`Similarly/web`)

### 6.2. Kırmızı Çizgi Kuralları
1. **🛑 Test Edilmemiş Revizyon Commit Edilemez:**
   - **Xcode iOS Simülatöründe (`xcodebuild test -project Similarly.xcodeproj -scheme Similarly -destination 'platform=iOS Simulator,...'`) test edilmemiş ve `** TEST SUCCEEDED **` sonucu alınmamış hiçbir kod revizyonu kesinlikle `git commit` veya `git push` yapılamaz!**
2. **🌐 Web Tasarım ve Dil Bütünlüğü:**
   - `Similarly/web` üzerinde çalışan `Pixel Craft`, 8 dildeki `translations.js` bütünlüğünü, mobil öncelikli responsive düzeni ve `DesignSystem.Colors.accent` temasını korur.
3. **🏷️ Zorunlu Commit Başlığı (`Ajan Ofisi`):**
   - Sanal ofis ajanlarının yaptığı tüm commit mesajlarında mutlaka **`Ajan Ofisi:`** başlığı yer almalıdır.
   - Commit gövdesinde hangi ajanın hangi değişikliği yaptığı ve Xcode Simülatör test sonucu açıkça yazılmalıdır.
