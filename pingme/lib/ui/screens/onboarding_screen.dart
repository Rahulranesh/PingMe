import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neumorphic_container.dart';
import '../../widgets/pingme_toy_guide.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _statusController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Show Toy Guide after a delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          PingMeToyGuideOverlay.show(
            context,
            message: "Welcome! Let's set up your profile to start chatting with nearby friends!",
            animationType: 'wave',
            duration: const Duration(seconds: 6),
          );
        }
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              AppTheme.secondaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
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
                  _buildStatusField(context),
                  const SizedBox(height: 40),
                  _buildStartButton(context),
                  const SizedBox(height: 20),
                  _buildPrivacyText(context),
                  const SizedBox(height: 20),
                  PingMeToyGuide(
                    message: "Fill in your name and tap 'Get Started' to begin!",
                    animationType: 'heart',
                    guideName: 'onboarding_setup',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
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
          size: 60,
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
          'Welcome to PingMe',
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
          'Chat with nearby devices over WiFi',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 300.ms)
            .slideY(begin: 0.2, end: 0),
        const SizedBox(height: 4),
        Text(
          'No internet required!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.w600,
              ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 400.ms)
            .slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildNameField(BuildContext context) {
    return NeumorphicContainer(
      padding: EdgeInsets.zero,
      child: TextFormField(
        controller: _nameController,
        decoration: InputDecoration(
          labelText: 'Your Name',
          hintText: 'Enter your name',
          prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your name';
          }
          if (value.trim().length < 2) {
            return 'Name must be at least 2 characters';
          }
          if (value.trim().length > 30) {
            return 'Name must be less than 30 characters';
          }
          return null;
        },
        textCapitalization: TextCapitalization.words,
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 500.ms)
        .slideX(begin: -0.2, end: 0);
  }

  Widget _buildStatusField(BuildContext context) {
    return NeumorphicContainer(
      padding: EdgeInsets.zero,
      child: TextFormField(
        controller: _statusController,
        decoration: InputDecoration(
          labelText: 'Status (optional)',
          hintText: 'What\'s on your mind?',
          prefixIcon: const Icon(Icons.mood, color: AppTheme.primaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        maxLength: 100,
        buildCounter: (context, {required int currentLength, required bool isFocused, maxLength}) => null,
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 600.ms)
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: NeumorphicButton(
        onPressed: _isLoading ? null : _handleStart,
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Get Started',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                  ),
                ],
              ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 700.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildPrivacyText(BuildContext context) {
    return Text(
      'Your data stays on your device.\nNo servers, no tracking, just pure P2P.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade500,
          ),
      textAlign: TextAlign.center,
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 800.ms);
  }

  void _handleStart() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profileService = context.read<ProfileService>();
      
      await profileService.createProfile(
        name: _nameController.text.trim(),
        status: _statusController.text.trim().isEmpty
            ? 'Hey there! I\'m using PingMe'
            : _statusController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
