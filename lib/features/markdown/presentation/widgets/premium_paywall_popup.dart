import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/subscription_provider.dart';

class PremiumPaywallPopup extends ConsumerWidget {
  const PremiumPaywallPopup({super.key});

  Future<bool> _checkInternet(BuildContext context) async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (context.mounted) {
        _showNoInternetDialog(context);
      }
      return false;
    }
    return true;
  }

  void _showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text('No Internet', style: GoogleFonts.saira(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'An active internet connection is required to process subscriptions and verify your account.',
          style: GoogleFonts.saira(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subState = ref.watch(subscriptionProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1424) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.amber.shade400,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium banner header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade700,
                      Colors.orange.shade600,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.star_rounded, size: 56, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      'mdStudio Premium',
                      style: GoogleFonts.saira(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Elevate your secure document vault',
                      style: GoogleFonts.saira(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unlock All Features',
                      style: GoogleFonts.saira(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Features list
                    _buildFeatureRow(Icons.block_rounded, '100% Ad-Free Experience', 'Remove all app open and list banner ads.'),
                    _buildFeatureRow(Icons.lock_rounded, 'Advanced Document Encryption', 'Lock individual folders & documents securely.'),
                    _buildFeatureRow(Icons.fingerprint_rounded, 'Biometric Verification', 'Use face and fingerprint locks on any item.'),
                    _buildFeatureRow(Icons.settings_backup_restore_rounded, 'Unlimited Automated Backups', 'Auto-save and export backups without limits.'),

                    const Divider(height: 32),

                    if (subState.user == null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You need to sign in with Google first to purchase a plan.',
                                style: GoogleFonts.saira(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Subscription choices
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              if (!await _checkInternet(context)) return;
                              
                              if (subState.user == null) {
                                await ref.read(subscriptionProvider.notifier).signInWithGoogle();
                              } else {
                                final success = await ref.read(subscriptionProvider.notifier).purchasePlan('monthly');
                                if (success && context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF161F38) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary, width: 1.5),
                              ),
                              child: Column(
                                children: [
                                  Text('Monthly', style: GoogleFonts.saira(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text('\$0.41 (50 BDT)', style: GoogleFonts.saira(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              if (!await _checkInternet(context)) return;

                              if (subState.user == null) {
                                await ref.read(subscriptionProvider.notifier).signInWithGoogle();
                              } else {
                                final success = await ref.read(subscriptionProvider.notifier).purchasePlan('lifetime');
                                if (success && context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF161F38) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.shade600, width: 1.5),
                              ),
                              child: Column(
                                children: [
                                  Text('Lifetime', style: GoogleFonts.saira(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text('\$5.00 (600 BDT)', style: GoogleFonts.saira(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Actions list
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF1D2640) : Colors.grey.shade200,
                          foregroundColor: isDark ? Colors.white70 : Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Skip & Use Free Mode',
                          style: GoogleFonts.saira(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () async {
                          if (!await _checkInternet(context)) return;
                          final success = await ref.read(subscriptionProvider.notifier).restorePurchases();
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Purchases Restored successfully!')),
                            );
                            Navigator.of(context).pop();
                          }
                        },
                        child: Text(
                          'Restore Previous Purchases',
                          style: GoogleFonts.saira(fontSize: 11, color: AppColors.grey500, decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.amber.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.saira(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(subtitle, style: GoogleFonts.saira(fontSize: 10, color: AppColors.grey500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
