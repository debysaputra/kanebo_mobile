import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// Singleton yang mengurus inisialisasi AdMob serta iklan interstitial &
/// rewarded (yang sifatnya di-load di awal lalu ditampilkan saat dibutuhkan).
///
/// Banner & native ad tidak dikelola di sini — keduanya di-load langsung oleh
/// widget-nya masing-masing karena terikat ke ukuran/lifecycle widget.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;
  int _saveCounter = 0;

  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;

  RewardedAd? _rewarded;
  bool _loadingRewarded = false;

  /// Panggil sekali saat startup (setelah WidgetsFlutterBinding).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await MobileAds.instance.initialize();
    if (AdConfig.enableInterstitial) _loadInterstitial();
    if (AdConfig.enableRewarded) _loadRewarded();
  }

  // ---------------------------------------------------------------------------
  // Interstitial
  // ---------------------------------------------------------------------------
  void _loadInterstitial() {
    if (_loadingInterstitial || _interstitial != null) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitial = null;
              _loadInterstitial(); // siapkan untuk berikutnya
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitial = null;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          _interstitial = null;
          debugPrint('Interstitial gagal load: $error');
        },
      ),
    );
  }

  /// Catat satu kali simpan transaksi; tampilkan interstitial bila sudah
  /// mencapai kelipatan [AdConfig.interstitialEveryNSaves] dan iklan siap.
  void registerSaveAndMaybeShowInterstitial() {
    if (!AdConfig.enableInterstitial) return;
    _saveCounter++;
    if (_saveCounter % AdConfig.interstitialEveryNSaves != 0) return;
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    ad.show();
  }

  // ---------------------------------------------------------------------------
  // Rewarded (opsional, dipicu oleh user)
  // ---------------------------------------------------------------------------
  void _loadRewarded() {
    if (_loadingRewarded || _rewarded != null) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: AdConfig.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _loadingRewarded = false;
        },
        onAdFailedToLoad: (error) {
          _loadingRewarded = false;
          _rewarded = null;
          debugPrint('Rewarded gagal load: $error');
        },
      ),
    );
  }

  bool get isRewardedReady => _rewarded != null;

  /// Tampilkan rewarded ad. [onReward] dipanggil bila user menonton sampai
  /// selesai. Mengembalikan `false` bila iklan belum siap.
  bool showRewarded({required VoidCallback onReward}) {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    _rewarded = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewarded();
      },
    );
    ad.show(onUserEarnedReward: (_, __) => onReward());
    return true;
  }
}
