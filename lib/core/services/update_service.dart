import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';

class UpdateService {
  UpdateService._();

  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      // Set default values and configuration
      await remoteConfig.setDefaults({
        'min_version': '1.0.0',
        'latest_version': '1.0.0',
        'min_build': 1,
        'latest_build': 1,
        'update_url': 'https://play.google.com/store/apps/details?id=com.mdstudio',
        'update_message': 'A new version of mdStudio Secure is available. Update now to enjoy the latest features and security enhancements.',
      });

      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // Fetch and activate
      await remoteConfig.fetchAndActivate();

      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;
      final int currentBuild = int.tryParse(packageInfo.buildNumber) ?? 1;

      final String minVersion = remoteConfig.getString('min_version');
      final String latestVersion = remoteConfig.getString('latest_version');
      final int minBuild = remoteConfig.getInt('min_build');
      final int latestBuild = remoteConfig.getInt('latest_build');
      final String updateUrl = remoteConfig.getString('update_url');
      final String updateMessage = remoteConfig.getString('update_message');

      bool isMandatoryUpdate = false;
      bool isOptionalUpdate = false;

      // Check mandatory update
      if (_isVersionLower(currentVersion, minVersion)) {
        isMandatoryUpdate = true;
      } else if (currentVersion == minVersion && currentBuild < minBuild) {
        isMandatoryUpdate = true;
      }

      // Check optional update
      if (!isMandatoryUpdate) {
        if (_isVersionLower(currentVersion, latestVersion)) {
          isOptionalUpdate = true;
        } else if (currentVersion == latestVersion && currentBuild < latestBuild) {
          isOptionalUpdate = true;
        }
      }

      if (isMandatoryUpdate) {
        if (context.mounted) {
          _showUpdateUI(context, updateUrl, updateMessage, isMandatory: true);
        }
      } else if (isOptionalUpdate) {
        if (context.mounted) {
          _showUpdateUI(context, updateUrl, updateMessage, isMandatory: false);
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  static bool _isVersionLower(String current, String target) {
    try {
      List<int> currentParts = current.split('.').map(int.parse).toList();
      List<int> targetParts = target.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        int c = i < currentParts.length ? currentParts[i] : 0;
        int t = i < targetParts.length ? targetParts[i] : 0;
        if (c < t) return true;
        if (c > t) return false;
      }
    } catch (_) {}
    return false;
  }

  static void _showUpdateUI(BuildContext context, String url, String message, {required bool isMandatory}) {
    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (ctx) => PopScope(
        canPop: !isMandatory,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF141A2E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon/illustration
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: const Icon(Icons.system_update_rounded, size: 64, color: Colors.white),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        isMandatory ? 'Critical Update' : 'New Version Available',
                        style: GoogleFonts.saira(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.saira(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // Action Buttons
                      Row(
                        children: [
                          if (!isMandatory)
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: Text(
                                  'Maybe Later',
                                  style: GoogleFonts.saira(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          if (!isMandatory) const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                final Uri uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Text(
                                'Update Now',
                                style: GoogleFonts.saira(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
