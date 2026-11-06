---
name: pre-release-audit
description: >-
  Use this skill whenever preparing a new release, submitting to App Store Connect / TestFlight,
  running pre-release checks, validating 100% localization across 12 languages,
  verifying core engine revisions, scanning UI layout truncation, auditing privacy & PhotoKit strings,
  or generating the final 'v{VERSION} pre release report.md'.
---

# Pre-Release Audit Skill (Yayın Öncesi Son Kontrol)

Bu yetenek (skill), Similarly projesinde yeni bir sürüm App Store Connect veya TestFlight'a gönderilmeden önce **tüm teknik, yerelleştirme, izin, performans ve kod kalitesi risklerini sıfıra indirmek** amacıyla kullanılır.

## Otomatik Denetim Betiğini Çalıştırma

Skill bünyesinde yer alan entegre betik tüm projeyi saniyeler içinde tarar ve otomatik rapor üretir:

```bash
python3 /Users/tamersavasci/Documents/Similarly/.agents/skills/pre-release-audit/scripts/run_pre_release_audit.py
```

Bu betik otomatik olarak:
1. `MARKETING_VERSION` ve `CURRENT_PROJECT_VERSION` değerlerini okur.
2. `Info.plist` içinde `ITSAppUsesNonExemptEncryption` değerini doğrular.
3. 12 dilde `InfoPlist.strings` ve `Localizable.strings` dosyalarını tarayıp `plutil -lint` ile syntax denetimi yapar.
4. Kod tabanında `force-unwrap` (`!`), `force-cast` (`as!`) ve debug log kalıntılarını tarar.
5. `PhotoAnalyzer`, `SimilarityEngine` ve `ReviewManager` motor testlerini doğrular.
6. `xcodebuild` derlemesini koşturur.
7. Proje kök dizininde `v{VERSION} pre release report.md` raporunu oluşturur.
