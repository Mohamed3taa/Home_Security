import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HardwareControlScreen extends StatelessWidget {
  final String deviceId;
  final String deviceName;

  const HardwareControlScreen({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  Future<void> _sendCommand(String command, Map<String, dynamic> params) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('Hardware')
          .doc(deviceId)
          .collection('commands')
          .add({
            'command': command,
            'params': params,
            'triggered_by': user.uid,
            'timestamp': FieldValue.serverTimestamp(),
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        foregroundColor: colorScheme.onPrimaryContainer,
        backgroundColor: colorScheme.primaryContainer,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onPrimaryContainer),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          deviceName,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Hardware')
            .doc(deviceId)
            .collection('states')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Connection Error",
                style: TextStyle(color: colorScheme.error),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          }

          Map<String, dynamic> state = {};
          if (snapshot.data != null && snapshot.data!.docs.isNotEmpty) {
            state = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          }

          // Default values if data missing
          final double temp = (state['temperature'] ?? 0).toDouble();
          final double humidity = (state['humidity'] ?? 0).toDouble();
          final bool gateOpen =
              state['gate'] == true; // Assuming boolean 'gate' (true=open)
          final bool alarmOn = state['alarm_state'] == true;
          final String status = state['state'] ?? 'Offline';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: status == 'Online'
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        status == 'Online' ? Icons.wifi : Icons.wifi_off,
                        color: status == 'Online'
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Status: $status",
                        style: TextStyle(
                          color: status == 'Online'
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Sensor Grid
                Row(
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
                const SizedBox(height: 32),

                Text(
                  "Device Controls",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Gate Control
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
                    _sendCommand('SET_GATE', {'state': val ? 'OPEN' : 'CLOSE'});
                  },
                ),
                const SizedBox(height: 16),

                // Alarm Control
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
          );
        },
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bgColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
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
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? activeColor.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1.5,
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
