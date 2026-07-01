import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/subscription_provider.dart';

class PremiumPaywallPopup extends ConsumerWidget {
  const PremiumPaywallPopup({super.key});

  Future<bool> _checkInternet(BuildContext context) async {
    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        if (context.mounted) {
          _showNoInternetDialog(context);
        }
        return false;
      }
      return true;
    } catch (e) {
      // If the plugin is missing or fails, we assume there is internet
      // to not block the user from trying to purchase.
      debugPrint('Connectivity check failed: $e');
      return true; 
    }
  }

  void _showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subState = ref.watch(subscriptionProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ClipRRect( // Added ClipRRect to prevent design leakage when scrolling
        borderRadius: BorderRadius.circular(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F1424) : Colors.white,
            border: Border.all(
              color: Colors.amber.shade400,
              width: 1.5,
            ),
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
                      
                      _buildFeatureRow(Icons.block_rounded, '100% Ad-Free Experience', 'Remove all app open and list banner ads.'),
                      _buildFeatureRow(Icons.lock_rounded, 'Advanced Document Encryption', 'Lock individual folders & documents securely.'),
                      _buildFeatureRow(Icons.fingerprint_rounded, 'Biometric Verification', 'Use face and fingerprint locks on any item.'),
                      _buildFeatureRow(Icons.settings_backup_restore_rounded, 'Unlimited Automated Backups', 'Auto-save and export backups without limits.'),

                      const Divider(height: 32),

                      // Login Box with Button
                      if (subState.user == null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Sign in required to purchase plans.',
                                      style: GoogleFonts.saira(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        if (!await _checkInternet(context)) return;
                                          await ref.read(subscriptionProvider.notifier).signInWithGoogle(context);
                                      },
                                      icon: const Icon(Icons.login_rounded, size: 16),
                                      label: const Text('Google'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black87,
                                        elevation: 1,
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        textStyle: GoogleFonts.saira(fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showEmailAuthDialog(context, ref),
                                      icon: const Icon(Icons.email_rounded, size: 16),
                                      label: const Text('Email'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        elevation: 1,
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        textStyle: GoogleFonts.saira(fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      // Subscription choices
                      Row(
                        children: [
                          Expanded(
                            child: Material( // Added Material for ripple effect
                              color: isDark ? const Color(0xFF161F38) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  if (!await _checkInternet(context)) return;
                                  
                                  if (subState.user == null) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please login first to purchase a plan!'),
                                          backgroundColor: Colors.orange,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                    _showEmailAuthDialog(context, ref);
                                  } else {
                                    final success = await ref.read(subscriptionProvider.notifier).purchasePlan(context, 'monthly');
                                    if (success && context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.primary, width: 1.5),
                                  ),
                                  child: Column(
                                    children: [
                                      Text('Monthly', style: GoogleFonts.saira(fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.swap_vert_rounded, size: 14, color: AppColors.primary),
                                          const SizedBox(width: 4),
                                          Text('50 BDT', style: GoogleFonts.saira(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Material(
                              color: isDark ? const Color(0xFF161F38) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  if (!await _checkInternet(context)) return;

                                  if (subState.user == null) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please login first to purchase a plan!'),
                                          backgroundColor: Colors.orange,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                    _showEmailAuthDialog(context, ref);
                                  } else {
                                    final success = await ref.read(subscriptionProvider.notifier).purchasePlan(context, 'lifetime');
                                    if (success && context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.amber.shade600, width: 1.5),
                                  ),
                                  child: Column(
                                    children: [
                                      Text('Lifetime', style: GoogleFonts.saira(fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '50 USD',
                                        style: GoogleFonts.saira(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                      Text(
                                        '25 USD (3000 BDT)',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.saira(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
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
