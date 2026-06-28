import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_security/screens/HomeScreen/LiveStream/camera_management_screen.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class LiveStreamViewer extends StatefulWidget {
  const LiveStreamViewer({super.key});

  @override
  State<LiveStreamViewer> createState() => _LiveStreamViewerState();
}

class _LiveStreamViewerState extends State<LiveStreamViewer> {
  MqttServerClient? client;
  bool isConnected = false;
  bool isConnecting = false;
  String statusMessage = "Select a camera to start";
  bool isError = false;
  Uint8List? _currentFrame;
  encrypt.Encrypter? _encrypter;
  String? _selectedCameraId;

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }

  void _setStatus(String msg, {bool error = false}) {
    if (mounted) {
      setState(() {
        statusMessage = msg;
        isError = error;
      });
    }
  }

  Future<void> _onCameraSelected(
    String? docId,
    List<QueryDocumentSnapshot> docs,
  ) async {
    if (docId == _selectedCameraId) return;

    await _disconnect();

    if (docId == null) {
      setState(() {
        _selectedCameraId = null;
        statusMessage = "Select a camera to start";
      });
      return;
    }

    final doc = docs.firstWhere((d) => d.id == docId);
    final data = doc.data() as Map<String, dynamic>;

    setState(() {
      _selectedCameraId = docId;
    });

    _connectToCamera(data);
  }

  Future<void> _refreshConnection() async {
    if (_selectedCameraId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Disconnect existing connection
    await _disconnect();

    // Fetch fresh camera data to ensure we have latest keys/config
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('cameras')
          .doc(_selectedCameraId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        _connectToCamera(data);
      } else {
        _setStatus("Camera not found", error: true);
      }
    } catch (e) {
      _setStatus("Refresh failed: $e", error: true);
    }
  }

  Future<void> _connectToCamera(Map<String, dynamic> data) async {
    final broker = data['broker'] as String?;
    final portStr = data['port']?.toString() ?? '8883';
    final topic = data['mqtt_topic'] as String?;
    final keyStr = data['key'] as String?;
    final deviceId = data['device_id'] as String?;

    if (broker == null || topic == null || keyStr == null) {
      _setStatus("Invalid Camera Configuration", error: true);
      return;
    }

    try {
      final key = encrypt.Key.fromBase64(keyStr.trim());
      final fernet = encrypt.Fernet(key);
      _encrypter = encrypt.Encrypter(fernet);
    } catch (e) {
      _setStatus("Invalid Encryption Key", error: true);
      return;
    }

    setState(() {
      isConnecting = true;
      isError = false;
    });

    try {
      final String clientId =
          'viewer_${deviceId}_${DateTime.now().millisecondsSinceEpoch}';
      final int port = int.tryParse(portStr) ?? 8883;

      client = MqttServerClient.withPort(broker, clientId, port);
      client!.logging(on: false);
      client!.keepAlivePeriod = 20;
      client!.useWebSocket = false;
      client!.secure = true;
      client!.securityContext = SecurityContext.defaultContext;
      client!.onBadCertificate = (dynamic cert) => true;

      client!.onDisconnected = _onDisconnected;
      client!.onConnected = _onConnected;
      client!.onSubscribed = _onSubscribed;

      if (data.containsKey('username') && data.containsKey('password')) {
        client!.connectionMessage = MqttConnectMessage()
            .withClientIdentifier(clientId)
            .startClean()
            .authenticateAs(data['username'], data['password']);
      } else {
        client!.connectionMessage = MqttConnectMessage()
            .withClientIdentifier(clientId)
            .startClean()
            .authenticateAs('App_User', 'App_User_Password_1');
      }

      _setStatus("Connecting to $deviceId...");

      await client!.connect();

      if (client!.connectionStatus!.state == MqttConnectionState.connected) {
        _setStatus("Subscribing...");
        client!.subscribe(topic, MqttQos.atMostOnce);
        client!.updates!.listen(_onMessage);
      } else {
        _disconnect();
        _setStatus("Connection failed", error: true);
      }
    } catch (e) {
      _disconnect();
      _setStatus("Error: $e", error: true);
    } finally {
      if (mounted) setState(() => isConnecting = false);
    }
  }

  Future<void> _disconnect() async {
    client?.disconnect();
    client = null;
    if (mounted) {
      setState(() {
        isConnected = false;
        isConnecting = false;
        _currentFrame = null;
        if (!isError) statusMessage = "Disconnected";
      });
    }
  }

  void _onConnected() {
    if (mounted) {
      setState(() {
        isConnected = true;
        statusMessage = "Waiting for live feed...";
      });
    }
  }

  void _onDisconnected() {
    if (mounted) {
      setState(() {
        isConnected = false;
        _currentFrame = null;
        if (!isError) statusMessage = "Disconnected";
      });
    }
  }

  void _onSubscribed(String topic) {
    _setStatus("Live: Connected securely");
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage?>>? c) {
    if (c == null || c.isEmpty) return;
    final recMess = c[0].payload as MqttPublishMessage;
    final payloadString = MqttPublishPayload.bytesToStringAsString(
      recMess.payload.message,
    );

    try {
      if (_encrypter != null) {
        final decryptedBase64Image = _encrypter!.decrypt64(payloadString);
        final imageBytes = base64Decode(decryptedBase64Image);
        if (mounted) {
          setState(() {
            _currentFrame = imageBytes;
            isError = false;
          });
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(
        child: Text(
          "Please sign in",
          style: TextStyle(color: colorScheme.error),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title Section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Live Stream",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              if (_selectedCameraId != null)
                IconButton(
                  onPressed: isConnecting ? null : _refreshConnection,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: "Refresh Connection",
                  style: IconButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),

        // Camera Selector Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Users')
                      .doc(user.uid)
                      .collection('cameras')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return LinearProgressIndicator(
                        borderRadius: BorderRadius.circular(4),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        color: colorScheme.primary,
                      );
                    }

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Text(
                          "No cameras found. Add one in settings.",
                          style: TextStyle(color: colorScheme.outline),
                        ),
                      );
                    }

                    if (_selectedCameraId != null &&
                        !docs.any((d) => d.id == _selectedCameraId)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _onCameraSelected(null, docs);
                      });
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCameraId,
                          hint: Text(
                            "Select Camera",
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          isExpanded: true,
                          dropdownColor: colorScheme.surfaceContainer,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: colorScheme.primary,
                          ),
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          items: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final name = data['name'] ?? 'Unnamed Camera';
                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(name),
                            );
                          }).toList(),
                          onChanged: (val) => _onCameraSelected(val, docs),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CameraManagementScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.secondaryContainer,
                  foregroundColor: colorScheme.onSecondaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                tooltip: "Manage Cameras",
              ),
            ],
          ),
        ),

        // Video Stage
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _currentFrame != null
                  ? Colors.black
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isConnected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_currentFrame != null)
                      Image.memory(
                        _currentFrame!,
                        gaplessPlayback: true,
                        fit: BoxFit.contain,
                      )
                    else
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isError
                                  ? Icons.error_outline_rounded
                                  : Icons.videocam_off_outlined,
                              size: 48,
                              color: isError
                                  ? colorScheme.error
                                  : colorScheme.onSurfaceVariant.withValues(
                                      alpha: 0.5,
                                    ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              statusMessage,
                              style: TextStyle(
                                color: isError
                                    ? colorScheme.error
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isConnecting) ...[
                              const SizedBox(height: 24),
                              CircularProgressIndicator(
                                strokeWidth: 3,
                                color: colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                      ),

                    // Live Indicator Overlay
                    if (_currentFrame != null)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer.withValues(
                              alpha: 0.9,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.error.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colorScheme.error,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.error.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "LIVE",
                                style: TextStyle(
                                  color: colorScheme.onErrorContainer,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
