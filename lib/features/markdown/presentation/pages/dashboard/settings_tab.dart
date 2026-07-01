import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/config/app_features.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/services/ad_service.dart';
import '../../providers/theme_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/subscription_provider.dart';
import '../audit_logs_page.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final isSaving = ref.watch(settingsProvider);
    final double screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 500;

    void _handleGoogleLogin(BuildContext context, WidgetRef ref) async {
      final user = await ref.read(subscriptionProvider.notifier).signInWithGoogle(context);
      if (user != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${user.displayName ?? user.email}!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }

    void _showEmailAuthDialog(BuildContext context, WidgetRef ref) {
      final nameController = TextEditingController();
      final emailController = TextEditingController();
      final passwordController = TextEditingController();
      bool isLogin = true;

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(isLogin ? 'Login with Email' : 'Create Account', 
              style: GoogleFonts.saira(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isLogin)
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                if (!isLogin) const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(isLogin ? "Don't have an account? Sign Up" : "Already have an account? Login",
                    style: GoogleFonts.saira(fontSize: 12)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final email = emailController.text.trim();
                  final password = passwordController.text.trim();
                  
                  if (email.isEmpty || password.isEmpty) return;
                  if (!isLogin && name.isEmpty) return;

                  final notifier = ref.read(subscriptionProvider.notifier);
                  final user = isLogin 
                    ? await notifier.signInWithEmail(email, password)
                    : await notifier.signUpWithEmail(email, password, name);

                  if (user != null) {
                    Navigator.of(ctx).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isLogin ? 'Login Failed' : 'Registration Failed'), 
                      backgroundColor: AppColors.error),
                    );
                  }
                },
                child: Text(isLogin ? 'Login' : 'Register'),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildThemeOption(
      String label,
      ThemeMode mode,
      bool isSelected,
      IconData icon,
    ) {
      final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
      
      return Expanded(
        child: InkWell(
          onTap: () => ref.read(themeProvider.notifier).setThemeMode(mode),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : (isDarkTheme ? const Color(0xFF161F38) : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isDarkTheme ? const Color(0xFF23305A) : Colors.grey.shade300),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : (isDarkTheme ? Colors.white70 : Colors.black87),
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.saira(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : (isDarkTheme ? Colors.white70 : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final subState = ref.watch(subscriptionProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preferences', style: GoogleFonts.saira(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppDimensions.paddingM),

            // User Authentication Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_circle_rounded, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Account & Sync',
                          style: GoogleFonts.saira(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Login to sync your premium subscription across all your devices securely.',
                      style: GoogleFonts.saira(fontSize: 12, color: AppColors.grey500),
                    ),
                    const SizedBox(height: 16),
                    if (subState.user != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundImage: subState.user!.photoURL != null 
                              ? NetworkImage(subState.user!.photoURL!) 
                              : null,
                          child: subState.user!.photoURL == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(subState.user!.displayName ?? 'User', style: GoogleFonts.saira(fontWeight: FontWeight.bold)),
                        subtitle: Text(subState.user!.email ?? '', style: GoogleFonts.saira(fontSize: 12)),
                        trailing: TextButton(
                          onPressed: () => ref.read(subscriptionProvider.notifier).signOut(),
                          child: const Text('Logout', style: TextStyle(color: AppColors.error)),
                        ),
                      )
                    else
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _handleGoogleLogin(context, ref),
                              icon: const Icon(Icons.login_rounded),
                              label: const Text('Sign in with Google'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                side: const BorderSide(color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showEmailAuthDialog(context, ref),
                              icon: const Icon(Icons.email_rounded),
                              label: const Text('Sign in with Email'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            
            // Theme selection card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.brightness_medium_rounded, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Theme Settings',
                          style: GoogleFonts.saira(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Customize the look of mdStudio Secure. Choose between Light Mode, Dark Mode, or match your System Default.',
                      style: GoogleFonts.saira(fontSize: 12, color: AppColors.grey500),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        buildThemeOption('Light', ThemeMode.light, theme == ThemeMode.light, Icons.light_mode_rounded),
                        const SizedBox(width: 8),
                        buildThemeOption('Dark', ThemeMode.dark, theme == ThemeMode.dark, Icons.dark_mode_rounded),
                        const SizedBox(width: 8),
                        buildThemeOption('System', ThemeMode.system, theme == ThemeMode.system, Icons.settings_suggest_rounded),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Premium Subscription & Monetization Card
            if (AppFeatures.enableSubscriptions) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                            'mdStudio Premium Pass',
                            style: GoogleFonts.saira(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subState.isSubscribed
                            ? 'Thank you! You are subscribed to the ${subState.planType.toUpperCase()} Plan. All advertisements are disabled and advanced encryption is fully unlocked.'
                            : 'Unlock advanced security features and enjoy a completely ad-free experience by subscribing to a premium plan.',
                        style: GoogleFonts.saira(fontSize: 12, color: AppColors.grey500),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () => ref.read(subscriptionProvider.notifier).purchasePlan(context, 'monthly'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: subState.isSubscribed && subState.planType == 'monthly'
                                        ? AppColors.success
                                        : AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text('Monthly - \$0.41 (50 BDT)',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.saira(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                if (subState.isSubscribed && subState.planType == 'monthly')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                                        const SizedBox(width: 4),
                                        Text('Active Plan',
                                            style: GoogleFonts.saira(
                                                fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () => ref.read(subscriptionProvider.notifier).purchasePlan(context, 'lifetime'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: subState.isSubscribed && subState.planType == 'lifetime'
                                        ? AppColors.success
                                        : AppColors.secondary,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text('Lifetime - \$5.00 (600 BDT)',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.saira(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                if (subState.isSubscribed && subState.planType == 'lifetime')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                                        const SizedBox(width: 4),
                                        Text('Active Plan',
                                            style: GoogleFonts.saira(
                                                fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingM),
            ],

            // Security Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.security_rounded, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Document Level Security',
                          style: GoogleFonts.saira(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'To protect your sensitive files, you can set individual password or biometric (Face ID / Fingerprint) locks. Open the actions menu (three dots) next to any file in the Explorer to lock, unlock, or manage encryption.',
                      style: GoogleFonts.saira(fontSize: 12, color: AppColors.grey500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // System Audit Logs Card
            Card(
              child: ListTile(
                leading: const Icon(Icons.history_edu_rounded, color: AppColors.primary),
                title: Text('System Audit Trail', style: GoogleFonts.saira(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('View security logs, file activities, and encryption changes', style: GoogleFonts.saira(fontSize: 11, color: AppColors.grey500)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AuditLogsPage()),
                  );
                },
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Backup and Restore Card
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backup & Restore Management',
                      style: GoogleFonts.saira(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manually backup the local SQLite database to device storage, or sync safely using secure Firebase Cloud backups.',
                      style: GoogleFonts.saira(fontSize: 12, color: AppColors.grey500),
                    ),
                    const SizedBox(height: 8),
                    if (!subState.isSubscribed)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Premium feature: Subscribe or watch a short ad to unlock backup/restore.',
                                style: GoogleFonts.saira(fontSize: 11, color: Colors.amber.shade800, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (isSaving)
                      const Center(child: CircularProgressIndicator())
                    else if (isSmallScreen)
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                if (subState.isSubscribed) {
                                  final success = await ref.read(settingsProvider.notifier).backupDatabase();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(success ? 'Database Backup Exported!' : 'Export Failed.'),
                                        backgroundColor: success ? AppColors.secondary : AppColors.error,
                                      ),
                                    );
                                  }
                                } else {
                                  await AdService.showRewardedVideoAd(context, 'Unlock Backup', () async {
                                    final success = await ref.read(settingsProvider.notifier).backupDatabase();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(success ? 'Database Backup Exported!' : 'Export Failed.'),
                                          backgroundColor: success ? AppColors.secondary : AppColors.error,
                                        ),
                                      );
                                    }
                                  });
                                }
                              },
                              icon: Icon(subState.isSubscribed ? Icons.backup_rounded : Icons.play_circle_fill_rounded),
                              label: Text(subState.isSubscribed ? 'Export Backup' : 'Watch Ad to Export'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                Future<void> proceedRestore() async {
                                  final result = await ref.read(settingsProvider.notifier).restoreDatabase();
                                  if (context.mounted) {
                                    if (result == 'success') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Database Restored Successfully!'),
                                          backgroundColor: AppColors.secondary,
                                        ),
                                      );
                                    } else if (result == 'invalid_format') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Restore Failed: Invalid database file format or schema.'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Restore Aborted.'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  }
                                }

                                if (subState.isSubscribed) {
                                    await proceedRestore();
                                } else {
                                  await AdService.showRewardedVideoAd(context, 'Unlock Restore', () async {
                                    await proceedRestore();
                                  });
                                }
                              },
                              icon: Icon(subState.isSubscribed ? Icons.settings_backup_restore_rounded : Icons.play_circle_fill_rounded),
                              label: Text(subState.isSubscribed ? 'Import Backup' : 'Watch Ad to Import'),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                if (subState.isSubscribed) {
                                  final success = await ref.read(settingsProvider.notifier).backupDatabase();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(success ? 'Database Backup Exported!' : 'Export Failed.'),
                                        backgroundColor: success ? AppColors.secondary : AppColors.error,
                                      ),
                                    );
                                  }
                                } else {
                                  await AdService.showRewardedVideoAd(context, 'Unlock Backup', () async {
                                    final success = await ref.read(settingsProvider.notifier).backupDatabase();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(success ? 'Database Backup Exported!' : 'Export Failed.'),
                                          backgroundColor: success ? AppColors.secondary : AppColors.error,
                                        ),
                                      );
                                    }
                                  });
                                }
                              },
                              icon: Icon(subState.isSubscribed ? Icons.backup_rounded : Icons.play_circle_fill_rounded),
                              label: Text(subState.isSubscribed ? 'Export Backup' : 'Watch Ad to Export'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                Future<void> proceedRestore() async {
                                  final result = await ref.read(settingsProvider.notifier).restoreDatabase();
                                  if (context.mounted) {
                                    if (result == 'success') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Database Restored Successfully!'),
                                          backgroundColor: AppColors.secondary,
                                        ),
                                      );
                                    } else if (result == 'invalid_format') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Restore Failed: Invalid database file format or schema.'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Restore Aborted.'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  }
                                }

                                if (subState.isSubscribed) {
                                  await proceedRestore();
                                } else {
                                  await AdService.showRewardedVideoAd(context, 'Unlock Restore', () async {
                                    await proceedRestore();
                                  });
                                }
                              },
                              icon: Icon(subState.isSubscribed ? Icons.settings_backup_restore_rounded : Icons.play_circle_fill_rounded),
                              label: Text(subState.isSubscribed ? 'Import Backup' : 'Watch Ad to Import'),
                            ),
                          ),
                        ],
                      ),
                    const Divider(height: 32),
                    Row(
                      children: [
                        const Icon(Icons.cloud_queue_rounded, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Cloud Sync Backup (Firebase)',
                          style: GoogleFonts.saira(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Safely sync your database backup file directly to your secure personal Firebase cloud storage. Access and restore your database easily on any device.',
                      style: GoogleFonts.saira(fontSize: 11, color: AppColors.grey500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          subState.user != null ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                          size: 14,
                          color: subState.user != null ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            subState.user != null
                                ? 'Logged in as: ${subState.user!.email}'
                                : 'Not logged in. Sign in using Google from dashboard profile menu to enable.',
                            style: GoogleFonts.saira(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: subState.user != null ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (isSmallScreen)
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final user = subState.user;
                                if (user == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please log in using Google from the profile menu first.'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                  return;
                                }

                                Future<void> proceedCloudBackup() async {
                                  final success = await ref.read(settingsProvider.notifier).backupDatabaseToCloud(user.uid);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(success == 'success'
                                            ? 'Database Backup Uploaded to Cloud!'
                                            : 'Cloud Backup Failed.'),
                                        backgroundColor: success == 'success' ? AppColors.secondary : AppColors.error,
                                      ),
                                    );
                                  }
                                }

                                if (subState.isSubscribed) {
                                  await proceedCloudBackup();
                                } else {
                                  await AdService.showRewardedVideoAd(context, 'Unlock Cloud Backup', () async {
                                    await proceedCloudBackup();
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              icon: Icon(subState.isSubscribed ? Icons.cloud_upload_rounded : Icons.play_circle_fill_rounded),
                              label: Text(subState.isSubscribed ? 'Backup to Cloud' : 'Watch Ad to Cloud Backup'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final user = subState.user;
                                if (user == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please log in using Google from the profile menu first.'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                  return;
                                }

                                Future<void> proceedCloudRestore() async {
                                  final result = await ref.read(settingsProvider.notifier).restoreDatabaseFromCloud(user.uid);
                                  if (context.mounted) {
                                    if (result == 'success') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Database Restored from Cloud Successfully!'),
                                          backgroundColor: AppColors.secondary,
                                        ),
                                      );
                                    } else if (result == 'no_backup') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Restore Failed: No cloud backup found for this account.'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    } else if (result == 'invalid_format') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Restore Failed: Cloud backup has invalid database schema.'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Cloud Restore Failed.'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  }
                                }

                                if (subState.isSubscribed) {
                                  await proceedCloudRestore();
                                } else {
                                  await AdService.showRewardedVideoAd(context, 'Unlock Cloud Restore', () async {
                                    await proceedCloudRestore();
                                  });
                                }
                              },
                              icon: Icon(subState.isSubscribed ? Icons.cloud_download_rounded : Icons.play_circle_fill_rounded),
                              label: Text(subState.isSubscribed ? 'Restore from Cloud' : 'Watch Ad to Cloud Restore'),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final user = subState.user;
                                if (user == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please log in using Google from the profile menu first.'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                  return;
                                }

                                Future<void> proceedCloudBackup() async {
                                  final success = await ref.read(settingsProvider.notifier).backupDatabaseToCloud(user.uid);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(success == 'success'
                                            ? 'Database Backup Uploaded to Cloud!'
                                            : 'Cloud Backup Failed.'),
                                        backgroundColor: success == 'success' ? AppColors.secondary : AppColors.error,
                                      ),
                                    );
                                  }
                                }

                                if (subState.isSubscribed) {
                                  await proceedCloudBackup();
                                } else {
                                  await AdService.showRewardedVideoAd(context, 'Unlock Cloud Backup', () async {
                                    await proceedCloudBackup();
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              icon: Icon(subState.isSubscribed ? Icons.cloud_upload_rounded : Icons.play_circle_fill_rounded),
                              label: Text(subState.isSubscribed ? 'Backup to Cloud' : 'Watch Ad to Backup'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final user = subState.user;
                                if (user == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please log in using Google from the profile menu first.'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                  return;
                                }

                                Future<void> proceedCloudRestore() async {
                                  final result = await ref.read(settingsProvider.notifier).restoreDatabaseFromCloud(user.uid);
                                  if (context.mounted) {
                                    if (result == 'success') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Database Restored from Cloud Successfully!'),
                                          backgroundColor: AppColors.secondary,
                                        ),
                                      );
                                    } else if (result == 'no_backup') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Restore Failed: No cloud backup found for this account.'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    } else if (result == 'invalid_format') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Restore Failed: Cloud backup has invalid database schema.'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Cloud Restore Failed.'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  }
                                }

                                if (subState.isSubscribed) {
                                  await proceedCloudRestore();
                                } else {
                                  await AdService.showRewardedVideoAd(context, 'Unlock Cloud Restore', () async {
                                    await proceedCloudRestore();
                                  });
                                }
                              },
                              icon: Icon(subState.isSubscribed ? Icons.cloud_download_rounded : Icons.play_circle_fill_rounded),
                              label: Text(subState.isSubscribed ? 'Restore from Cloud' : 'Watch Ad to Restore'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
