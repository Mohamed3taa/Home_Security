import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:home_security/screens/HomeScreen/hardware/hardware_management_screen.dart';

class HardwareControlSection extends StatefulWidget {
  const HardwareControlSection({super.key});

  @override
  State<HardwareControlSection> createState() => _HardwareControlSectionState();
}

class _HardwareControlSectionState extends State<HardwareControlSection> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedDeviceId;

  Future<void> _sendCommand(String command, Map<String, dynamic> params) async {
    final user = _auth.currentUser;
    if (user != null && _selectedDeviceId != null) {
      try {
        await _firestore
            .collection('Hardware')
            .doc(_selectedDeviceId)
            .collection('commands')
            .add({
              'command': command,
              'params': params,
              'triggered_by': user.uid,
              'timestamp': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send command: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = _auth.currentUser;

    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Device Control",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HardwareManagementScreen(),
                    ),
                  );
                },
                child: const Text("Manage List"),
              ),
            ],
          ),
        ),

        // Stream for User's Hardware List
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('Users')
              .doc(user.uid)
              .collection('hardware')
              .orderBy('paired_at', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Error loading devices",
                  style: TextStyle(color: colorScheme.error),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final devices = snapshot.data!.docs;

            if (devices.isEmpty) {
              return _buildNoDevicesState(context);
            }

            // Auto-select first device if none selected or selection is invalid
            if (_selectedDeviceId == null ||
                !devices.any(
                  (doc) => doc.get('device_id') == _selectedDeviceId,
                )) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _selectedDeviceId = devices.first.get('device_id');
                  });
                }
              });
            }

            return Column(
              children: [
                // Dropdown Selector (Styled like a Card)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDeviceId,
                          isExpanded: true,
                          hint: const Text("Select Device"),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          dropdownColor: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          items: devices.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem<String>(
                              value: data['device_id'],
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.router,
                                      size: 16,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    data['name'] ?? 'Unknown Device',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedDeviceId = val;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Selected Device Controls
                if (_selectedDeviceId != null)
                  _buildDeviceControlView(context, _selectedDeviceId!),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDeviceControlView(BuildContext context, String deviceId) {
    return StreamBuilder<QuerySnapshot>(
      // Listen to the specific device's state
      stream: _firestore
          .collection('Hardware')
          .doc(deviceId)
          .collection('states')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final colorScheme = Theme.of(context).colorScheme;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        Map<String, dynamic> state = {};
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          state = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        }

        final double temp = (state['temperature'] ?? 0).toDouble();
        final double humidity = (state['humidity'] ?? 0).toDouble();
        final bool gateOpen = state['gate'] == true;
        final bool alarmOn = state['alarm_state'] == true;
        final String status = state['state'] ?? 'Offline';
        final bool isOnline = status == 'Online';

        return Column(
          children: [
            // Status Indicator (Styled as a Card)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 0,
                color: isOnline
                    ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOnline ? Icons.wifi : Icons.wifi_off,
                        size: 16,
                        color: isOnline
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Status: $status",
                        style: TextStyle(
                          color: isOnline
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sensors Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSensorCard(
                      context,
                      "Temperature",
                      "${temp.toStringAsFixed(1)}°C",
                      Icons.thermostat,
                      colorScheme.tertiary,
                      colorScheme.tertiaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSensorCard(
                      context,
                      "Humidity",
                      "${humidity.toStringAsFixed(1)}%",
                      Icons.water_drop,
                      colorScheme.secondary,
                      colorScheme.secondaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildControlTile(
                    context,
                    title: "Gate Control",
                    subtitle: gateOpen ? "Gate is OPEN" : "Gate is CLOSED",
                    icon: gateOpen
                        ? Icons.door_front_door_outlined
                        : Icons.door_front_door,
                    isActive: gateOpen,
                    activeColor: colorScheme.primary,
                    onToggle: (val) {
                      _sendCommand('SET_GATE', {
                        'state': val ? 'OPEN' : 'CLOSE',
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildControlTile(
                    context,
                    title: "Security Alarm",
                    subtitle: alarmOn ? "Alarm Triggered!" : "System Armed",
                    icon: alarmOn
                        ? Icons.notifications_active
                        : Icons.notifications_off_outlined,
                    isActive: alarmOn,
                    activeColor: colorScheme.error,
                    onToggle: (val) {
                      _sendCommand('SET_ALARM', {'state': val ? 'ON' : 'OFF'});
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoDevicesState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.device_unknown, size: 48, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                "No Devices Paired",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Go to 'Manage List' to add a new hardware device via QR Code.",
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HardwareManagementScreen(),
                    ),
                  );
                },
                child: const Text("Add Device"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensorCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color bgColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required Function(bool) onToggle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: SwitchListTile(
        value: isActive,
        onChanged: onToggle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isActive ? activeColor : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.1)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isActive ? activeColor : colorScheme.onSurfaceVariant,
          ),
        ),
        activeThumbColor: activeColor,
        activeTrackColor: activeColor.withValues(alpha: 0.2),
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}
