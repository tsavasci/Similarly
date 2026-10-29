#!/usr/bin/env python3
import os
import re
import sys

def parse_strings_file(path):
    keys = {}
    pattern = re.compile(r'^\s*"([^"]+)"\s*=\s*"([^"]*)";', re.MULTILINE)
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    for match in pattern.finditer(content):
        keys[match.group(1)] = match.group(2)
    return keys

def main():
    base_dir = "Similarly"
    languages = ["en", "tr", "ar", "zh-Hans", "es", "fr", "de", "ja"]
    
    en_path = os.path.join(base_dir, "en.lproj", "Localizable.strings")
    if not os.path.exists(en_path):
        print("en.lproj/Localizable.strings bulunamadı!")
        sys.exit(1)
        
    en_keys = parse_strings_file(en_path)
    print(f"Referans (İngilizce) anahtar sayısı: {len(en_keys)}")
    
    has_error = False
    for lang in languages:
        if lang == "en":
            continue
        lang_path = os.path.join(base_dir, f"{lang}.lproj", "Localizable.strings")
        if not os.path.exists(lang_path):
            print(f"HATA: {lang_path} bulunamadı!")
            has_error = True
            continue
            
        target_keys = parse_strings_file(lang_path)
        missing_keys = set(en_keys.keys()) - set(target_keys.keys())
        extra_keys = set(target_keys.keys()) - set(en_keys.keys())
        
        if missing_keys:
            print(f"[{lang}] Eksik {len(missing_keys)} anahtar:")
            for k in sorted(missing_keys):
                print(f"  - {k}")
            has_error = True
        elif extra_keys:
            print(f"[{lang}] Fazla {len(extra_keys)} anahtar:")
            for k in sorted(extra_keys):
                print(f"  + {k}")
        else:
            print(f"[{lang}] OK ({len(target_keys)} anahtar - eksiksiz eşleşti)")

    if has_error:
        print("\nDoğrulama BAŞARISIZ: Eksik anahtarlar mevcut.")
        sys.exit(1)
    else:
        print("\nDoğrulama BAŞARILI: Tüm 8 dilde anahtarlar %100 senkronize!")

if __name__ == "__main__":
    main()
