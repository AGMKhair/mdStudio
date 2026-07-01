import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/markdown_file_provider.dart';
import '../providers/subscription_provider.dart';
import '../../../../core/services/ad_service.dart';
import '../widgets/premium_paywall_popup.dart';
import '../../../../core/services/update_service.dart';
import 'dashboard/home_tab.dart';
import 'dashboard/explorer_tab.dart';
import 'dashboard/settings_tab.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _currentTab = 0; // 0: Home, 1: Explorer, 2: Settings

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAppOpenAd();
      _checkAndShowPremiumPopup();
      UpdateService.checkForUpdates(context);
    });
  }

  Future<void> _checkAndShowPremiumPopup() async {
    final subState = ref.read(subscriptionProvider);
    
    // 1. If already subscribed, don't show
    if (subState.isSubscribed) return;

    // 2. Check last shown date in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final lastShownStr = prefs.getString('premium_popup_last_shown');
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // TEST MODE: If kDebugMode is true, you might want to show it every time for testing.
    // Replace 'true' with 'false' if you want daily check even in debug.
    const bool forceShowForTest = kDebugMode && true; 

    if (forceShowForTest || lastShownStr != today) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => const PremiumPaywallPopup(),
        );
        // 3. Save today's date as last shown
        await prefs.setString('premium_popup_last_shown', today);
      }
    }
  }

  void _showAppOpenAd() {
    AdService.showAppOpenAd(context);
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    switch (_currentTab) {
      case 0:
        content = HomeTab(
          onNavigateToExplorer: (filter) {
            if (filter != null) {
              ref.read(markdownFileProvider.notifier).setFilter(filter);
            }
            setState(() => _currentTab = 1);
          },
        );
        break;
      case 1:
        content = const ExplorerTab();
        break;
      case 2:
        content = const SettingsTab();
        break;
      default:
        content = HomeTab(
          onNavigateToExplorer: (filter) {
            if (filter != null) {
              ref.read(markdownFileProvider.notifier).setFilter(filter);
            }
            setState(() => _currentTab = 1);
          },
        );
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentTab == 0
              ? 'Dashboard'
              : _currentTab == 1
                  ? 'File Explorer'
                  : 'Settings',
        ),
      ),
      body: content,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey500,
        onTap: (index) => setState(() => _currentTab = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_copy_rounded), label: 'Explorer'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}
