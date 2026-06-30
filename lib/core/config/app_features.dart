class AppFeatures {
  AppFeatures._();

  // If false, subscription gating and paywall popups are completely disabled.
  static const bool enableSubscriptions = true;

  // If true, inline banner ads are hidden in explorer and home lists.
  static const bool hideBannerAds = false;

  // Determines if user should see general banner ads based on subscriptions or global flag
  static bool shouldShowBanners(bool isSubscribed) {
    if (hideBannerAds) return false;
    return !isSubscribed;
  }
}
