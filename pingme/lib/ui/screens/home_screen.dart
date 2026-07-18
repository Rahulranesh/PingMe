import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/mdns_discovery_service.dart';
import '../../services/chat_service.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_request_service.dart';
import '../../services/language_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neumorphic_container.dart';
import '../../widgets/pingme_toy_guide.dart';
import '../../widgets/chat_request_listener.dart';
import '../../utils/localization_helper.dart';
import 'chat_list_screen.dart';
import 'discovery_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
      
      // Show context-aware Toy Guide
      _showContextualGuide();
    });
    
    // Initialize services in background
    _initializeServicesInBackground();
    
    // Show initial guide
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          PingMeToyGuideOverlay.show(
            context,
            message: "Navigate between chats, discovery, profile, and settings using the bottom tabs!",
            animationType: 'chat',
            duration: const Duration(seconds: 5),
          );
        }
      });
    });
  }

  void _initializeServicesInBackground() async {
    try {
      final authService = context.read<AuthService>();
      
      // Initialize ChatRequestService if user is logged in
      final chatRequestService = context.read<ChatRequestService>();
      if (authService.currentUser != null) {
        await chatRequestService.initialize(authService.currentUser!);
      }

      // Discovery service - start discovery if not already running
      final mdnsService = context.read<MDNSDiscoveryService>();
      if (!mdnsService.isDiscovering) {
        await mdnsService.initialize().timeout(const Duration(seconds: 5));
        await mdnsService.startDiscovery().timeout(const Duration(seconds: 3));
      }

      // Chat service - initialize if user is logged in
      if (authService.currentUser != null) {
        final chatService = context.read<ChatService>();
        await chatService.initialize(authService.currentUser!).timeout(const Duration(seconds: 5));
      }
      
    } catch (e) {
      debugPrint('Error initializing services: $e');
      // Services can still be initialized on-demand
    }
  }
  
  void _showContextualGuide() {
    if (!mounted) return;
    
    String message;
    String animationType;
    
    switch (_currentIndex) {
      case 0:
        message = context.l10n.viewConversationsHere;
        animationType = 'chat';
        break;
      case 1:
        message = context.l10n.discoverNearbyDevices;
        animationType = 'search';
        break;
      case 2:
        message = context.l10n.customizeProfileHere;
        animationType = 'star';
        break;
      case 3:
        message = context.l10n.adjustPreferences;
        animationType = 'wave';
        break;
      default:
        return;
    }
    
    PingMeToyGuideOverlay.show(
      context,
      message: message,
      animationType: animationType,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChatRequestListener(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    ChatListScreen(),
                    DiscoveryScreen(),
                    ProfileScreen(),
                    SettingsScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(context),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final profileService = context.watch<ProfileService>();
    final user = profileService.currentUser;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'PingMe',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const Spacer(),
          if (user != null)
            NeumorphicContainer(
              padding: const EdgeInsets.all(8),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: user.isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user.isOnline ? context.l10n.online : context.l10n.offline,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            Icons.chat_bubble_outline,
            Icons.chat_bubble,
            context.l10n.chat,
            0,
          ),
          _buildNavItem(
            context,
            Icons.explore_outlined,
            Icons.explore,
            context.l10n.discover,
            1,
          ),
          _buildNavItem(
            context,
            Icons.person_outline,
            Icons.person,
            context.l10n.profile,
            2,
          ),
          _buildNavItem(
            context,
            Icons.settings_outlined,
            Icons.settings,
            context.l10n.settings,
            3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
  ) {
    final isActive = _currentIndex == index;
    final color = isActive ? AppTheme.primaryColor : Colors.grey.shade600;

    return Expanded(
      child: InkWell(
        onTap: () => _tabController.animateTo(index),
        child: Container(
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: color,
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
