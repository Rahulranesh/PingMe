import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/mdns_discovery_service.dart';
import '../../services/auth_service.dart';
import '../../models/device.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neumorphic_container.dart';
import '../../widgets/pingme_toy_guide.dart';
import 'chat_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({Key? key}) : super(key: key);

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mdnsService = context.read<MDNSDiscoveryService>();
      if (!mdnsService.isDiscovering) {
        mdnsService.startDiscovery().catchError((e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to start discovery: $e'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mdnsService = context.watch<MDNSDiscoveryService>();
    final authService = context.watch<AuthService>();
    final devices = mdnsService.discoveredDevices;
    final isScanning = mdnsService.isDiscovering;

    // Check authentication
    if (!authService.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Please login to discover devices',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkSurface.withOpacity(0.1)
                : AppTheme.lightSurface.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        children: [
          _buildScanControl(context, mdnsService, isScanning),
          if (devices.isEmpty)
            Expanded(child: _buildEmptyState(context, isScanning))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices.values.elementAt(index);
                  return _buildDeviceItem(context, device)
                      .animate()
                      .fadeIn(duration: 300.ms, delay: Duration(milliseconds: index * 50))
                      .slideX(begin: 0.2, end: 0, duration: 300.ms);
                },
              ),
            ),
          PingMeToyGuide(
            message: isScanning 
                ? "Scanning for nearby devices..." 
                : "Tap the radar button to find devices!",
            animationType: 'search',
            guideName: 'discovery_hint',
          ),
        ],
      ),
    );
  }

  Widget _buildScanControl(
    BuildContext context,
    MDNSDiscoveryService mdnsService,
    bool isScanning,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nearby Devices',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isScanning ? 'Scanning...' : 'Tap to scan',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              _buildScanButton(context, mdnsService, isScanning),
            ],
          ),
          const SizedBox(height: 16),
          if (isScanning) _buildRadarAnimation(context),
        ],
      ),
    );
  }

  Widget _buildScanButton(
    BuildContext context,
    MDNSDiscoveryService mdnsService,
    bool isScanning,
  ) {
    return NeumorphicButton(
      onPressed: () {
        if (isScanning) {
          mdnsService.stopDiscovery();
        } else {
          mdnsService.startDiscovery();
        }
      },
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(50),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Icon(
          isScanning ? Icons.stop : Icons.radar,
          key: ValueKey(isScanning),
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildRadarAnimation(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final delay = index * 0.3;
                final value = (_animationController.value - delay) % 1.0;
                return Container(
                  width: 100 * (1 + value),
                  height: 100 * (1 + value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(1 - value),
                      width: 2,
                    ),
                  ),
                );
              },
            );
          }),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildEmptyState(BuildContext context, bool isScanning) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isScanning ? Icons.wifi_tethering : Icons.devices,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            isScanning ? 'Searching for devices...' : 'No devices found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isScanning
                ? 'Make sure other devices are nearby\nand have PingMe open'
                : 'Tap the scan button to search\nfor nearby devices',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(BuildContext context, Device device) {
    final isConnected = device.status == ConnectionStatus.connected;
    final isPairing = device.status == ConnectionStatus.pairing;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeumorphicContainer(
        onTap: () => _showConnectionDialog(context, device),
        child: Row(
          children: [
            _buildDeviceIcon(device),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _getDeviceTypeIcon(device.type),
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        device.platform ?? device.type.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${device.ipAddress}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildConnectionStatus(context, device),
                ],
              ),
            ),
            _buildSignalStrength(device.signalStrength),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceIcon(Device device) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.8),
            AppTheme.accentColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _getDeviceTypeIcon(device.type),
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(BuildContext context, Device device) {
    Color statusColor;
    String statusText;
    
    switch (device.status) {
      case ConnectionStatus.connected:
        statusColor = Colors.green;
        statusText = 'Connected';
        break;
      case ConnectionStatus.connecting:
        statusColor = Colors.orange;
        statusText = 'Connecting...';
        break;
      case ConnectionStatus.pairing:
        statusColor = Colors.blue;
        statusText = 'Pairing...';
        break;
      case ConnectionStatus.disconnected:
        statusColor = Colors.grey;
        statusText = 'Available';
        break;
      case ConnectionStatus.failed:
        statusColor = Colors.red;
        statusText = 'Failed';
        break;
    }
    
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          statusText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSignalStrength(int strength) {
    final bars = (strength / 25).ceil();
    
    return Row(
      children: List.generate(4, (index) {
        return Container(
          width: 3,
          height: 8 + (index * 3),
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: index < bars
                ? (bars >= 3 ? Colors.green : bars >= 2 ? Colors.orange : Colors.red)
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  IconData _getDeviceTypeIcon(DeviceType type) {
    switch (type) {
      case DeviceType.mobile:
        return Icons.smartphone;
      case DeviceType.tablet:
        return Icons.tablet;
      case DeviceType.desktop:
        return Icons.computer;
      case DeviceType.watch:
        return Icons.watch;
      case DeviceType.tv:
        return Icons.tv;
      default:
        return Icons.devices;
    }
  }

  void _showConnectionDialog(BuildContext context, Device device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Connect to ${device.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (device.metadata['avatarUrl'] != null && 
                device.metadata['avatarUrl'].toString().isNotEmpty)
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(device.metadata['avatarUrl']),
              )
            else
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.8),
                      AppTheme.accentColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    device.name.isNotEmpty ? device.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Do you want to chat with this person connected on this WiFi?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getDeviceTypeIcon(device.type),
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  device.platform ?? device.type.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• ${device.ipAddress}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            if (device.metadata['status'] != null &&
                device.metadata['status'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '"${device.metadata['status']}"',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 16),
                        Text('Connecting...'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
                
                // Connect to device
                final mdnsService = context.read<MDNSDiscoveryService>();
                await mdnsService.connectToDevice(device);
                
                // Navigate to chat screen
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(device: device),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to connect: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}
