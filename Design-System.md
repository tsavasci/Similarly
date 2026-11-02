# Similarly — Tasarım Sistemi (Design System)

Bu doküman, **Similarly** iOS uygulamasının görsel dilini, renk paletini, kategori ve skor renk kodlamasını, tipografi ölçeğini, boşluk (spacing) ve ızgara (grid) kurallarını, köşe yuvarlaklıklarını ve yeniden kullanılabilir bileşen standartlarını gerçek SwiftUI kod tabanına dayanarak sabitler.

> **Kaynak Dosyalar:**
> - [MainView.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/MainView.swift)
> - [SimilarPhotosListView.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/SimilarPhotosListView.swift)
> - [PhotoComparisonView.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/PhotoComparisonView.swift)
> - [QualityIssuesView.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/QualityIssuesView.swift)
> - [MediaLibraryView.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/MediaLibraryView.swift)
> - [CleanCelebrationView.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/CleanCelebrationView.swift)
> - [OnboardingView.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/OnboardingView.swift)
> - [SettingsView.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/SettingsView.swift)
> - [L10n.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Utilities/L10n.swift)

---

## 1. Tasarım İlkeleri

1. **Net Kategori Kodlaması (Semantic Color Coding):** Kullanıcının binlerce fotoğraf arasında hangi grupta veya kalite sorununda olduğunu anında ayırt edebilmesi için her kategori (Kopyalar, Ekran Görüntüleri, Benzerler, Bulanık, Karanlık, Parlak, Video, Live Photo) kendine özgü sabit bir sistem rengi ve SF Symbol ikonu ile temsil edilir.
2. **Favori Koruması Önceliği (Favorite Safety First):** Favori fotoğraflar (`photo.isFavorite == true`) hiçbir ekranda silinmek üzere seçilemez; görsel olarak **Sarı (`Color.yellow`)** çerçeve (`3–4 pt`), sol üst yıldız rozeti (`star.fill`) ve seçim ekranlarında `%70` opaklık ile korunur.
3. **Karanlık ve Aydınlık Mod Uyumu (Adaptive System Surfaces):** Arka planlarda `Color(UIColor.systemBackground)`, kart ve ikincil buton yüzeylerinde dinamik opaklıklı nötr katmanlar (`Color.gray.opacity(0.08..0.20)`) ve kategori vurgularında `color.opacity(0.10)` kullanılarak hem Aydınlık hem Karanlık modda yüksek kontrast korunur.
4. **Çok Dilli Esnek Yerleşim (8-Language Resilient Layout):** Uygulama Türkçe, İngilizce, Arapça (RTL), Çince, Japonca, Almanca, Fransızca ve İspanyolca dillerini destekler. Yan yana duran aksiyon butonlarında ve grup bilgi satırlarında metin taşmasını önlemek için `.lineLimit(1)` ve `.minimumScaleFactor(0.7..0.8)` standart olarak uygulanır.

---

## 2. Renk Sistemi (Color Palette)

### 2.1. Marka ve Birincil Aksiyon Gradyanları

