import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neumorphic_container.dart';
import '../../utils/localization_helper.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _buildLogo(context),
                const SizedBox(height: 30),
                _buildWelcomeText(context),
                const SizedBox(height: 40),
                _buildNameField(context),
                const SizedBox(height: 20),
                _buildEmailField(context),
                const SizedBox(height: 20),
                _buildPasswordField(context),
                const SizedBox(height: 20),
                _buildConfirmPasswordField(context),
                const SizedBox(height: 20),
                _buildTermsCheckbox(context),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _buildErrorMessage(context),
                ],
                const SizedBox(height: 30),
                _buildSignUpButton(context),
                const SizedBox(height: 20),
                _buildDivider(context),
                const SizedBox(height: 20),
                _buildGoogleSignUp(context),
                const SizedBox(height: 30),
                _buildLoginLink(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.chat_bubble_rounded,
          color: Colors.white,
          size: 50,
        ),
      ),
    )
        .animate()
        .scale(duration: 500.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 500.ms);
  }

  Widget _buildWelcomeText(BuildContext context) {
    return Column(
      children: [
        Text(
          context.l10n.createAccount,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 200.ms)
            .slideY(begin: 0.2, end: 0),
        const SizedBox(height: 8),
        Text(
          context.l10n.joinPingMe,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 300.ms)
            .slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildNameField(BuildContext context) {
    return NeumorphicContainer(
      padding: EdgeInsets.zero,
      child: TextFormField(
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: context.l10n.fullName,
          hintText: context.l10n.enterYourName,
          prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryColor),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return context.l10n.pleaseEnterName;
          }
          if (value.trim().length < 2) {
            return context.l10n.nameMinLength;
          }
          return null;
        },
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 400.ms)
        .slideX(begin: -0.2, end: 0);
  }

  Widget _buildEmailField(BuildContext context) {
    return NeumorphicContainer(
      padding: EdgeInsets.zero,
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: context.l10n.email,
          hintText: context.l10n.enterYourEmail,
          prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryColor),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return context.l10n.pleaseEnterEmail;
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return context.l10n.pleaseEnterValidEmail;
          }
          return null;
        },
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 500.ms)
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildPasswordField(BuildContext context) {
    return NeumorphicContainer(
      padding: EdgeInsets.zero,
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          labelText: context.l10n.password,
          hintText: context.l10n.createPassword,
          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryColor),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return context.l10n.pleaseEnterPassword;
          }
          if (value.length < 6) {
            return context.l10n.passwordMinLength;
          }
          return null;
        },
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 600.ms)
        .slideX(begin: -0.2, end: 0);
  }

  Widget _buildConfirmPasswordField(BuildContext context) {
    return NeumorphicContainer(
      padding: EdgeInsets.zero,
      child: TextFormField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirmPassword,
        decoration: InputDecoration(
          labelText: context.l10n.confirmPassword,
          hintText: context.l10n.reenterPassword,
          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryColor),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return context.l10n.pleaseConfirmPassword;
          }
          if (value != _passwordController.text) {
            return context.l10n.passwordsDoNotMatch;
          }
          return null;
        },
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 700.ms)
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildTermsCheckbox(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) {
            setState(() {
              _acceptTerms = value ?? false;
            });
          },
          activeColor: AppTheme.primaryColor,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _acceptTerms = !_acceptTerms;
              });
            },
            child: Text.rich(
              TextSpan(
                text: 'I agree to the ',
                style: TextStyle(color: Colors.grey.shade600),
                children: [
                  const TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: ' and ',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 800.ms);
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.errorColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.errorColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppTheme.errorColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .shake(duration: 300.ms);
  }

  Widget _buildSignUpButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: NeumorphicButton(
        onPressed: _isLoading ? null : _handleSignUp,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Create Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 900.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 1000.ms);
  }

  Widget _buildGoogleSignUp(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _handleGoogleSignUp,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(
            color: Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://www.google.com/favicon.ico',
              height: 24,
              width: 24,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.g_mobiledata,
                  size: 24,
                  color: Colors.blue,
                );
              },
            ),
            const SizedBox(width: 12),
            const Text(
              'Sign up with Google',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 1100.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildLoginLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          },
          child: const Text(
            'Sign In',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 1200.ms);
  }

  void _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      setState(() {
        _errorMessage = 'Please accept the terms and conditions';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final success = await authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleGoogleSignUp() async {
    if (!_acceptTerms) {
      setState(() {
        _errorMessage = 'Please accept the terms and conditions';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final success = await authService.signInWithGoogle();

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google sign-up failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
