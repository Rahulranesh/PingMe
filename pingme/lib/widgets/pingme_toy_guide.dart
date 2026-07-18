import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class PingMeToyGuide extends StatefulWidget {
  final String message;
  final String? animationType;
  final VoidCallback? onDismiss;
  final bool showOnce;
  final String? guideName;

  const PingMeToyGuide({
    super.key,
    required this.message,
    this.animationType = 'wave',
    this.onDismiss,
    this.showOnce = true,
    this.guideName,
  });

  @override
  State<PingMeToyGuide> createState() => _PingMeToyGuideState();
}

class _PingMeToyGuideState extends State<PingMeToyGuide> with SingleTickerProviderStateMixin {
  bool _isVisible = true;
  late AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _checkIfShown();
  }

  Future<void> _checkIfShown() async {
    if (widget.showOnce && widget.guideName != null) {
      final prefs = await SharedPreferences.getInstance();
      final hasShown = prefs.getBool('guide_${widget.guideName}') ?? false;
      if (hasShown) {
        setState(() {
          _isVisible = false;
        });
      } else {
        await prefs.setBool('guide_${widget.guideName}', true);
      }
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 5 * _bounceController.value),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.9),
                    AppTheme.secondaryColor.withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildToyCharacter(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Ping says:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onDismiss != null)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () {
                        setState(() {
                          _isVisible = false;
                        });
                        widget.onDismiss!();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 500.ms)
          .slideY(begin: 1, end: 0, curve: Curves.elasticOut, duration: 800.ms),
    );
  }

  Widget _buildToyCharacter() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: _getAnimatedIcon(),
          ),
        ),
      ],
    );
  }

  Widget _getAnimatedIcon() {
    switch (widget.animationType) {
      case 'wave':
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: -0.2, end: 0.2),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Transform.rotate(
              angle: value,
              child: const Text(
                '👋',
                style: TextStyle(fontSize: 32),
              ),
            );
          },
          onEnd: () {
            // Loop the animation
            setState(() {});
          },
        );
      case 'heart':
        return const Text(
          '❤️',
          style: TextStyle(fontSize: 32),
        ).animate(onPlay: (controller) => controller.repeat())
            .scaleXY(begin: 0.8, end: 1.2, duration: 800.ms)
            .then()
            .scaleXY(begin: 1.2, end: 0.8, duration: 800.ms);
      case 'star':
        return const Text(
          '⭐',
          style: TextStyle(fontSize: 32),
        ).animate(onPlay: (controller) => controller.repeat())
            .rotate(duration: 2000.ms);
      case 'chat':
        return const Text(
          '💬',
          style: TextStyle(fontSize: 32),
        ).animate(onPlay: (controller) => controller.repeat())
            .shake(hz: 2, duration: 1000.ms);
      case 'search':
        return const Text(
          '🔍',
          style: TextStyle(fontSize: 32),
        ).animate(onPlay: (controller) => controller.repeat())
            .scaleXY(begin: 0.9, end: 1.1, duration: 1000.ms);
      default:
        return const Icon(
          Icons.chat_bubble_rounded,
          color: AppTheme.primaryColor,
          size: 32,
        );
    }
  }
}

class PingMeToyGuideOverlay {
  static OverlayEntry? _overlayEntry;

  static void show(
    BuildContext context, {
    required String message,
    String? animationType,
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onDismiss,
  }) {
    remove();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: PingMeToyGuide(
            message: message,
            animationType: animationType,
            showOnce: false,
            onDismiss: () {
              remove();
              onDismiss?.call();
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    Future.delayed(duration, () {
      remove();
    });
  }

  static void remove() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