| Kullanım Yeri | Başlangıç → Bitiş Rengi | Yön (`LinearGradient`) | Kaynak |
| :--- | :--- | :--- | :--- |
| **Ana Logo & Birincil CTA Butonu** (`Benzer Fotoğrafları Bul`, `Tamam`) | `.blue` → `.purple` | `.topLeading` → `.bottomTrailing` (Logo) / `.leading` → `.trailing` (Buton) | [MainView.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/MainView.swift#L47-L51), [CleanCelebrationView.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/CleanCelebrationView.swift#L136-L140) |
| **Kutlama İkonu & Hale Efekti** (`CleanCelebrationView`) | `.green` → `.blue` (Hale: `.green.opacity(0.2)` → `.blue.opacity(0.1)`) | `.topLeading` → `.bottomTrailing` | [CleanCelebrationView.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/CleanCelebrationView.swift#L35-L53) |
| **Onboarding Sayfa 1** (`Benzer Fotoğrafları Bul`) | `.blue` → `.purple` | `.topLeading` → `.bottomTrailing` | [OnboardingView.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/OnboardingView.swift#L26) |
| **Onboarding Sayfa 2** (`Akıllı Analiz`) | `.purple` → `.pink` | `.topLeading` → `.bottomTrailing` | [OnboardingView.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/OnboardingView.swift#L32) |
| **Onboarding Sayfa 3** (`Kolay Seçim`) | `.pink` → `.orange` | `.topLeading` → `.bottomTrailing` | [OnboardingView.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/OnboardingView.swift#L38) |
| **Onboarding Sayfa 4** (`Alan Kazanın`) | `.orange` → `.red` | `.topLeading` → `.bottomTrailing` | [OnboardingView.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/OnboardingView.swift#L44) |

### 2.2. Kategori, Kalite ve Durum Renkleri

| Kategori / Durum | Renk Tokenı | Arka Plan Tonu (Banner/Kart) | İkon (`SF Symbols`) | Kullanım Yeri |
| :--- | :--- | :--- | :--- | :--- |
| **Kopyalar (Duplicates)** | `.red` | Sistem Liste / Bölüm Başlığı | `doc.on.doc.fill` | `SimilarPhotosListView` kopya grubu başlığı ve özeti |
| **Ekran Görüntüleri (Screenshots)** | `.orange` | Sistem Liste / Bölüm Başlığı | `camera.viewfinder` | `SimilarPhotosListView` ekran görüntüsü grupları |
| **Benzer Fotoğraflar (Similar)** | `.blue` | `Color.blue.opacity(0.1..0.2)` | `square.stack.3d.up.fill` | `SimilarPhotosListView`, karşılaştırma ve seçim vurguları |
| **Kalite — Bulanık (`blurry`)** | `.orange` | `Color.orange.opacity(0.1)` | `eye.slash.fill` | `QualityIssuesView` Sekme 0 ve `SettingsView` bulanıklık slider'ı |
| **Kalite — Karanlık (`dark`)** | `.purple` | `Color.purple.opacity(0.1)` | `moon.fill` | `QualityIssuesView` Sekme 1 ve `SettingsView` karanlık slider'ı |
| **Kalite — Parlak (`bright`)** | `.yellow` | `Color.yellow.opacity(0.1)` | `sun.max.fill` | `QualityIssuesView` Sekme 2 ve `SettingsView` parlaklık slider'ı |
| **Medya — Videolar (`video`)** | `.blue` | `Color.blue.opacity(0.1)` | `video.fill` / `film.stack` | `MediaLibraryView` Sekme 0 ve video rozetleri |
| **Medya — Live Photos (`livePhoto`)** | `.purple` | `Color.purple.opacity(0.1)` | `livephoto` | `MediaLibraryView` Sekme 1 ve Live Photo rozetleri |
| **Kazanılan Alan / Başarı** | `.green` | `Color.green` / `.opacity(0.2)` | `internaldrive.fill` / `checkmark.circle.fill` | `StatCard` tasarruf kartı, `CleanCelebrationView`, "Sorun Yok" butonu |
| **Silme / Yıkıcı Eylem** | `.red` (Pasifken `.gray`) | Katı `Color.red` | `trash.fill` / `trash.circle.fill` | Seçilen fotoğrafları silme butonları |
| **Favori Koruması** | `.yellow` | `Color.yellow.opacity(0.1)` | `star.fill` | Favori bilgi kutusu, küçük resim çerçevesi ve yıldız rozeti |

### 2.3. Benzerlik Skoru Renk Skalası ([`SimilarGroupRow.getScoreColor`](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/SimilarPhotosListView.swift#L540-L547))

Her grup satırının sağ tarafında gösterilen yüzde benzerlik oranı (`%98` vb.) skora göre dinamik renk alır:
- **`0.90 ... 1.00` (%90–%100):** `.green` (`Birebir aynı` / `Neredeyse aynı` / `Çok benzer`)
- **`0.80 ..< 0.90` (%80–%89):** `.blue` (`Çok benzer` / `Benzer`)
- **`0.70 ..< 0.80` (%70–%79):** `.orange` (`Benzer`)
- **`< 0.70` (<%70):** `.red` (`Az benzer`)

---

## 3. Tipografi Ölçeği

Uygulama genelinde Apple'ın sistem yazı tipi (**SF Pro**) ve dinamik metin stilleri kullanılır:

| Stil / Tanım | Boyut & Ağırlık | Renk | Kullanım Yeri |
| :--- | :--- | :--- | :--- |
| **Onboarding Başlığı** | `.system(size: 32, weight: .bold)` | `.white` | [`OnboardingPageView`](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/OnboardingView.swift#L193) ana sayfa başlığı |
| **Uygulama Ana Başlığı** | `.largeTitle` + `.bold` | `.primary` | [`MainView`](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/MainView.swift#L55-L56) uygulama adı (`Similarly`) |
| **Kutlama Başlığı** | `.system(size: 28, weight: .bold)` | `.primary` | [`CleanCelebrationView`](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/CleanCelebrationView.swift#L61) ana tebrik başlığı |
| **Grup Benzerlik Yüzdesi** | `.system(size: 24, weight: .bold)` | Skor Rengi | [`SimilarGroupRow`](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/SimilarPhotosListView.swift#L499) sağ yüzde göstergesi |
| **Ekran / Bölüm Başlığı** | `.title2` + `.bold` | `.primary` | `SimilarPhotoDetailView`, `PhotoComparisonView`, `QualityIssuesView`, `MediaLibraryView` üst başlıkları ve `CleanCelebrationView` metrik değerleri |
| **İstatistik Değeri** | `.title3` + `.semibold` | `.primary` | [`StatCard`](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/MainView.swift#L273-L274) sayaç ve boyut değerleri |
| **Grup & Bölüm Alt Başlığı** | `.headline` | `.primary` / Kategori Rengi | Liste özet satırları, `ProcessingOverlay` başlığı, ayar profili başlıkları |
| **Açıklama & Alt Metin** | `.subheadline` | `.secondary` | Ekran alt başlıkları, seçim sayaçları (`Seçilen: 3 fotoğraf`) |
| **Kart Etiketi & İpucu** | `.caption` | `.secondary` | `StatCard` üst etiketi, `PhotoComparisonView` ipucu çubuğu, ayar açıklamaları |
| **Fotoğraf Metadata Etiketi** | `.caption2` | `.secondary` | Küçük resim altındaki tarih, çözünürlük (`4032×3024`), video süresi ve dosya boyutu |

---

## 4. Boşluk (Spacing), Izgara (Grid) ve Köşe Yuvarlaklığı Kuralları

### 4.1. Boşluk ve Dolgu (Spacing & Padding)
- **Ana Ekran (`MainView`):** Üst logo boşluğu `padding(.top, 50)`, ana bölümler arası `VStack(spacing: 30)`, `StatCard` listesi `VStack(spacing: 15)`, alt aksiyon butonları yatay `padding(.horizontal, 30)` ve alt `padding(.bottom, 50)`.
- **Liste Satırları (`SimilarGroupRow`):** Dikey iç dolgu `12 pt`, yatay `16 pt`; `List` satır girintileri `EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 16)`.
- **Alt Kontrol Çubukları (`PhotoComparisonView`, `QualityPhotoGrid`, `MediaPhotoGrid`):** Yatay `16 pt`, dikey `16 pt` dolgu, `Color(UIColor.systemBackground)` zemin ve üst sınırda `shadow(color: .black.opacity(0.1), radius: 5, y: -2)` ayrım gölgesi.

### 4.2. Fotoğraf Izgarası (Grid) Standartları

| Ekran / Bileşen | Sütun Yapısı (`LazyVGrid`) | Hücre Boyutu | Hücre Aralığı (`spacing`) | Görüntü Yükleme Gecikmesi |
| :--- | :--- | :--- | :--- | :--- |
| **`SimilarGroupRow` (Önizleme Şeridi)** | Yatay `HStack` (İlk 3 fotoğraf) | Sabit `80 × 80 pt` | `8 pt` | `0.15 sn` (`80 * displayScale`) |
| **`SimilarPhotoDetailView` (`PhotoGridItem`)** | 2 sabit sütun (`GridItem(.fixed(cellWidth))`) | Dinamik kare (`max(75, floor((width - 44) / 2))`) | Yatay `12 pt`, Dikey `15 pt` | `0.15 sn` (`cellSize * displayScale`) |
| **`PhotoComparisonView` (`ComparisonPhotoCard`)** | 2 esnek sütun (`GridItem(.flexible(minimum: 150))`) | `aspectRatio(1, contentMode: .fit)` kare | `12 pt` | `0.15 sn` (`150 * displayScale`) |
| **`QualityIssuesView` (`QualityPhotoItem`)** | 3 esnek sütun (`GridItem(.flexible(minimum: 100))`) | Sabit `110 × 110 pt` | Yatay `8 pt`, Dikey `12 pt` | `0.10 sn` (`110 * displayScale`) |
| **`MediaLibraryView` (`MediaPhotoItem`)** | 3 esnek sütun (`GridItem(.flexible(minimum: 100))`) | `aspectRatio(1, contentMode: .fit)` kare | Yatay `8 pt`, Dikey `12 pt` | `0.15 sn` (`100 * displayScale`) |

### 4.3. Köşe Yuvarlaklığı (`cornerRadius`)

| Bileşen | Köşe Yuvarlaklığı |
| :--- | :--- |
| Küçük Butonlar & Favori Uyarı Kutusu (`ProcessingOverlay` İptal, `favorite_protected`) | `8 pt` |
| Standart Kartlar, Tüm Fotoğraf Hücreleri ve Alt Aksiyon Butonları (`StatCard`, `PhotoGridItem`, `ComparisonPhotoCard`, `QualityPhotoItem`, `MediaPhotoItem`) | `12 pt` |
| Kutlama Ekranı Butonları (`CleanCelebrationView`) | `14 pt` |
| Ana Ekran & Onboarding Birincil CTA Butonları (`MainView`, `OnboardingView`) | `15 pt` |
| Kutlama Tasarruf Özeti Kartı (`CleanCelebrationView`) | `16 pt` |
| İşlem Katmanı Kutusu (`ProcessingOverlay`) | `20 pt` |
| Rozetler (Favori yıldızı, Seçim tiki, Medya türü ikonu) | `Circle()` |

---

## 5. Temel Bileşen Kütüphanesi (Component Catalog)

### 5.1. `StatCard` ([MainView.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/MainView.swift#L255-L283))
Ana ekranda toplam fotoğraf, benzer grup sayısı, temizlenebilir fotoğraf adedi ve potansiyel alan tasarrufunu gösteren yatay bilgi kartıdır.
- **Yapı:** Sol tarafta `50 pt` genişliğinde çerçevede `30 pt` renkli SF Symbol ikonu, sağında `caption` başlık ve `title3.semibold` değer, `Color.gray.opacity(0.1)` arka plan ve `12 pt` köşe yuvarlaklığı.

### 5.2. `ProcessingOverlay` ([MainView.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/MainView.swift#L286-L331))
Fotoğraf kütüphanesi taranırken veya benzerlik analizi çalışırken ekranı kaplayan yarı saydam ilerleme katmanıdır.
- **Yapı:** Tam ekran `Color.black.opacity(0.4)` karartma üzerinde `30 pt` dolgulu, `20 pt` köşe yuvarlaklıklı `Color.black.opacity(0.8)` kutu; `1.5x` ölçekli beyaz dönen `ProgressView`, `200 pt` genişliğinde doğrusal ilerleme çubuğu, yerel yüzde metni (`L10n.percent(progress)`) ve opsiyonel `İptal` butonu içerir.

### 5.3. `SimilarGroupRow` & `GroupRowThumbnail` ([SimilarPhotosListView.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/SimilarPhotosListView.swift#L388-L548))
Benzer, kopya veya ekran görüntüsü gruplarını listede özetleyen satır bileşenidir.
- **Sol Bölüm:** Üstte grup içindeki fotoğraf adedi (`3 kopya` / `4 fotoğraf`), nokta ayırıcı (`•`), sözel benzerlik derecesi (`Birebir aynı`, `Çok benzer`) ve grupta favori varsa sarı yıldızlı `Favori` etiketi; altında temsilci fotoğrafın tarihi ve ilk 3 fotoğrafın `80×80 pt` boyutlu `GroupRowThumbnail` önizlemesi.
- **Sağ Bölüm:** En az `55 pt` genişliğinde, skora göre renklendirilmiş `24 pt` kalın yüzde skoru ve altında `benzer` alt etiketi.

### 5.4. `PhotoGridItem` & `ComparisonPhotoCard` ([SimilarPhotosListView.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/SimilarPhotosListView.swift#L810-L912), [PhotoComparisonView.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/PhotoComparisonView.swift#L225-L357))
Grup detayında ve yan yana karşılaştırma ekranında kullanılan etkileşimli fotoğraf kartlarıdır.
- **Etkileşim:**
  - **Tek Dokunuş (`onTapGesture`):** Favori değilse fotoğrafı silme listesine ekler veya çıkarır. Seçildiğinde sağ üstte beyaz dairesel zemin üzerinde mavi `checkmark.circle.fill` rozeti ve `3 pt` mavi kenarlık (`Color.blue`) belirir.
  - **Uzun Basış (`onLongPressGesture`):** `UIImpactFeedbackGenerator(style: .medium)` titreşimi verir; grup detayında `PhotoComparisonView`'ı, karşılaştırma ve kalite/medya ekranlarında ise tam ekran [`FullImageView`](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/SimilarPhotosListView.swift#L915-L1004) önizlemesini açar.
- **Zengin Metadata (`ComparisonPhotoCard`):** Fotoğrafın altında çekim tarihi (`calendar`), dosya boyutu (`doc`), bulanıksa turuncu `Bulanık` uyarısı (`eye.slash`) ve piksel çözünürlüğü (`arrow.up.left.and.arrow.down.right`) gösterilir.

### 5.5. `CleanCelebrationView` ([CleanCelebrationView.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Views/CleanCelebrationView.swift#L11-L159))
Silme işlemi tamamlandığında `.sheet` olarak açılan, pozitif geri bildirim ve organik paylaşım (viral growth) sağlayan kutlama ekranıdır.
- **Animasyon:** Açılışta `.spring(response: 0.6, dampingFraction: 0.7)` ile büyüyen `sparkles` ikonu ve arka planda `1.5 sn` periyotla nefes alan (`scaleEffect(1.05 <-> 0.95)`) yeşil-mavi gradyan daire.
- **Tasarruf Kartı:** Sol sütunda yeşil renkle açılan depolama alanı (`L10n.bytes(savedBytes)`), ortada `40 pt` dikey `Divider()`, sağ sütunda mavi renkle temizlenen fotoğraf adedi.
- **Aksiyonlar:** Üstte `UIActivityViewController` (`ShareSheet`) tetikleyen açık mavi `Başarını Paylaş` butonu, altta mavi-mor gradyanlı `Tamam` butonu.

---

## 6. İkonografi ve Yerelleştirilmiş Biçimlendirme (`L10n`)

### 6.1. SF Symbols İkon Sözlüğü
- **Marka & Analiz:** `photo.stack.fill`, `photo.stack`, `sparkles`, `photo.on.rectangle.angled`, `square.on.square`
- **Kategoriler:** `doc.on.doc.fill` (Kopyalar), `camera.viewfinder` (Ekran Görüntüleri), `square.stack.3d.up.fill` (Benzerler), `video.fill` / `film.stack` (Videolar), `livephoto` (Live Photos)
- **Kalite Sorunları:** `exclamationmark.triangle.fill` (Genel Kalite), `eye.slash.fill` (Bulanık), `moon.fill` (Karanlık), `sun.max.fill` (Parlak)
- **Aksiyon & Durum:** `trash.fill`, `trash.circle.fill`, `checkmark.circle.fill`, `checkmark.circle`, `circle`, `star.fill`, `clock.arrow.circlepath` (En Eskileri Seç), `arrow.left.and.right.square` (Karşılaştır), `square.and.arrow.up` (Paylaş), `xmark.circle.fill` (Kapat)
- **Ayarlar Profilleri:** `scope` (Hassas), `slider.horizontal.3` (Dengeli), `wand.and.stars` (Esnek)

### 6.2. Birleşik Yerel Ayar Biçimlendirmesi ([L10n.swift](file:///Users/tamersavasci/Documents/Similarly/Similarly/Utilities/L10n.swift#L76-L102))
Aynı ekranda farklı rakam sistemlerinin (ör. Arapça metin içinde Batı rakamları veya tersi) karışmasını önlemek için tüm sayı, boyut, tarih ve yüzde değerleri `L10n.appLocale` (`<dil_kodu>_<cihaz_bölgesi>`) üzerinden biçimlendirilir:
- **Sayılar:** `L10n.number(_:)` → `.number.locale(appLocale)`
- **Dosya Boyutları:** `L10n.bytes(_:)` → `.byteCount(style: .file).locale(appLocale)`
- **Tarihler:** `L10n.date(_:time:)` → `Date.FormatStyle(date: .numeric, time: time).locale(appLocale)`
- **Yüzdeler:** `L10n.percent(_:)` → `.percent.precision(.fractionLength(0)).locale(appLocale)` (`%98`, `98 %`, `٩٨٪`)
