import subprocess
import time
import os
import shutil

SIMULATOR_UDID = "0ABDEF65-8E56-492C-A88E-BC388B52D4E8"
APP_BUNDLE_ID = "tsavasci.Similarly"
BASE_DIR = "/Users/tamersavasci/Documents/Similarly"
OUTPUT_DIR = os.path.join(BASE_DIR, "AppStoreScreenshots")
REMOVE_ALPHA_BIN = "/tmp/remove_alpha"

LANGUAGES = [
    {"code": "tr", "name_tr": "Türkçe", "name_native": "Türkçe"},
    {"code": "en", "name_tr": "İngilizce", "name_native": "English"},
    {"code": "de", "name_tr": "Almanca", "name_native": "Deutsch"},
    {"code": "es", "name_tr": "İspanyolca", "name_native": "Español"},
    {"code": "fr", "name_tr": "Fransızca", "name_native": "Français"},
    {"code": "ja", "name_tr": "Japonca", "name_native": "日本語"},
    {"code": "zh-Hans", "name_tr": "Çince", "name_native": "简体中文"},
    {"code": "ar", "name_tr": "Arapça", "name_native": "العربية"},
]

def run_cmd(args):
    return subprocess.run(args, capture_output=True, text=True)

def setup_dirs():
    for size in ["6.9", "6.5"]:
        for lang in LANGUAGES:
            path = os.path.join(OUTPUT_DIR, size, lang["name_tr"])
            os.makedirs(path, exist_ok=True)

def capture_screen(lang, screen_num):
    code = lang["code"]
    name_tr = lang["name_tr"]
    print(f"[{code}] Capturing screen {screen_num}/10 for {name_tr}...")

    # Terminate running app
    run_cmd(["xcrun", "simctl", "terminate", SIMULATOR_UDID, APP_BUNDLE_ID])

    # Launch app with arguments
    launch_args = [
        "xcrun", "simctl", "launch", SIMULATOR_UDID, APP_BUNDLE_ID,
        "--screenshot", str(screen_num),
        "-AppleLanguages", f"({code})",
        "-appLanguage", code
    ]
    run_cmd(launch_args)

    # Appropriate wait time
    if screen_num in [1, 2, 10]:
        time.sleep(1.4)
    elif screen_num == 3:
        time.sleep(2.0)
    else:
        time.sleep(2.8)

    raw_tmp = f"/tmp/raw_screen_{code}_{screen_num}.png"
    run_cmd(["xcrun", "simctl", "io", SIMULATOR_UDID, "screenshot", raw_tmp])

    # Destination paths for 6.9"
    out_69_path = os.path.join(OUTPUT_DIR, "6.9", name_tr, f"{name_tr}{screen_num}.png")
    
    # Remove alpha to be App Store Connect compliant
    run_cmd([REMOVE_ALPHA_BIN, raw_tmp, out_69_path])

    # Create 6.5" version (1242 x 2688)
    out_65_path = os.path.join(OUTPUT_DIR, "6.5", name_tr, f"{name_tr}{screen_num}.png")
    run_cmd(["sips", "-z", "2688", "1242", out_69_path, "--out", out_65_path])

    if os.path.exists(raw_tmp):
        os.remove(raw_tmp)

def main():
    setup_dirs()
    # Ensure status bar is clean 9:41
    run_cmd([
        "xcrun", "simctl", "status_bar", SIMULATOR_UDID, "override",
        "--time", "9:41",
        "--batteryState", "charged",
        "--batteryLevel", "100",
        "--cellularBars", "4",
        "--wifiBars", "3"
    ])

    total = len(LANGUAGES) * 10
    current = 0
    for lang in LANGUAGES:
        print(f"\n==========================================")
        print(f"Starting language: {lang['name_tr']} ({lang['code']})")
        print(f"==========================================")
        for s in range(1, 11):
            current += 1
            print(f"Progress: {current}/{total}")
            capture_screen(lang, s)

    print("\nAll screenshots generated successfully!")

if __name__ == "__main__":
    main()
