import Foundation

/// AdMob configuration constants.
///
/// BEFORE RELEASING TO APP STORE:
/// 1. Create an AdMob account at https://admob.google.com
/// 2. Create an iOS App in AdMob and copy the App ID
/// 3. Create two Ad Units (Banner and Rewarded)
/// 4. Replace all placeholder values below with your real IDs
/// 5. Also update GADApplicationIdentifier in Info.plist with your App ID
enum AdConfig {

    // MARK: - App ID

    /// Your AdMob App ID.
    /// Format: "ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"
    ///
    /// TODO: Replace with real App ID before App Store release.
    /// Also update Info.plist → GADApplicationIdentifier with the same value.
    static let appID = "ca-app-pub-3940256099942544~1458002511" // Google test App ID

    // MARK: - Ad Unit IDs

    /// Banner ad unit ID shown at the bottom of the HomeView.
    /// Format: "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
    ///
    /// TODO: Replace with real Banner Ad Unit ID before App Store release.
    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716" // Google test ID

    /// Rewarded ad unit ID shown in CityManagementView ("+50 CP" offer).
    /// Format: "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
    ///
    /// TODO: Replace with real Rewarded Ad Unit ID before App Store release.
    static let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313" // Google test ID

    // MARK: - Reward Amount

    /// CP awarded when a user successfully watches a rewarded ad to completion.
    static let rewardedAdCPBonus: Int = 50

    // MARK: - Debug Helpers

    #if DEBUG
    /// Returns true when using Google test IDs (debug builds).
    static let isUsingTestIDs = true
    #else
    /// Returns true when using Google test IDs (production builds).
    /// If this is true in a release build, AdMob will reject the app.
    static let isUsingTestIDs = appID.contains("3940256099942544")
    #endif
}
