# ScTools v1 — Flutter APK

APK Android untuk bypass SFL, cari script ML di YouTube, dan manage script Mobile Legends.

---

## ⚙️ Setup & Build

### Prasyarat
- Flutter SDK 3.x ([flutter.dev](https://flutter.dev/docs/get-started/install))
- Android Studio + Android SDK
- JDK 17+

### 1. Install Dependencies
```bash
cd ScToolsv1
flutter pub get
```

### 2. YouTube API Key (WAJIB)
Buka file `lib/services/youtube_service.dart` dan ganti:
```dart
static const String _apiKey = 'YOUR_YOUTUBE_API_KEY_HERE';
```
Dengan API Key YouTube Data v3 kamu dari [Google Cloud Console](https://console.cloud.google.com).

**Cara dapat API Key:**
1. Buka Google Cloud Console
2. Buat project baru
3. Enable "YouTube Data API v3"
4. Buat Credentials → API Key
5. Tempel di file di atas

### 3. Build APK Release
```bash
flutter build apk --release
```
APK output: `build/app/outputs/flutter-apk/app-release.apk`

### 4. Build APK Debug (untuk testing)
```bash
flutter build apk --debug
```

### 5. Install Langsung ke HP (USB debugging ON)
```bash
flutter install
```

---

## 📱 Fitur

### Tab 1: ⚡ SFL Bypass
- Paste link `sfl.gl/safelinku`
- Tap **Bypass Sekarang**
- Hasil muncul + tombol Salin & Buka
- Riwayat tersimpan otomatis (max 30)

### Tab 2: 🎬 Cari Script YouTube
- Search script ML via YouTube Data API v3
- Tampil thumbnail, judul, channel, waktu
- Tap video → buka YouTube langsung

### Tab 3: 📦 Script Manager ML
- Tap **Install Script** → pilih file `.zip`
- App otomatis deteksi folder dalam zip (Art, Audio, UI, dll)
- Pilih folder mana yang mau diinstall
- Extract otomatis ke:
  `/storage/emulated/0/Android/data/com.mobile.legends/files/dragon2017/assets/`
- List script terpasang + detail + hapus dari daftar

---

## 🔑 Permissions yang Diperlukan

| Permission | Kegunaan |
|---|---|
| INTERNET | Bypass + YouTube API |
| READ/WRITE_EXTERNAL_STORAGE | Akses file ML (Android < 10) |
| MANAGE_EXTERNAL_STORAGE | Akses file ML (Android 10+) |

**Android 11+:** Setelah install APK, perlu aktifkan izin "All Files Access" di Settings > Apps > ScTools > Permissions.

---

## 🛠 Troubleshooting

**"Bypass gagal"** → Coba link lain, atau cek koneksi internet.

**"API Key tidak valid"** → Pastikan YouTube Data API v3 sudah di-enable di Google Cloud Console.

**Script tidak terinstall** → Pastikan:
1. Mobile Legends sudah pernah dibuka (folder harus ada)
2. Izin storage sudah diberikan
3. File zip valid dan berisi folder ML

**Build error** → Jalankan `flutter clean && flutter pub get` lalu build ulang.

---

## 📦 Package yang Digunakan

| Package | Versi | Fungsi |
|---|---|---|
| http | ^1.1.0 | HTTP request |
| file_picker | ^6.1.1 | Pilih file zip |
| archive | ^3.4.9 | Extract zip |
| path_provider | ^2.1.1 | Direktori temp |
| permission_handler | ^11.0.1 | Minta permission |
| shared_preferences | ^2.2.2 | Simpan riwayat |
| url_launcher | ^6.2.1 | Buka link/YouTube |
| cached_network_image | ^3.3.0 | Cache thumbnail |
| intl | ^0.18.1 | Format tanggal |

---

## 🎨 Desain

- Background: Putih bersih
- Aksen: Gradient ungu `#7C3AFF` → cyan `#00D4FF`
- Gaya: Neon modern dengan shadow berwarna
- Bottom nav: Animated pill indicator
