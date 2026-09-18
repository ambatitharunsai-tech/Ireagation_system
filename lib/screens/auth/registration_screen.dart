import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

import '../../providers/auth_provider.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final success = await auth.register(
        _nameCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
        } else if (auth.error != null) {
          final errorMsg = auth.error!;
          auth.clearError();
          _showErrorDialog(errorMsg);
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) {
        final lang = Provider.of<LanguageProvider>(ctx);
        return AlertDialog(
          icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
          title: Text(lang.t('Registration Failed')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lang.t(message), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(
                lang.t('You can use Demo Mode to explore all features without an account.'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(lang.t('Try Again')),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx); // close dialog
                Provider.of<AuthProvider>(context, listen: false).loginAsDemo();
                Navigator.pop(context); // close registration screen
              },
              icon: const Icon(Icons.explore),
              label: Text(lang.t('Use Demo Mode')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0F9D58).withValues(alpha: 0.1),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.person_add_alt_1,
                      size: 72,
                      color: Color(0xFF0F9D58),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      lang.t('Create Account'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lang.t('Join SmartAgri and manage your farm'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: InputDecoration(
                                labelText: lang.t('Full Name'),
                                prefixIcon: const Icon(Icons.person_outline),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              textCapitalization: TextCapitalization.words,
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                  ? lang.t('Enter your name')
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: lang.t('Email'),
                                prefixIcon: const Icon(Icons.email_outlined),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return lang.t('Enter your email');
                                }
                                if (!val.contains('@') || !val.contains('.')) {
                                  return lang.t('Enter a valid email');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: lang.t('Password'),
                                prefixIcon: const Icon(Icons.lock_outline),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.length < 6) {
                                  return lang.t('Password must be at least 6 characters');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordCtrl,
                              obscureText: _obscureConfirm,
                              decoration: InputDecoration(
                                labelText: lang.t('Confirm Password'),
                                prefixIcon: const Icon(Icons.lock_outline),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                ),
                              ),
                              validator: (val) {
                                if (val != _passwordCtrl.text) {
                                  return lang.t('Passwords do not match');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            if (auth.isLoading)
                              const Center(child: CircularProgressIndicator())
                            else
                              FilledButton(
                                onPressed: _register,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  lang.t('Create Account'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(lang.t('Already have an account?')),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            lang.t('Login'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
