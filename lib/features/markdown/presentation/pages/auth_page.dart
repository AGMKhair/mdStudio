import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../providers/auth_provider.dart';
import '../providers/security_provider.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isRegistering = false;
  bool _isLoading = false;
  bool _hasUsersChecked = false;
  bool _dbHasUsers = false;

  @override
  void initState() {
    super.initState();
    _checkDbUsers();
  }

  Future<void> _checkDbUsers() async {
    final hasUsers = await ref.read(authProvider.notifier).hasUsers();
    setState(() {
      _dbHasUsers = hasUsers;
      _isRegistering = !hasUsers; // Show register first if DB is empty
      _hasUsersChecked = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text;
    final password = _passwordController.text;

    bool success = false;
    if (_isRegistering) {
      final name = _nameController.text;
      success = await ref.read(authProvider.notifier).register(name, email, password);
    } else {
      success = await ref.read(authProvider.notifier).login(email, password);
    }

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isRegistering ? 'Registration successful!' : 'Login successful!'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed. Please check details.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _biometricLogin() async {
    final securityState = ref.read(securityProvider);
    if (!securityState.isBiometricsAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometrics not available or configured on this device.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authenticated = await ref
        .read(securityProvider.notifier)
        .authenticateBiometrics('Authenticate to access mdStudio Secure');

    if (authenticated) {
      final success = await ref.read(authProvider.notifier).loginBiometrically();
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to login biometrically. Please enter password.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasUsersChecked) {
      return const Scaffold(
        backgroundColor: AppColors.darkScaffoldBg,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E1E38)]
                : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Card(
                elevation: 10,
                color: isDark ? AppColors.darkCardBg.withOpacity(0.9) : AppColors.cardBg.withOpacity(0.9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingL,
                    vertical: AppDimensions.paddingXL,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_person_rounded,
                            size: 64,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: AppDimensions.paddingS),
                          Text(
                            'mdStudio Secure',
                            style: GoogleFonts.saira(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.grey900,
                            ),
                          ),
                          Text(
                            _isRegistering ? 'Setup Owner Key' : 'Local Document Vault',
                            style: GoogleFonts.saira(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.grey400,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.paddingXL),
                          
                          if (_isRegistering) ...[
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Your Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty ? 'Name required' : null,
                            ),
                            const SizedBox(height: AppDimensions.paddingM),
                          ],
                          
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Email required';
                              if (!value.contains('@')) return 'Invalid email address';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppDimensions.paddingM),
                          
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Vault Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (value) =>
                                value == null || value.length < 6 ? 'Password min 6 chars' : null,
                          ),
                          const SizedBox(height: AppDimensions.paddingM),
                          
                          if (_isRegistering) ...[
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              validator: (value) {
                                if (value != _passwordController.text) return 'Passwords do not match';
                                return null;
                              },
                            ),
                            const SizedBox(height: AppDimensions.paddingL),
                          ],

                          if (_isLoading)
                            const CircularProgressIndicator()
                          else ...[
                            ElevatedButton(
                              onPressed: _submit,
                              child: Text(_isRegistering ? 'Initialize Vault' : 'Unlock Vault'),
                            ),
                            if (!_isRegistering && _dbHasUsers) ...[
                              const SizedBox(height: AppDimensions.paddingM),
                              OutlinedButton.icon(
                                onPressed: _biometricLogin,
                                icon: const Icon(Icons.fingerprint_rounded),
                                label: const Text('Unlock with Biometrics'),
                              ),
                            ],
                            const SizedBox(height: AppDimensions.paddingM),
                            if (_dbHasUsers)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isRegistering = !_isRegistering;
                                  });
                                },
                                child: Text(
                                  _isRegistering
                                      ? 'Already registered? Login'
                                      : 'Register another account',
                                  style: const TextStyle(color: AppColors.primary),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
