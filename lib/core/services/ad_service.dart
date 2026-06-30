import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../config/app_features.dart';
import '../../features/markdown/presentation/providers/subscription_provider.dart';

class AdService {
  AdService._();

  static bool Function()? isSubscribedCheck;
  static bool Function()? isTestModeCheck;

  // Official AdMob Test Ad Unit IDs
  static const String _appOpenAndroidTest = 'ca-app-pub-3940256099942544/9257395921';
  static const String _appOpenIOSTest = 'ca-app-pub-3940256099942544/5662855259';

  static const String _bannerAndroidTest = 'ca-app-pub-3940256099942544/6300978111';
  static const String _bannerIOSTest = 'ca-app-pub-3940256099942544/2934735716';

  static const String _rewardedAndroidTest = 'ca-app-pub-3940256099942544/5224354917';
  static const String _rewardedIOSTest = 'ca-app-pub-3940256099942544/1712485313';

  // AdMob Production Unit IDs (User Provided)
  static const String _appOpenAndroidProd = 'ca-app-pub-9914807097694036/7975058479';
  static const String _appOpenIOSProd = 'ca-app-pub-9914807097694036/7975058479';

  static const String _bannerAndroidProd = 'ca-app-pub-9914807097694036/6661976801';
  static const String _bannerIOSProd = 'ca-app-pub-9914807097694036/6661976801';

  static const String _rewardedAndroidProd = 'ca-app-pub-9914807097694036/2722731794';
  static const String _rewardedIOSProd = 'ca-app-pub-9914807097694036/2722731794';

  static Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await MobileAds.instance.initialize();
    } catch (_) {}
  }

  // Get current Banner Unit ID
  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    final isAndroid = Platform.isAndroid;
    if (kDebugMode) {
      return isAndroid ? _bannerAndroidTest : _bannerIOSTest;
    } else {
      return isAndroid ? _bannerAndroidProd : _bannerIOSProd;
    }
  }

  // Get current Rewarded Unit ID
  static String get rewardedAdUnitId {
    if (kIsWeb) return '';
    final isAndroid = Platform.isAndroid;
    if (kDebugMode) {
      return isAndroid ? _rewardedAndroidTest : _rewardedIOSTest;
    } else {
      return isAndroid ? _rewardedAndroidProd : _rewardedIOSProd;
    }
  }

  // Get current App Open Unit ID
  static String get appOpenAdUnitId {
    if (kIsWeb) return '';
    final isAndroid = Platform.isAndroid;
    if (kDebugMode) {
      return isAndroid ? _appOpenAndroidTest : _appOpenIOSTest;
    } else {
      return isAndroid ? _appOpenAndroidProd : _appOpenIOSProd;
    }
  }

  // Show App Open Ad (Limit to once per day using local storage)
  static Future<void> showAppOpenAd(BuildContext context) async {
    if (kIsWeb) return;

    try {
      const storage = FlutterSecureStorage();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final lastShowDate = await storage.read(key: 'last_app_open_ad_date');
      
      if (lastShowDate == today) {
        debugPrint('AppOpenAd already shown today.');
        return;
      }

      // Load and show real AdMob App Open Ad
      AppOpenAd.load(
        adUnitId: appOpenAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) async {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
              },
            );
            await ad.show();
            await storage.write(key: 'last_app_open_ad_date', value: today);
          },
          onAdFailedToLoad: (error) {
            debugPrint('AppOpenAd failed to load: $error');
          },
        ),
      );
    } catch (e) {
      debugPrint('Error showing AppOpenAd: $e');
    }
  }

  // Show Rewarded Video Ad before applying password lock
  static Future<void> showRewardedVideoAd(BuildContext context, String reason, VoidCallback onAdCompleted) async {
    if (kIsWeb) {
      onAdCompleted();
      return;
    }

    final Completer<void> completer = Completer<void>();
    bool isRewarded = false;

    // Show loading progress indicator while fetching the ad
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    // Load real AdMob Rewarded Ad
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (context.mounted) {
            Navigator.of(context).pop(); // dismiss loading dialog
          }
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (isRewarded) {
                onAdCompleted();
              }
              if (!completer.isCompleted) completer.complete();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete();
            },
          );
          ad.show(onUserEarnedReward: (adWithoutContent, rewardItem) {
            isRewarded = true;
          });
        },
        onAdFailedToLoad: (error) {
          if (context.mounted) {
            Navigator.of(context).pop(); // dismiss loading dialog
          }
          debugPrint('RewardedAd failed to load: $error');
          onAdCompleted(); // Execute callback anyway to prevent locking user out
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );

    return completer.future;
  }
}

// Visual placeholder banner ad widget when in mock/test mode
class MockBannerAdCard extends StatelessWidget {
  const MockBannerAdCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppFeatures.hideBannerAds) {
      return const SizedBox.shrink();
    }
    return const AdMobBannerWidget();
  }
}

// Visual placeholder banner ad widget formatted as a Grid card
class MockBannerAdGridCard extends StatelessWidget {
  const MockBannerAdGridCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppFeatures.hideBannerAds) {
      return const SizedBox.shrink();
    }
    return const AdMobBannerWidget();
  }
}

// Real Google AdMob Banner AdWidget Integration
class AdMobBannerWidget extends ConsumerStatefulWidget {
  const AdMobBannerWidget({super.key});

  @override
  ConsumerState<AdMobBannerWidget> createState() => _AdMobBannerWidgetState();
}

class _AdMobBannerWidgetState extends ConsumerState<AdMobBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (kIsWeb) return;

    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionProvider);
    if (subState.isSubscribed) {
      return const SizedBox.shrink();
    }

    if (kIsWeb || _bannerAd == null || !_isLoaded) {
      return const SizedBox.shrink();
    }
    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      height: _bannerAd!.size.height.toDouble(),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
