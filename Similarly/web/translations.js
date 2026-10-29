//
//  translations.js
//  Similarly - Multilingual dictionary supporting 8 languages
//  en, tr, de, es, fr, ja, zh-Hans, ar
//

const translations = {
  en: {
    dir: "ltr",
    langName: "English",
    flag: "🇺🇸",
    nav: {
      features: "Features",
      faq: "FAQ",
      privacy: "Privacy Policy",
      download: "Download"
    },
    hero: {
      badge: "✨ On-Device AI Photo Cleaner",
      title1: "Clear the Clutter,",
      titleGradient: "Keep Best Memories",
      subtitle: "Similarly detects similar burst shots, duplicate photos, and blurry images with 100% on-device Apple Vision AI. Reclaim valuable iPhone storage in seconds.",
      explore: "Explore Features",
      statsAccuracy: "99% Accuracy",
      statsSpeed: "10x Faster",
      statsPrivacy: "100% On-Device",
      statsStorage: "Gigabytes Saved"
    },
    stats: {
      item1Val: "100%",
      item1Lbl: "Private & On-Device",
      item2Val: "0 MB",
      item2Lbl: "Cloud Data Uploaded",
      item3Val: "10x",
      item3Lbl: "Faster Vision AI",
      item4Val: "∞",
      item4Lbl: "Photos Supported"
    },
    features: {
      badge: "Features",
      title: "Why Choose Similarly?",
      subtitle: "The fastest, safest, and smartest way to organize your iPhone camera roll.",
      f1Title: "Similar Photo Detection",
      f1Desc: "Instantly groups burst shots, repeated poses, and identical angles. Keeps the sharpest shot and cleans the rest.",
      f2Title: "Exact Duplicate Remover",
      f2Desc: "Finds identical photo copies, repeated message saves, and identical screenshots to free up storage.",
      f3Title: "Blurry & Low-Quality Finder",
      f3Desc: "Automatically detects out-of-focus, underexposed dark photos, or blown-out highlights.",
      f4Title: "Live Storage Savings",
      f4Desc: "Calculates the exact amount of megabytes and gigabytes you can safely reclaim before deleting anything.",
      f5Title: "100% On-Device Privacy",
      f5Desc: "Powered by Apple Vision framework. All processing stays local on your iPhone. Zero cloud uploads, zero telemetry.",
      f6Title: "PhotoKit Safe Deletion",
      f6Desc: "Uses Apple PhotoKit with full user confirmation. Photos move to the 'Recently Deleted' album for safe recovery."
    },
    faq: {
      badge: "FAQ",
      title: "Frequently Asked Questions",
      subtitle: "Everything you need to know about Similarly.",
      q1: "Are my photos uploaded to any external server?",
      a1: "Never. Similarly runs 100% locally on your iPhone using Apple's Neural Engine and Vision framework. No photo, thumbnail, or metadata ever leaves your device.",
      q2: "Can I recover accidentally deleted photos?",
      a2: "Yes! Deleted photos are moved to the standard iOS 'Recently Deleted' album in the Photos app, where you can restore them within 30 days.",
      q3: "Does Similarly require an internet connection?",
      a3: "No, Similarly works completely offline and even in Airplane Mode.",
      q4: "How does it detect similar photos?",
      a4: "Similarly uses Vision FeaturePrint vector analysis, capturing visual patterns, textures, and compositions rather than simple file hashes."
    },
    cta: {
      title: "Ready to Clean Your Camera Roll?",
      subtitle: "Download Similarly for free today and reclaim gigabytes of precious iPhone storage in minutes.",
      button: "Download on App Store"
    },
    footer: {
      desc: "The smartest, privacy-first similar & duplicate photo cleaner for iOS. Made with ❤️ in Turkey.",
      product: "Product",
      legal: "Legal",
      privacy: "Privacy Policy",
      terms: "Terms of Use",
      rights: "© 2025 Similarly. All rights reserved."
    },
    privacyPage: {
      title: "Privacy Policy",
      subtitle: "Your privacy is our highest priority",
      lastUpdated: "Last Updated: October 2025",
      intro: "This Privacy Policy describes our commitment to your privacy when using the Similarly application for iOS. Similarly is built from the ground up as a privacy-first, on-device utility.",
      boxHighlight: "🛡️ Core Principle: All image processing, similarity analysis, and categorization take place exclusively on your iPhone. Your photos, videos, and personal data NEVER leave your device.",
      h1: "1. Information We Access",
      p1: "Similarly requests permission to access your iOS Photo Library solely to scan, compare, and display similar or duplicate photos. We do not collect, transmit, store, or share your personal photos, EXIF data, or location metadata on any remote servers.",
      h2: "2. On-Device Image Processing",
      p2: "Image analysis is performed using Apple's Vision framework (FeaturePrint embeddings) entirely on your device's Neural Engine. Generated mathematical feature vectors are cached locally in your device's sandboxed SwiftData database and deleted when photos are removed.",
      h3: "3. Third-Party Analytics & Tracking",
      p3: "Similarly contains zero third-party tracking SDKs, zero ad networks, and zero telemetry frameworks. We do not track your activity, your device ID, or your personal identity.",
      h4: "4. Your Rights & Photo Deletion",
      p4: "Whenever you choose to delete photos, Similarly utilizes Apple's official PhotoKit API, prompting a native iOS confirmation. Deleted items are safely relocated to Apple's 'Recently Deleted' album, allowing 30 days for easy recovery.",
      h5: "5. Contact Us",
      p5: "If you have any questions or feedback regarding this Privacy Policy, feel free to contact us at support@similarly.app.",
      backHome: "Back to Home"
    }
  },

  tr: {
    dir: "ltr",
    langName: "Türkçe",
    flag: "🇹🇷",
    nav: {
      features: "Özellikler",
      faq: "Sıkça Sorulanlar",
      privacy: "Gizlilik Politikası",
      download: "İndir"
    },
    hero: {
      badge: "✨ Cihaz İçi Yapay Zeka Fotoğraf Temizleyici",
      title1: "Fazlalıklardan Kurtulun,",
      titleGradient: "Anılarınıza Yer Açın",
      subtitle: "Similarly, %100 cihaz üzerinde çalışan Apple Vision yapay zekası ile seri çekimleri, kopya fotoğrafları ve bulanık kareleri anında tespit eder. iPhone'unuzda saniyeler içinde gigabaytlarca alan açın.",
      explore: "Özellikleri Keşfet",
      statsAccuracy: "%99 Doğruluk",
      statsSpeed: "10x Daha Hızlı",
      statsPrivacy: "%100 Cihaz İçi",
      statsStorage: "Gigabaytlarca Tasarruf"
    },
    stats: {
      item1Val: "%100",
      item1Lbl: "Cihaz İçi Gizlilik",
      item2Val: "0 MB",
      item2Lbl: "Buluta Yüklenen Veri",
      item3Val: "10x",
      item3Lbl: "Daha Hızlı Vision AI",
      item4Val: "∞",
      item4Lbl: "Fotoğraf Desteği"
    },
    features: {
      badge: "Özellikler",
      title: "Neden Similarly?",
      subtitle: "iPhone fotoğraf arşivinizi organize etmenin en hızlı, güvenli ve akıllı yolu.",
      f1Title: "Akıllı Benzer Fotoğraf Tespiti",
      f1Desc: "Seri çekimleri, benzer pozları ve aynı açıdan çekilmiş fotoğrafları otomatik gruplar. En net kareyi koruyup diğerlerini temizler.",
      f2Title: "Birebir Kopya Temizleyici",
      f2Desc: "Aynı fotoğraf kopyalarını, mükerrer mesaj kayıtlarını ve duplikat ekran görüntülerini tespit ederek depolama alanı kazandırır.",
      f3Title: "Bulanık & Kusurlu Fotoğraf Bulucu",
      f3Desc: "Odak dışı bulanık, detayları kaybolmuş karanlık veya aşırı parlak pozlanmış fotoğrafları kolayca ayıklar.",
      f4Title: "Canlı Depolama Tasarrufu",
      f4Desc: "Silme işleminden önce tam olarak ne kadar megabayt ve gigabayt tasarruf edeceğinizi anlık olarak hesaplar.",
      f5Title: "%100 Cihaz İçi Gizlilik",
      f5Desc: "Apple Vision motoru ile çalışır. Tüm analizler telefonunuzun kendi işlemcisinde yapılır. Fotoğraflarınız asla cihazınızdan çıkmaz.",
      f6Title: "PhotoKit ile Güvenli Silme",
      f6Desc: "Apple PhotoKit güvencesiyle silinen fotoğraflar 'Son Silinenler' albümüne taşınır; 30 gün boyunca kolayca geri kurtarılabilir."
    },
    faq: {
      badge: "SSS",
      title: "Sıkça Sorulan Sorular",
      subtitle: "Similarly hakkında merak ettiğiniz her şey.",
      q1: "Fotoğraflarım herhangi bir sunucuya yükleniyor mu?",
      a1: "Kesinlikle hayır. Similarly %100 yerel olarak iPhone'unuzun Neural Engine ve Apple Vision çerçevesini kullanır. Hiçbir fotoğraf veya bilgi cihazınızdan dışarı çıkmaz.",
      q2: "Yanlışlıkla sildiğim bir fotoğrafı geri getirebilir miyim?",
      a2: "Evet! Silinen fotoğraflar iOS'un yerleşik 'Son Silinenler' albümüne taşınır. 30 gün içinde dilediğiniz zaman tek dokunuşla geri yükleyebilirsiniz.",
      q3: "Similarly internet bağlantısı gerektirir mi?",
      a3: "Hayır, Similarly tamamen çevrimdışı (offline) ve hatta Uçak Modu açıkken bile kusursuz çalışır.",
      q4: "Benzer fotoğrafları nasıl tespit ediyor?",
      a4: "Similarly, basit dosya boyutuna değil; Apple Vision FeaturePrint vektör analizi ile görsel doku, kompozisyon ve sahne benzerliğine bakar."
    },
    cta: {
      title: "Galerinizi Temizlemeye Hazır Mısınız?",
      subtitle: "Similarly'yi App Store'dan ücretsiz indirin ve dakikalar içinde telefonunuzda gigabaytlarca yer açın.",
      button: "App Store'dan İndir"
    },
    footer: {
      desc: "iOS için yapay zeka destekli, gizlilik odaklı benzer ve kopya fotoğraf temizleyicisi. Made with ❤️ in Turkey.",
      product: "Ürün",
      legal: "Yasal",
      privacy: "Gizlilik Politikası",
      terms: "Kullanım Koşulları",
      rights: "© 2025 Similarly. Tüm hakları saklıdır."
    },
    privacyPage: {
      title: "Gizlilik Politikası",
      subtitle: "Gizliliğiniz bizim en temel ilkemizdir",
      lastUpdated: "Son Güncelleme: Ekim 2025",
      intro: "Bu Gizlilik Politikası, iOS için geliştirilen Similarly uygulamasının gizliliğinizi nasıl koruduğunu açıklar. Similarly, gizlilik öncelikli ve cihaz içi çalışan bir araç olarak tasarlanmıştır.",
      boxHighlight: "🛡️ Temel Prensip: Tüm görüntü analizi, benzerlik tespiti ve kategorizasyon işlemleri yalnızca iPhone'unuzda gerçekleşir. Fotoğraflarınız, videolarınız veya kişisel verileriniz ASLA sunucularımıza gönderilmez.",
      h1: "1. Erişilen Bilgiler",
      p1: "Similarly, yalnızca benzer ve kopya fotoğrafları taramak, karşılaştırmak ve gruplamak amacıyla iOS Fotoğraf Kütüphanenize erişim izni ister. Fotoğraflarınız, EXIF verileriniz veya konum bilgileriniz hiçbir uzak sunucuya aktarılmaz ve depolanmaz.",
      h2: "2. Cihaz İçi Görüntü Analizi",
      p2: "Görüntü benzerlik analizi, Apple'ın Vision framework'ü (FeaturePrint vektörleri) kullanılarak doğrudan cihazınızın Neural Engine donanımında gerçekleştirilir. Oluşturulan matematiksel vektörler cihazınızın yerel SwiftData veritabanında saklanır ve fotoğraflar silindiğinde silinir.",
      h3: "3. Üçüncü Taraf Takip ve Analizler",
      p3: "Similarly uygulamasında hiçbir üçüncü taraf reklam ağı, takip SDK'sı veya telemetri kütüphanesi bulunmaz. Cihaz kimliğiniz veya kişisel kimliğiniz asla izlenmez.",
      h4: "4. Kullanıcı Hakları ve Güvenli Silme",
      p4: "Silme işlemlerinde Apple'ın resmi PhotoKit API'si kullanılır ve silme işlemi iOS sistem onayı ile yapılır. Silinen fotoğraflar 'Son Silinenler' albümüne taşınarak 30 gün boyunca güvenle geri kurtarılabilir.",
      h5: "5. İletişim",
      p5: "Gizlilik Politikamızla ilgili her türlü soru veya öneriniz için support@similarly.app adresinden bize ulaşabilirsiniz.",
      backHome: "Ana Sayfaya Dön"
    }
  },

  de: {
    dir: "ltr",
    langName: "Deutsch",
    flag: "🇩🇪",
    nav: {
      features: "Funktionen",
      faq: "FAQ",
      privacy: "Datenschutz",
      download: "Laden"
    },
    hero: {
      badge: "✨ Lokale KI-Fotobereinigung",
      title1: "Galerie Aufräumen,",
      titleGradient: "Speicherplatz Schaffen",
      subtitle: "Similarly erkennt ähnliche Serienbilder, Duplikate und unscharfe Fotos mit 100% lokaler Apple Vision KI. Gewinnen Sie in Sekundenschnelle wertvollen iPhone-Speicher zurück.",
      explore: "Funktionen Entdecken",
      statsAccuracy: "99% Genauigkeit",
      statsSpeed: "10x Schneller",
      statsPrivacy: "100% Lokal",
      statsStorage: "Gigabytes Gespart"
    },
    stats: {
      item1Val: "100%",
      item1Lbl: "Privat auf dem Gerät",
      item2Val: "0 MB",
      item2Lbl: "Cloud-Uploads",
      item3Val: "10x",
      item3Lbl: "Schnellere Vision KI",
      item4Val: "∞",
      item4Lbl: "Fotos Unterstützt"
    },
    features: {
      badge: "Funktionen",
      title: "Warum Similarly?",
      subtitle: "Der schnellste, sicherste und intelligenteste Weg, Ihre iPhone-Mediathek aufzuräumen.",
      f1Title: "Ähnliche Fotos Erkennen",
      f1Desc: "Gruppiert Serienaufnahmen und ähnliche Posen automatisch. Behält die schärfste Aufnahme und bereinigt den Rest.",
      f2Title: "Duplikate Entfernen",
      f2Desc: "Findet identische Kopien, doppelte Bildschirmfotos und Downloads, um Speicherplatz freizugeben.",
      f3Title: "Unscharfe Fotos Aufspüren",
      f3Desc: "Erkennt automatisch verwackelte, zu dunkle oder überbelichtete Aufnahmen.",
      f4Title: "Echtzeit-Speicherersparnis",
      f4Desc: "Berechnet vor dem Löschen genau, wie viele Megabytes und Gigabytes Sie einsparen können.",
      f5Title: "100% Lokaler Datenschutz",
      f5Desc: "Basiert auf Apple Vision. Alle Prozesse laufen ausschließlich auf Ihrem iPhone. Keine Server, kein Tracking.",
      f6Title: "Sicheres Löschen mit PhotoKit",
      f6Desc: "Gelöschte Fotos werden in 'Zuletzt gelöscht' verschoben und können 30 Tage lang wiederhergestellt werden."
    },
    faq: {
      badge: "FAQ",
      title: "Häufig gestellte Fragen",
      subtitle: "Alles, was Sie über Similarly wissen müssen.",
      q1: "Werden meine Fotos auf externe Server geladen?",
      a1: "Niemals. Similarly arbeitet zu 100% lokal auf Ihrem iPhone mit Apples Neural Engine und Vision Framework. Keine Fotos verlassen Ihr Gerät.",
      q2: "Kann ich versehentlich gelöschte Fotos wiederherstellen?",
      a2: "Ja! Gelöschte Fotos landen im Album 'Zuletzt gelöscht' der Fotos-App und können innerhalb von 30 Tagen wiederhergestellt werden.",
      q3: "Funktioniert Similarly ohne Internetverbindung?",
      a3: "Ja, Similarly funktioniert komplett offline und sogar im Flugmodus.",
      q4: "Wie erkennt die App ähnliche Fotos?",
      a4: "Similarly nutzt Apple Vision FeaturePrint Vektoranalysen, um Bildkompositionen und visuelle Muster präzise zu vergleichen."
    },
    cta: {
      title: "Bereit für eine aufgeräumte Galerie?",
      subtitle: "Laden Sie Similarly kostenlos im App Store herunter und schaffen Sie sofort Platz für neue Erinnerungen.",
      button: "Im App Store laden"
    },
    footer: {
      desc: "Der intelligente, datenschutzfreundliche Duplikat- und Fotoreiniger für iOS. Made with ❤️ in Turkey.",
      product: "Produkt",
      legal: "Rechtliches",
      privacy: "Datenschutzerklärung",
      terms: "Nutzungsbedingungen",
      rights: "© 2025 Similarly. Alle Rechte vorbehalten."
    },
    privacyPage: {
      title: "Datenschutzerklärung",
      subtitle: "Ihre Privatsphäre steht an erster Stelle",
      lastUpdated: "Stand: Oktober 2025",
      intro: "Diese Datenschutzerklärung erläutert, wie Similarly für iOS Ihre Privatsphäre schützt. Die App wurde als datenschutzorientiertes On-Device-Tool entwickelt.",
      boxHighlight: "🛡️ Grundprinzip: Alle Bildanalysen, Ähnlichkeitsberechnungen und Sortierungen erfolgen ausschließlich auf Ihrem iPhone. Ihre Fotos verlassen niemals Ihr Gerät.",
      h1: "1. Zugriff auf Ihre Fotos",
      p1: "Similarly fordert nur Zugriff auf Ihre Mediathek an, um ähnliche und doppelte Fotos zu erkennen und zu sortieren. Wir übertragen, speichern oder analysieren keine Fotos auf externen Servern.",
      h2: "2. Lokale Bildverarbeitung",
      p2: "Die Bilderkennung basiert auf Apples Vision-Framework und der internen Neural Engine. Erstellte mathematische Vektoren werden lokal in der SwiftData-Datenbank auf Ihrem Gerät gespeichert.",
      h3: "3. Keine Tracker oder Werbung",
      p3: "Similarly enthält keinerlei Tracking-SDKs, Werbenetzwerke oder Telemetrie. Wir verfolgen weder Ihre Aktivitäten noch Ihre Identität.",
      h4: "4. Sicheres Löschen",
      p4: "Löschvorgänge nutzen die offizielle Apple PhotoKit API mit nativer Bestätigung. Gelöschte Fotos verbleiben 30 Tage lang im Album 'Zuletzt gelöscht'.",
      h5: "5. Kontakt",
      p5: "Bei Fragen zu dieser Datenschutzerklärung erreichen Sie uns unter support@similarly.app.",
      backHome: "Zur Startseite"
    }
  },

  es: {
    dir: "ltr",
    langName: "Español",
    flag: "🇪🇸",
    nav: {
      features: "Características",
      faq: "Preguntas",
      privacy: "Privacidad",
      download: "Descargar"
    },
    hero: {
      badge: "✨ Limpiador de Fotos con IA Local",
      title1: "Despeja tu Galería,",
      titleGradient: "Guarda lo Mejor",
      subtitle: "Similarly detecta fotos similares en ráfaga, duplicadas e imágenes borrosas con la IA local de Apple Vision al 100%. Recupera gigabytes en tu iPhone en segundos.",
      explore: "Ver Características",
      statsAccuracy: "99% Precisión",
      statsSpeed: "10x Más Rápido",
      statsPrivacy: "100% En el Dispositivo",
      statsStorage: "Gigabytes Liberados"
    },
    stats: {
      item1Val: "100%",
      item1Lbl: "Privado en el Dispositivo",
      item2Val: "0 MB",
      item2Lbl: "Datos a la Nube",
      item3Val: "10x",
      item3Lbl: "IA Vision Más Rápida",
      item4Val: "∞",
      item4Lbl: "Fotos Compatibles"
    },
    features: {
      badge: "Características",
      title: "¿Por Qué Elegir Similarly?",
      subtitle: "La forma más rápida, segura e inteligente de organizar las fotos de tu iPhone.",
      f1Title: "Detección de Fotos Similares",
      f1Desc: "Agrupa ráfagas y fotos repetidas en segundos. Conserva la toma más nítida y borra las demás con un solo toque.",
      f2Title: "Eliminación de Duplicadas",
      f2Desc: "Encuentra copias idénticas, descargas repetidas y capturas duplicadas para liberar espacio de inmediato.",
      f3Title: "Detector de Fotos Borrosas",
      f3Desc: "Identifica automáticamente fotos desenfocadas, oscuras o sobreexpuestas que malgastan espacio.",
      f4Title: "Ahorro de Espacio en Vivo",
      f4Desc: "Calcula con precisión los megabytes y gigabytes que recuperarás antes de eliminar cualquier archivo.",
      f5Title: "100% Privacidad en el Dispositivo",
      f5Desc: "Impulsado por Apple Vision. Todo el procesamiento se ejecuta localmente en tu iPhone. Cero subidas a la nube.",
      f6Title: "Eliminación Segura con PhotoKit",
      f6Desc: "Las fotos eliminadas se mueven al álbum 'Eliminado recientemente' de iOS para recuperarlas en 30 días si lo deseas."
    },
    faq: {
      badge: "Preguntas Frecuentes",
      title: "Preguntas Frecuentes",
      subtitle: "Todo lo que necesitas saber sobre Similarly.",
      q1: "¿Se suben mis fotos a algún servidor externo?",
      a1: "Nunca. Similarly funciona 100% en tu iPhone gracias al Neural Engine y Apple Vision. Ninguna foto ni dato sale de tu dispositivo.",
      q2: "¿Puedo recuperar una foto si la borro por error?",
      a2: "¡Sí! Las fotos eliminadas se envían al álbum 'Eliminado recientemente' de la app Fotos, donde puedes restaurarlas en 30 días.",
      q3: "¿Funciona Similarly sin conexión a internet?",
      a3: "Sí, Similarly funciona totalmente sin conexión e incluso con el Modo Avión activado.",
      q4: "¿Cómo detecta las fotos parecidas?",
      a4: "Utiliza el análisis vectorial FeaturePrint de Apple Vision para evaluar composición, texturas y formas visuales reales."
    },
    cta: {
      title: "¿Listo para Limpiar tu Carrete?",
      subtitle: "Descarga Similarly gratis en el App Store y recupera gigabytes de almacenamiento en pocos minutos.",
      button: "Descargar en el App Store"
    },
    footer: {
      desc: "El organizador y limpiador inteligente de fotos duplicadas para iOS, centrado en tu privacidad. Made with ❤️ in Turkey.",
      product: "Producto",
      legal: "Legal",
      privacy: "Política de Privacidad",
      terms: "Términos de Uso",
      rights: "© 2025 Similarly. Todos los derechos reservados."
    },
    privacyPage: {
      title: "Política de Privacidad",
      subtitle: "Tu privacidad es nuestra máxima prioridad",
      lastUpdated: "Última actualización: Octubre de 2025",
      intro: "Esta Política de Privacidad describe cómo Similarly para iOS protege tu información personal. La aplicación está diseñada bajo una filosofía 100% local.",
      boxHighlight: "🛡️ Principio Fundamental: Todo el análisis de imágenes y la detección de similitudes ocurren únicamente en tu iPhone. Tus fotos y vídeos NUNCA se envían a ningún servidor.",
      h1: "1. Información a la que Accedemos",
      p1: "Similarly solicita permiso de acceso a tu Fototeca solo para escanear y agrupar fotos similares y duplicadas. No transmitimos ni almacenamos tus fotos ni datos de ubicación en la nube.",
      h2: "2. Procesamiento Local",
      p2: "El análisis se realiza mediante Apple Vision en el chip Neural Engine de tu dispositivo. Los vectores matemáticos se guardan en una base de datos local y se eliminan junto con las fotos.",
      h3: "3. Cero Rastreadores y Publicidad",
      p3: "Similarly no incluye SDKs de terceros ni redes publicitarias ni herramientas de telemetría. Tu identidad está totalmente protegida.",
      h4: "4. Eliminación Segura",
      p4: "Usamos la API oficial de Apple PhotoKit con confirmación del sistema. Las fotos eliminadas van al álbum 'Eliminado recientemente' durante 30 días.",
      h5: "5. Contacto",
      p5: "Si tienes dudas sobre esta política, contáctanos en support@similarly.app.",
      backHome: "Volver al Inicio"
    }
  },

  fr: {
    dir: "ltr",
    langName: "Français",
    flag: "🇫🇷",
    nav: {
      features: "Fonctionnalités",
      faq: "FAQ",
      privacy: "Confidentialité",
      download: "Télécharger"
    },
    hero: {
      badge: "✨ Nettoyeur de Photos IA 100% Local",
      title1: "Désencombrez,",
      titleGradient: "Sublimez Votre Galerie",
      subtitle: "Similarly détecte les rafales similaires, les doublons et les photos floues grâce à l'IA embarquée Apple Vision. Récupérez des gigaoctets sur votre iPhone en quelques secondes.",
      explore: "Découvrir les Fonctions",
      statsAccuracy: "99% Précision",
      statsSpeed: "10x Plus Rapide",
      statsPrivacy: "100% Sur l'Appareil",
      statsStorage: "Gigaoctets Libérés"
    },
    stats: {
      item1Val: "100%",
      item1Lbl: "Privé sur l'Appareil",
      item2Val: "0 Mo",
      item2Lbl: "Données Envoyées",
      item3Val: "10x",
      item3Lbl: "Vision IA Accélérée",
      item4Val: "∞",
      item4Lbl: "Photos Prises en Charge"
    },
    features: {
      badge: "Fonctionnalités",
      title: "Pourquoi Choisir Similarly ?",
      subtitle: "La solution la plus rapide, sûre et intelligente pour organiser les photos de votre iPhone.",
      f1Title: "Détection des Photos Similaires",
      f1Desc: "Regroupe instantanément les séries de rafales et poses semblables. Garde le meilleur cliché et nettoie le reste.",
      f2Title: "Suppression des Doublons",
      f2Desc: "Repère les copies conformes, téléchargements en double et captures identiques pour libérer du stockage.",
      f3Title: "Tri des Photos Floues",
      f3Desc: "Isole automatiquement les clichés flous, sous-exposés ou avec une luminosité excessive.",
      f4Title: "Calcul du Gain d'Espace",
      f4Desc: "Estime avec précision l'espace disque exact que vous allez récupérer avant toute suppression.",
      f5Title: "100% Confidentialité Locale",
      f5Desc: "Propulsé par Apple Vision. Toutes les opérations se font en local sur votre iPhone. Aucun transfert cloud.",
      f6Title: "Suppression Sûre avec PhotoKit",
      f6Desc: "Les photos supprimées rejoignent l'album 'Supprimés récemment' d'iOS et restent récupérables pendant 30 jours."
    },
    faq: {
      badge: "FAQ",
      title: "Questions Fréquentes",
      subtitle: "Tout ce qu'il faut savoir sur Similarly.",
      q1: "Mes photos sont-elles téléchargées sur un serveur ?",
      a1: "Absolument pas. Similarly fonctionne à 100% localement sur votre iPhone grâce au Neural Engine d'Apple. Aucune photo ne quitte votre appareil.",
      q2: "Puis-je restaurer une photo supprimée par erreur ?",
      a2: "Oui ! Les éléments supprimés sont déplacés dans l'album 'Supprimés récemment' de l'app Photos, récupérables pendant 30 jours.",
      q3: "L'application nécessite-t-elle une connexion Internet ?",
      a3: "Non, Similarly fonctionne parfaitement hors ligne et même en mode Avion.",
      q4: "Comment Similarily trouve-t-il les photos semblables ?",
      a4: "L'application analyse la composition visuelle et les détails grâce aux vecteurs FeaturePrint d'Apple Vision."
    },
    cta: {
      title: "Prêt à Désencombrer Votre Galerie ?",
      subtitle: "Téléchargez Similarly gratuitement sur l'App Store et libérez des gigaoctets d'espace en quelques minutes.",
      button: "Télécharger sur l'App Store"
    },
    footer: {
      desc: "Le nettoyeur de photos similaires et doublons intelligent et respectueux de la vie privée sur iOS. Made with ❤️ in Turkey.",
      product: "Produit",
      legal: "Légal",
      privacy: "Politique de Confidentialité",
      terms: "Conditions d'Utilisation",
      rights: "© 2025 Similarly. Tous droits réservés."
    },
    privacyPage: {
      title: "Politique de Confidentialité",
      subtitle: "Votre vie privée est notre priorité absolue",
      lastUpdated: "Dernière mise à jour : Octobre 2025",
      intro: "Cette Politique de Confidentialité décrit comment Similarly pour iOS protège vos données. L'application est entièrement conçue pour fonctionner en local.",
      boxHighlight: "🛡️ Règle d'Or : Tout le traitement d'image et l'analyse de similarité ont lieu exclusivement sur votre iPhone. Vos photos et vidéos ne sont JAMAIS transmises à un serveur.",
      h1: "1. Accès à Vos Photos",
      p1: "Similarly demande l'autorisation d'accéder à votre photothèque iOS uniquement pour comparer et organiser les photos en doublon ou similaires. Nous ne transférons ni ne conservons aucune donnée externe.",
      h2: "2. Traitement d'Image Embarqué",
      p2: "Les calculs s'appuient sur le framework Vision d'Apple et la puce Neural Engine. Les données mathématiques temporaires restent dans votre stockage local sécurisé.",
      h3: "3. Aucun Traceur Tiers",
      p3: "Similarly n'intègre aucun SDK de suivi publicitaire ni outil d'analyse tiers. Votre identité et vos activités restent privées.",
      h4: "4. Suppression Sécurisée",
      p4: "Toutes les suppressions passent par l'API officielle PhotoKit d'Apple avec confirmation. Les fichiers vont dans l'album 'Supprimés récemment' pendant 30 jours.",
      h5: "5. Contact",
      p5: "Pour toute question relative à cette politique, écrivez-nous à support@similarly.app.",
      backHome: "Retour à l'Accueil"
    }
  },

  ja: {
    dir: "ltr",
    langName: "日本語",
    flag: "🇯🇵",
    nav: {
      features: "機能",
      faq: "よくある質問",
      privacy: "プライバシー",
      download: "ダウンロード"
    },
    hero: {
      badge: "✨ 完全端末内処理のAI写真クリーナー",
      title1: "写真整理をもっと手軽に、",
      titleGradient: "最高の瞬間だけを残す",
      subtitle: "Similarlyは、Apple Vision AIを活用し、端末内だけで類似した連写写真や重複・ピンボケ写真を瞬時に検出します。iPhoneの空き容量を今すぐ数ギガバイト解放しましょう。",
      explore: "機能を見る",
      statsAccuracy: "99% 精度",
      statsSpeed: "10倍 高速",
      statsPrivacy: "100% 端末内処理",
      statsStorage: "大容量を解放"
    },
    stats: {
      item1Val: "100%",
      item1Lbl: "端末内プライバシー",
      item2Val: "0 MB",
      item2Lbl: "クラウド送信データ",
      item3Val: "10倍",
      item3Lbl: "高速Vision AI",
      item4Val: "∞",
      item4Lbl: "写真対応枚数"
    },
    features: {
      badge: "機能紹介",
      title: "Similarlyが選ばれる理由",
      subtitle: "iPhoneの写真ライブラリを最も安全・高速・賢く整理できるアプリです。",
      f1Title: "類似写真の自動グループ化",
      f1Desc: "似たアングルや連写写真を瞬時にまとめます。最も鮮明な1枚をキープし、不要なショットを素早く削除。",
      f2Title: "完全重複写真の除去",
      f2Desc: "二重保存された同じ画像や重複スクリーンショットを検出し、無駄なストレージを解消します。",
      f3Title: "失敗写真（ブレ・暗さ）検出",
      f3Desc: "手ブレした写真、暗すぎる写真、露出オーバーで白飛びした写真を自動でピックアップします。",
      f4Title: "節約容量のリアルタイム計算",
      f4Desc: "削除を実行する前に、どれだけのメガバイト・ギガバイトが解放されるかを事前に確認できます。",
      f5Title: "100% 端末内プライバシー保護",
      f5Desc: "Apple Visionフレームワーク採用。すべての解析はiPhoneのチップ上だけで完了し、写真は一切外部に送信されません。",
      f6Title: "PhotoKitによる安心削除",
      f6Desc: "削除した写真は「最近削除した項目」アルバムへ移動するため、30日以内ならいつでも復元可能です。"
    },
    faq: {
      badge: "FAQ",
      title: "よくあるご質問",
      subtitle: "Similarlyに関する疑問にお答えします。",
      q1: "写真データが外部サーバーへ送信されることはありますか？",
      a1: "一切ありません。SimilarlyはiPhoneのNeural EngineとApple Visionフレームワークのみを用いて、完全に端末内で処理を完結させます。",
      q2: "誤って削除した写真を復元できますか？",
      a2: "はい、可能です。削除された写真はiOS写真アプリの「最近削除した項目」に移動するため、30日以内であれば元に戻せます。",
      q3: "オフラインでも利用できますか？",
      a3: "はい。インターネット接続は不要で、機内モードでも問題なく動作します。",
      q4: "類似写真はどのように判定されますか？",
      a4: "単なるファイルサイズではなく、Apple VisionのFeaturePrint解析により、被写体の構図や質感を高度に比較して判定します。"
    },
    cta: {
      title: "カメラロールをすっきり整理しませんか？",
      subtitle: "App StoreからSimilarlyを今すぐ無料ダウンロードして、快適な空き容量を取り戻しましょう。",
      button: "App Storeで入手"
    },
    footer: {
      desc: "プライバシー重視のiOS向け類似・重複写真クリーナーアプリ。Made with ❤️ in Turkey.",
      product: "製品",
      legal: "法的事項",
      privacy: "プライバシーポリシー",
      terms: "利用規約",
      rights: "© 2025 Similarly. All rights reserved."
    },
    privacyPage: {
      title: "プライバシーポリシー",
      subtitle: "ユーザーのプライバシー保護を最優先に",
      lastUpdated: "最終更新日: 2025年10月",
      intro: "本プライバシーポリシーは、iOS向けSimilarlyアプリにおけるユーザー情報の取り扱い方針を説明するものです。Similarlyは完全に端末内で完結するツールとして設計されています。",
      boxHighlight: "🛡️ 基本原則: 画像解析や類似判定などのすべての処理は、ユーザーのiPhone内部のみで実行されます。写真や個人データが外部サーバーへ送信されることは決してありません。",
      h1: "1. アクセスする情報",
      p1: "Similarlyは、類似写真や重複写真をスキャン・比較・表示する目的でのみ写真ライブラリへのアクセス権限を要求します。外部サーバーへの収集や保存は一切行いません。",
      h2: "2. デバイス上での画像処理",
      p2: "解析にはAppleのVisionフレームワーク（FeaturePrint）を使用し、端末内のNeural Engineで高速処理されます。生成された数値データは端末内の安全なSwiftDataデータベースにのみ一時保持されます。",
      h3: "3. 第三者トラッキングの不使用",
      p3: "本アプリには広告SDK、第三者トラッカー、行動解析ツールは一切含まれていません。個人情報や端末識別子の追跡も行いません。",
      h4: "4. 安全な写真削除",
      p4: "削除処理にはApple公式のPhotoKit APIを使用し、iOSシステムの確認ダイアログが表示されます。削除された写真は「最近削除した項目」アルバムへ移動し、30日間安全に保管されます。",
      h5: "5. お問い合わせ",
      p5: "本ポリシーに関するご質問は support@similarly.app までお気軽にお寄せください。",
      backHome: "ホームに戻る"
    }
  },

  "zh-Hans": {
    dir: "ltr",
    langName: "简体中文",
    flag: "🇨🇳",
    nav: {
      features: "功能特点",
      faq: "常见问题",
      privacy: "隐私政策",
      download: "立即下载"
    },
    hero: {
      badge: "✨ 纯本地设备端 AI 相册清理工具",
      title1: "告别相册臃肿，",
      titleGradient: "保留最美瞬间",
      subtitle: "Similarly 依托 100% 本地运行的 Apple Vision 图像算法，极速识别相似连拍、重复图片及画质模糊废片。几秒内为您的 iPhone 释放大量存储空间。",
      explore: "探索核心功能",
      statsAccuracy: "99% 识别率",
      statsSpeed: "10倍 疾速处理",
      statsPrivacy: "100% 设备端运算",
      statsStorage: "海量空间释放"
    },
    stats: {
      item1Val: "100%",
      item1Lbl: "设备端隐私安全",
      item2Val: "0 MB",
      item2Lbl: "云端数据上传",
      item3Val: "10倍",
      item3Lbl: "更快 Vision AI",
      item4Val: "∞",
      item4Lbl: "相片支持上限"
    },
    features: {
      badge: "功能特点",
      title: "为什么选择 Similarly？",
      subtitle: "为您提供最高效、最安全、最智能的 iPhone 相册整理体验。",
      f1Title: "相似照片精准识别",
      f1Desc: "自动分类连拍废片与相似抓拍姿势。精选保留最清晰的一张，一键清理其余冗余照片。",
      f2Title: "完全重复照片清理",
      f2Desc: "毫秒级找出完全相同的重复文件、多次保存的照片与重复截图，彻底释放宝贵存储空间。",
      f3Title: "模糊与低画质甄别",
      f3Desc: "自动检测对焦不准的模糊废片、严重欠曝暗片或高光过曝照片，助您快速清理。",
      f4Title: "实时空间节省预估",
      f4Desc: "在执行删除前，精确计算并展示可为您腾出的兆字节（MB）与吉字节（GB）容量。",
      f5Title: "100% 本地隐私保障",
      f5Desc: "完全基于 Apple Vision 框架开发，所有计算全部在 iPhone 芯片本地完成，绝不上传云端。",
      f6Title: "PhotoKit 官方安全删除",
      f6Desc: "通过 Apple 官方接口安全删除，所有清理照片都会进入系统的“最近删除”相簿，30天内可随时恢复。"
    },
    faq: {
      badge: "常见问题",
      title: "常见问题解答",
      subtitle: "为您解答关于 Similarly 的核心疑问。",
      q1: "我的照片会被上传到外部服务器吗？",
      a1: "绝不可能。Similarly 100% 在您的 iPhone 本地运行，利用 Apple Neural Engine 和 Vision 框架进行运算，没有任何照片会离开您的设备。",
      q2: "如果不小心误删了照片，还能找回吗？",
      a2: "可以！所有删除的照片都会存放在系统“照片”应用的“最近删除”相簿中，30天内您可以随时一键还原。",
      q3: "离线或没有网络时可以使用吗？",
      a3: "完全可以，Similarly 支持完全离线工作，即使在飞行模式下功能也完全正常。",
      q4: "它是如何判定照片相似的？",
      a4: "并非简单比对文件哈希，而是通过 Apple Vision FeaturePrint 提取高维视觉特征，对画面的色彩构图及主体特征进行深度比对。"
    },
    cta: {
      title: "准备好给您的 iPhone 相册瘦身了吗？",
      subtitle: "立即前往 App Store 免费下载 Similarly，数分钟内清理多余照片，释放宝贵存储容量。",
      button: "前往 App Store 下载"
    },
    footer: {
      desc: "专为 iOS 打造的隐私优先、智能相似及重复照片清理利器。Made with ❤️ in Turkey.",
      product: "产品",
      legal: "法律与条款",
      privacy: "隐私政策",
      terms: "使用条款",
      rights: "© 2025 Similarly. 保留所有权利。"
    },
    privacyPage: {
      title: "隐私政策",
      subtitle: "守护您的个人隐私是我们的首要准则",
      lastUpdated: "最后更新日期：2025年10月",
      intro: "本隐私政策阐明了 Similarly iOS 应用程序如何处理并保护您的隐私。Similarly 自诞生起便坚持“隐私优先、设备端独立运行”的设计理念。",
      boxHighlight: "🛡️ 核心准则：所有的图像分析、相似度比对和相片分类操作均完全在您的 iPhone 本地设备端执行。您的照片、视频及个人数据绝不会上传至任何远程服务器。",
      h1: "1. 我们访问的信息",
      p1: "Similarly 仅在获得您的明确授权后访问 iOS 系统相册，且仅用于在本地扫描、比对与呈现相似或重复照片。我们绝不在云端收集、传输或保留您的任何照片或元数据。",
      h2: "2. 本地设备端图像处理",
      p2: "图像比对利用 Apple 原生 Vision 框架结合本地神经网络芯片执行。运算生成的特征向量仅在本地沙盒数据库中作临时缓存，照片移除后相关数据亦同步清除。",
      h3: "3. 无第三方追踪与广告",
      p3: "Similarly 内部不集成任何第三方广告 SDK、用户追踪框架或行为统计代码，绝不追踪您的设备标识或个人身份。",
      h4: "4. 安全删除机制",
      p4: "删除操作严格遵从 Apple PhotoKit 系统级确认规范。被删除项目将安全移入“最近删除”相簿，享有 30 天的无忧挽回期。",
      h5: "5. 联系我们",
      p5: "若您对本隐私政策有任何疑问或建议，欢迎发送邮件至 support@similarly.app。",
      backHome: "返回首页"
    }
  },

  ar: {
    dir: "rtl",
    langName: "العربية",
    flag: "🇸🇦",
    nav: {
      features: "المميزات",
      faq: "الأسئلة الشائعة",
      privacy: "سياسة الخصوصية",
      download: "تحميل"
    },
    hero: {
      badge: "✨ تنظيف الصور بالذكاء الاصطناعي داخل جهازك",
      title1: "تخلص من الفوضى،",
      titleGradient: "واحتفظ بأجمل الذكريات",
      subtitle: "يكتشف تطبيق Similarly لقطات التصوير المتتالي المتشابهة والصور المكررة والضبابية بأمان تام عبر تقنية Apple Vision بنسبة 100% داخل جهازك. استعد غيغابايت من مساحة الآيفون في ثوانٍ.",
      explore: "استكشف المميزات",
      statsAccuracy: "دقة 99%",
      statsSpeed: "أسرع 10 مرات",
      statsPrivacy: "100% داخل الجهاز",
      statsStorage: "مساحة هائلة مستعادة"
    },
    stats: {
      item1Val: "100%",
      item1Lbl: "خصوصية داخل الجهاز",
      item2Val: "0 ميغابايت",
      item2Lbl: "بيانات رُفعت للإنترنت",
      item3Val: "10x",
      item3Lbl: "معالجة أسرع عبر Vision",
      item4Val: "∞",
      item4Lbl: "عدد الصور المدعوم"
    },
    features: {
      badge: "المميزات",
      title: "لماذا تختار Similarly؟",
      subtitle: "الطريقة الأسرع والأكثر أماناً وذكاءً لتنظيم ألبوم صور الآيفون الخاص بك.",
      f1Title: "كشف ذكي للصور المتشابهة",
      f1Desc: "يجمع تلقائياً لقطات التصوير المتتابع والوضعيات المتشابهة. يحتفظ بأوضح لقطة ويتيح مسح الباقي بنقرة واحدة.",
      f2Title: "حذف الصور المكررة تماماً",
      f2Desc: "يكتشف النسخ المتطابقة من الصور ولقطات الشاشة المتكررة لتوفير مساحة التخزين فوراً.",
      f3Title: "اكتشاف الصور الضبابية والسيئة",
      f3Desc: "يتعرف تلقائياً على الصور غير الواضحة أو شديدة الظلمة أو الزائدة الإضاءة.",
      f4Title: "حساب فوري للمساحة الموفرة",
      f4Desc: "يحسب لك بدقة مقدار الميغابايت والغيغابايت التي ستستعيدها قبل اتخاذ أي إجراء حذف.",
      f5Title: "خصوصية محلية 100%",
      f5Desc: "يعتمد على محرك Apple Vision الذكي. تتم جميع العمليات داخل جهازك فقط دون رفع أي بيانات للسحابة.",
      f6Title: "حذف آمن عبر PhotoKit",
      f6Desc: "تُنقل الصور المحذوفة إلى ألبوم 'المحذوفة مؤخراً' بالنظام، مما يتيح لك استعادتها بكل سهولة خلال 30 يوماً."
    },
    faq: {
      badge: "الأسئلة الشائعة",
      title: "الأسئلة المتداولة",
      subtitle: "كل ما تحتاج معرفته حول تطبيق Similarly.",
      q1: "هل يتم رفع صوري إلى أي خادم خارجي؟",
      a1: "أبداً. يعمل Similarly محلياً بنسبة 100% داخل هاتفك مستفيداً من شريحة Neural Engine وتقنية Apple Vision. لا تغادر أي صورة جهازك نهائياً.",
      q2: "هل يمكنني استرجاع الصور إذا حذفتها بالخطأ؟",
      a2: "نعم بالتأكيد! تذهب الصور إلى ألبوم 'المحذوفة مؤخراً' في تطبيق الصور بالنظام، ويمكنك استعادتها في أي وقت خلال 30 يوماً.",
      q3: "هل يحتاج التطبيق إلى اتصال بالإنترنت؟",
      a3: "كلا، يعمل التطبيق دون اتصال بالإنترنت نهائياً وحتى في وضع الطيران.",
      q4: "كيف يتعرف التطبيق على الصور المتشابهة؟",
      a4: "يعتمد على تحليل Apple Vision FeaturePrint للتعرف على محتوى المشهد والزوايا والألوان بدقة متناهية وليس مجرد حجم الملف."
    },
    cta: {
      title: "جاهز لتنظيم ألبوم صورك وتوفير المساحة؟",
      subtitle: "حمل تطبيق Similarly مجاناً اليوم من App Store واستعد مساحة تخزين هاتفك الثمينة في دقائق.",
      button: "التحميل من App Store"
    },
    footer: {
      desc: "التطبيق الذكي لتنظيف الصور المتشابهة والمكررة على iOS مع الحفاظ المطلق على الخصوصية. Made with ❤️ in Turkey.",
      product: "المنتج",
      legal: "قانوني",
      privacy: "سياسة الخصوصية",
      terms: "شروط الاستخدام",
      rights: "© 2025 Similarly. جميع الحقوق محفوظة."
    },
    privacyPage: {
      title: "سياسة الخصوصية",
      subtitle: "خصوصيتك وأمان ذكرياتك هما أولويتنا المطلقة",
      lastUpdated: "آخر تحديث: أكتوبر 2025",
      intro: "توضح سياسة الخصوصية هذه التزامنا التام بحماية بياناتك أثناء استخدام تطبيق Similarly على نظام iOS. صُمم التطبيق بالكامل ليعمل محلياً دون أي خوادم خارجية.",
      boxHighlight: "🛡️ المبدأ الأساسي: جميع عمليات معالجة الصور وفحص التشابه تتم حصرياً داخل هاتف الآيفون الخاص بك. لا تخرج صورك أو بياناتك الشخصية من جهازك على الإطلاق.",
      h1: "1. البيانات التي نصل إليها",
      p1: "يطلب التطبيق الإذن للوصول إلى ألبوم صورك فقط بهدف فحص ومقارنة وعرض الصور المتشابهة والمكررة داخل جهازك. نحن لا نجمع أو ننقل أو نخزن أي بيانات على أي خوادم خارجية.",
      h2: "2. معالجة الصور محلياً داخل الجهاز",
      p2: "تتم المعالجة عبر إطار عمل Apple Vision والتعلم الآلي على معالج هاتفك مباشرة. تُخزن البيانات الرقمية المؤقتة في قاعدة بيانات محلية بجهازك وتُحذف تلقائياً عند حذف الصور.",
      h3: "3. عدم وجود أدوات تتبع أو إعلانات",
      p3: "لا يحتوي تطبيق Similarly على أي شبكات إعلانية أو أدوات تتبع لطرف ثالث. نحن لا نتتبع هويتك أو نشاطك الرقمي نهائياً.",
      h4: "4. الحذف الآمن وحقوق المستخدم",
      p4: "يتم الحذف عبر واجهة PhotoKit الرسمية من Apple بعد الحصول على تأكيد النظام المباشر. تنتقل العناصر المحذوفة إلى ألبوم 'المحذوفة مؤخراً' لمدة 30 يوماً مما يضمن لك سهولة استرجاعها.",
      h5: "5. تواصل معنا",
      p5: "إذا كانت لديك أي استفسارات حول سياسة الخصوصية، يسعدنا تواصلك معنا عبر support@similarly.app.",
      backHome: "العودة للرئيسية"
    }
  }
};
