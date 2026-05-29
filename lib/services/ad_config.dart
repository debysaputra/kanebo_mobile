import 'package:flutter/foundation.dart';

/// Konfigurasi terpusat untuk semua unit iklan AdMob.
///
/// Cara pakai ID asli (produksi):
/// 1. Buat akun https://admob.google.com lalu daftarkan aplikasi (Android).
/// 2. Salin **App ID** ke `android/app/src/main/AndroidManifest.xml`
///    pada meta-data `com.google.android.gms.ads.APPLICATION_ID`.
/// 3. Buat unit iklan (Banner / Native / Interstitial / Rewarded), salin
///    masing-masing Ad Unit ID ke konstanta `_prod*` di bawah.
/// 4. Set [forceTestAds] = false. Saat `kReleaseMode` ID produksi dipakai,
///    saat debug tetap pakai ID test Google biar akun tidak kena banned.
class AdConfig {
  AdConfig._();

  // --- Saklar format iklan (mudah dihidupkan lagi nanti) ---
  // Untuk sekarang HANYA banner yang aktif agar tidak mengganggu user.
  static const bool enableBanner = true;
  static const bool enableNativeInList = false;
  static const bool enableInterstitial = false;
  static const bool enableRewarded = false;

  /// Paksa selalu pakai ID test Google walau di build release.
  /// Biarkan `false`: debug otomatis pakai test, release pakai ID produksi.
  static const bool forceTestAds = false;

  /// Placeholder untuk ID produksi yang BELUM dibuat di AdMob.
  /// Jika sebuah ID produksi masih bernilai ini, otomatis fallback ke ID test.
  static const String _todo = 'TODO';

  // --- ID TEST resmi dari Google (jangan diubah) ---
  static const String _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testNative = 'ca-app-pub-3940256099942544/2247696110';
  static const String _testInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewarded =
      'ca-app-pub-3940256099942544/5224354917';

  // --- ID PRODUKSI (isi dari dashboard AdMob; biarkan _todo bila belum ada) ---
  static const String _prodBanner = 'ca-app-pub-4983939936970212/4494362519';
  static const String _prodNative = _todo;
  static const String _prodInterstitial = _todo;
  static const String _prodRewarded = _todo;

  static bool get _useTest => forceTestAds || !kReleaseMode;

  /// Pilih ID produksi bila tersedia & build release, selain itu pakai test.
  static String _pick(String prod, String test) {
    if (_useTest || prod == _todo) return test;
    return prod;
  }

  static String get bannerUnitId => _pick(_prodBanner, _testBanner);
  static String get nativeUnitId => _pick(_prodNative, _testNative);
  static String get interstitialUnitId =>
      _pick(_prodInterstitial, _testInterstitial);
  static String get rewardedUnitId => _pick(_prodRewarded, _testRewarded);

  /// Tampilkan interstitial setiap kelipatan ini saat simpan transaksi.
  /// Angka besar = lebih jarang = tidak mengganggu.
  static const int interstitialEveryNSaves = 5;

  /// Sisipkan satu native ad setiap N item di daftar transaksi.
  static const int nativeAdEveryNItems = 8;
}
