import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neumorphic_container.dart';
import '../../widgets/pingme_toy_guide.dart';
import 'discovery_screen.dart';
import 'chat_list_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

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
  
  void _showContextualGuide() {
    if (!mounted) return;
    
    String message;
    String animationType;
    
    switch (_currentIndex) {
      case 0:
        message = "View your conversations here!";
        animationType = 'chat';
        break;
      case 1:
        message = "Discover nearby devices to chat with!";
        animationType = 'search';
        break;
      case 2:
        message = "Customize your profile here!";
        animationType = 'star';
        break;
      case 3:
        message = "Adjust your app preferences!";
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

    return Scaffold(
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
            _buildBottomNavBar(context),
          ],
        ),
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
                    user.isOnline ? 'Online' : 'Offline',
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
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            'Chats',
            0,
          ),
          _buildNavItem(
            context,
            Icons.explore_outlined,
            Icons.explore,
            'Discover',
            1,
          ),
          _buildNavItem(
            context,
            Icons.person_outline,
            Icons.person,
            'Profile',
            2,
          ),
          _buildNavItem(
            context,
            Icons.settings_outlined,
            Icons.settings,
            'Settings',
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
    final color = isActive ? AppTheme.primaryColor : Colors.grey;

    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
