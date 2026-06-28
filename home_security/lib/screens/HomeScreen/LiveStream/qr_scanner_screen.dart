import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    formats: [BarcodeFormat.qrCode], // Optimization: Scan only QR codes
  );
  StreamSubscription<BarcodeCapture>? _subscription;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = _controller.barcodes.listen(_handleBarcode);
    _controller.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.hasCameraPermission) return;

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        _subscription = _controller.barcodes.listen(_handleBarcode);
        _controller.start();
        break;
      case AppLifecycleState.inactive:
        _subscription?.cancel();
        _subscription = null;
        _controller.stop();
        break;
    }
  }

  @override
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _subscription?.cancel();
    _subscription = null;
    super.dispose();
    await _controller.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null) {
        try {
          setState(() {
            _isProcessing = true;
          });

          // Pause camera while processing/dialog is open
          await _controller.stop();

          final Map<String, dynamic> data = jsonDecode(barcode.rawValue!);

          // Validate required fields
          if (data.containsKey('device_id') &&
              data.containsKey('key') &&
              data.containsKey('mqtt_topic') &&
              data.containsKey('broker')) {
            if (mounted) {
              // Ask for Camera Name
              final String? cameraName = await showDialog<String>(
                context: context,
                barrierDismissible: false,
                builder: (ctx) {
                  final nameCtrl = TextEditingController(
                    text: "Camera ${data['device_id']}",
                  );
                  return AlertDialog(
                    title: Text(
                      "Name Camera",
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    backgroundColor: colorScheme.surfaceContainerHigh,
                    content: TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: colorScheme.onSurface),
                      cursorColor: colorScheme.primary,
                      decoration: InputDecoration(
                        labelText: "Camera Name",
                        labelStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      autofocus: true,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          "Cancel",
                          style: TextStyle(color: colorScheme.primary),
                        ),
                      ),
                      FilledButton(
                        onPressed: () =>
                            Navigator.pop(ctx, nameCtrl.text.trim()),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                        child: const Text("Save"),
                      ),
                    ],
                  );
                },
              );

              if (cameraName != null && cameraName.isNotEmpty) {
                await _saveToFirebase(data, cameraName);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Camera "$cameraName" added!',
                        style: TextStyle(color: colorScheme.onPrimary),
                      ),
                      backgroundColor: colorScheme.primary,
                    ),
                  );
                  Navigator.of(context).pop(true); // Return success
                }
              } else {
                // User cancelled dialog, resume scanning
                if (mounted) {
                  setState(() => _isProcessing = false);
                  _controller.start();
                }
              }
            }
          } else {
            throw Exception("Invalid QR Format: Missing required fields");
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error: $e',
                  style: TextStyle(color: colorScheme.onError),
                ),
                backgroundColor: colorScheme.error,
              ),
            );
            // Resume after error
            setState(() => _isProcessing = false);
            _controller.start();
          }
        }
        break;
      }
    }
  }

  Future<void> _saveToFirebase(Map<String, dynamic> data, String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final deviceId = data['device_id'];
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('cameras')
          .doc(deviceId)
          .set({
            ...data,
            'name': name,
            'added_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scan Camera QR',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        foregroundColor: colorScheme.onPrimaryContainer,
        backgroundColor: colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return Icon(
                      Icons.flash_off,
                      color: colorScheme.onSurfaceVariant,
                    );
                  case TorchState.on:
                    return Icon(Icons.flash_on, color: colorScheme.primary);
                  case TorchState.auto:
                    return Icon(Icons.flash_auto, color: colorScheme.onSurface);
                  default:
                    return Icon(
                      Icons.flash_off,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    );
                }
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, child) {
                switch (state.cameraDirection) {
                  case CameraFacing.front:
                    return Icon(
                      Icons.camera_front,
                      color: colorScheme.onSurface,
                    );
                  case CameraFacing.back:
                    return Icon(
                      Icons.camera_rear,
                      color: colorScheme.onSurface,
                    );
                  default:
                    return Icon(Icons.camera_alt, color: colorScheme.onSurface);
                }
              },
            ),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller),
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: colorScheme.primary,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
                overlayColor: colorScheme.scrim.withValues(alpha: 0.5),
              ),
            ),
          ),
          if (_isProcessing)
            Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.8,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Align QR code within the frame",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 10.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final mCutOutSize = cutOutSize < width ? cutOutSize : width - borderOffset;
    final mBorderLength = borderLength > mCutOutSize / 2 + borderOffset * 2
        ? mCutOutSize / 2 + borderOffset * 2
        : borderLength;
    final mBorderRadius = borderRadius > mBorderLength / 4
        ? mBorderLength / 4
        : borderRadius;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - mCutOutSize / 2 + borderOffset,
      rect.top + height / 2 - mCutOutSize / 2 + borderOffset,
      mCutOutSize - borderOffset * 2,
      mCutOutSize - borderOffset * 2,
    );

    canvas
      ..saveLayer(rect, backgroundPaint)
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndRadius(cutOutRect, Radius.circular(mBorderRadius)),
        Paint()..blendMode = BlendMode.clear,
      )
      ..restore();

    final cutOutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(cutOutRect, Radius.circular(mBorderRadius)),
      );
    canvas.drawPath(cutOutPath, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
